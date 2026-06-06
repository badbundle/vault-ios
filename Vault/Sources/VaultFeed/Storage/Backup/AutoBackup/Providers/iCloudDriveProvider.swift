import Foundation

/// Configuration data for the iCloud Drive provider.
struct iCloudDriveProviderConfiguration: Codable, Equatable {
    /// Security-scoped bookmark data for the selected folder.
    var folderBookmark: Data?

    /// Display name of the selected folder for UI.
    var folderDisplayName: String?
}

/// Backup storage provider for iCloud Drive.
///
/// Uses a user-selected folder in iCloud Drive via document picker.
/// Stores a security-scoped bookmark for persistent access.
///
/// This is an actor to ensure thread-safe access to the mutable configuration state.
public actor iCloudDriveProvider: BackupStorageProvider {
    public static let providerID = "icloud-drive"

    public nonisolated let id: String = iCloudDriveProvider.providerID
    public nonisolated let displayName: String = "Files"
    public nonisolated let iconSystemName: String = "folder"

    private let fileManager: FileManager
    private var config: iCloudDriveProviderConfiguration

    /// The display name of the currently selected folder.
    public var folderDisplayName: String? {
        config.folderDisplayName
    }

    public init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
        config = iCloudDriveProviderConfiguration()
    }

    public var isConfigured: Bool {
        config.folderBookmark != nil
    }

    public var configurationSummary: String? {
        config.folderDisplayName
    }

    public var isAvailable: Bool {
        get async {
            // If we have a configured folder, try to access it to verify availability
            if config.folderBookmark != nil {
                do {
                    let url = try accessFolder()
                    url.stopAccessingSecurityScopedResource()
                    return true
                } catch {
                    return false
                }
            }
            // If not configured, we're available if user can select a folder
            return true
        }
    }

    public var configurationData: Data? {
        try? JSONEncoder().encode(config)
    }

    public func restoreConfiguration(from data: Data) throws {
        config = try JSONDecoder().decode(iCloudDriveProviderConfiguration.self, from: data)
    }

    public func clearConfiguration() {
        config = iCloudDriveProviderConfiguration()
    }

    /// Configure the provider with a folder URL selected by the user.
    ///
    /// This should be called from the UI layer after the user selects a folder
    /// via UIDocumentPickerViewController.
    ///
    /// - Parameter folderURL: The URL of the selected folder.
    public func configure(with folderURL: URL) throws {
        guard folderURL.startAccessingSecurityScopedResource() else {
            throw AutoBackupError.accessDenied
        }
        defer { folderURL.stopAccessingSecurityScopedResource() }

        let bookmark = try folderURL.bookmarkData(
            options: .minimalBookmark,
            includingResourceValuesForKeys: nil,
            relativeTo: nil,
        )

        config.folderBookmark = bookmark
        config.folderDisplayName = folderURL.lastPathComponent
    }

    public func write(data: Data, filename: String) async throws {
        let folderURL = try accessFolder()
        defer { folderURL.stopAccessingSecurityScopedResource() }

        let fileURL = folderURL.appendingPathComponent(filename)

        do {
            try data.write(to: fileURL, options: .atomic)
        } catch {
            throw AutoBackupError.writeFailed(reason: error.localizedDescription)
        }
    }

    public func listBackups() async throws -> [BackupFileInfo] {
        let folderURL = try accessFolder()
        defer { folderURL.stopAccessingSecurityScopedResource() }

        let contents = try fileManager.contentsOfDirectory(
            at: folderURL,
            includingPropertiesForKeys: [.creationDateKey, .fileSizeKey],
            options: [.skipsHiddenFiles],
        )

        return try contents
            .filter { $0.lastPathComponent.hasPrefix("vault-auto-backup-") }
            .filter { $0.pathExtension.lowercased() == "pdf" }
            .map { url -> BackupFileInfo in
                let attributes = try url.resourceValues(forKeys: [.creationDateKey, .fileSizeKey])
                return BackupFileInfo(
                    filename: url.lastPathComponent,
                    createdDate: attributes.creationDate ?? Date.distantPast,
                    size: Int64(attributes.fileSize ?? 0),
                )
            }
            .sorted { $0.createdDate > $1.createdDate }
    }

    public func delete(filename: String) async throws {
        let folderURL = try accessFolder()
        defer { folderURL.stopAccessingSecurityScopedResource() }

        let fileURL = folderURL.appendingPathComponent(filename)

        do {
            try fileManager.removeItem(at: fileURL)
        } catch {
            throw AutoBackupError.cleanupFailed(reason: error.localizedDescription)
        }
    }

    // MARK: - Private

    private func accessFolder() throws -> URL {
        guard let bookmark = config.folderBookmark else {
            throw AutoBackupError.providerNotConfigured
        }

        var isStale = false
        let url: URL

        do {
            url = try URL(
                resolvingBookmarkData: bookmark,
                options: [],
                relativeTo: nil,
                bookmarkDataIsStale: &isStale,
            )
        } catch {
            throw AutoBackupError.accessDenied
        }

        if isStale {
            // Bookmark is stale, need to reconfigure
            config.folderBookmark = nil
            throw AutoBackupError.accessDenied
        }

        guard url.startAccessingSecurityScopedResource() else {
            throw AutoBackupError.accessDenied
        }

        return url
    }
}
