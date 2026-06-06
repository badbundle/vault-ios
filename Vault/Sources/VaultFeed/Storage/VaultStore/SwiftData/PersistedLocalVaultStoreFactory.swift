import Foundation
import SwiftData

public final class PersistedLocalVaultStoreFactory {
    private static let storeFilename = "vault-primary.sqlite"
    private static let storeSidecarSuffixes = ["-shm", "-wal"]

    private let storageDirectory: URL
    private let fileManager: FileManager
    private let archiveDirectoryName: () -> String

    public init(
        storageDirectory: URL,
        fileManager: FileManager = .default,
        archiveDirectoryName: @escaping () -> String = {
            let timestamp = ISO8601DateFormatter()
                .string(from: Date())
                .replacingOccurrences(of: ":", with: "-")
            return "vault-primary.failed-open-\(timestamp)"
        },
    ) {
        self.storageDirectory = storageDirectory
        self.fileManager = fileManager
        self.archiveDirectoryName = archiveDirectoryName
    }

    public func makeVaultStore() -> PersistedLocalVaultStore {
        let storeURL = storageDirectory.appending(path: Self.storeFilename)
        do {
            return try makeVaultStore(storeURL: storeURL)
        } catch {
            recoverExistingStoreIfPresent(storeURL: storeURL, connectionError: error)
            do {
                return try makeVaultStore(storeURL: storeURL)
            } catch {
                fatalError("Unable to connect to PersistedLocalVaultStore after recovery: \(error)")
            }
        }
    }

    private func makeVaultStore(storeURL: URL) throws -> PersistedLocalVaultStore {
        let configuration = ModelConfiguration(
            "PersistedLocalVaultStore",
            schema: .init(versionedSchema: PersistedSchemaLatestVersion.self),
            url: storeURL,
        )
        let container = try ModelContainer(
            for: PersistedVaultItem.self, PersistedVaultTag.self,
            migrationPlan: PersistedSchemaMigrationPlan.self,
            configurations: configuration,
        )
        return PersistedLocalVaultStore(modelContainer: container)
    }

    private func recoverExistingStoreIfPresent(storeURL: URL, connectionError: any Error) {
        do {
            let existingURLs = storeBundleURLs(storeURL: storeURL).filter(fileExists(at:))
            guard existingURLs.isEmpty == false else {
                fatalError("Unable to connect to PersistedLocalVaultStore: \(connectionError)")
            }

            let archiveURL = makeUniqueArchiveDirectoryURL()
            try fileManager.createDirectory(at: archiveURL, withIntermediateDirectories: true)

            for url in existingURLs {
                let destinationURL = archiveURL.appending(path: url.lastPathComponent)
                try fileManager.moveItem(at: url, to: destinationURL)
            }
        } catch {
            fatalError("Unable to recover PersistedLocalVaultStore: \(error)")
        }
    }

    struct NoUserDocumentDirectory: Error, LocalizedError {
        var errorDescription: String? {
            "No user document directory available"
        }
    }
}

extension PersistedLocalVaultStoreFactory {
    private func makeUniqueArchiveDirectoryURL() -> URL {
        let baseName = archiveDirectoryName()
        var candidateURL = storageDirectory.appending(path: baseName)
        var suffix = 2

        while fileExists(at: candidateURL) {
            candidateURL = storageDirectory.appending(path: "\(baseName)-\(suffix)")
            suffix += 1
        }

        return candidateURL
    }

    private func storeBundleURLs(storeURL: URL) -> [URL] {
        let sidecarURLs = Self.storeSidecarSuffixes.map { suffix in
            URL(fileURLWithPath: storeURL.path(percentEncoded: false) + suffix)
        }
        return [
            storeURL,
            PendingKillphraseRehashStore.defaultURL(storeDirectory: storageDirectory),
            PendingSearchPassphraseRehashStore.defaultURL(storeDirectory: storageDirectory),
        ] + sidecarURLs
    }

    private func fileExists(at url: URL) -> Bool {
        fileManager.fileExists(atPath: url.path(percentEncoded: false))
    }
}
