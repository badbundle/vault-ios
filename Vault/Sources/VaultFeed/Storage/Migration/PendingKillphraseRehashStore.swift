import Foundation

/// Persisted as a sibling of the SwiftData store during the V1 → V2 schema
/// migration. Records the plaintext killphrases that were dropped from the
/// schema in Phase A so they can be hashed and written back in Phase B
/// (after the vault key becomes available on first post-update unlock).
///
/// On disk this is a JSON file written with file protection
/// `.completeFileProtectionUntilFirstUserAuthentication`. The window of
/// exposure is the narrow gap between a successful schema migration and
/// the user's first unlock that triggers `KillphraseRehashService.run`.
///
/// The file is cleared (and securely overwritten before deletion) once
/// all entries have been re-hashed.
///
/// `FileManager` is documented thread-safe for the basic operations used
/// here (`fileExists`, `attributesOfItem`, `removeItem`) and the call
/// sites only ever hop through this struct serially via the rehash
/// service. Marked `@unchecked Sendable` so the injected dependency does
/// not force every caller to wrap it.
struct PendingKillphraseRehashStore: @unchecked Sendable { // swiftlint:disable:this no_unchecked_sendable
    struct Entry: Codable, Equatable, Sendable {
        let itemID: UUID
        let phrase: String
    }

    private let fileURL: URL
    private let fileManager: FileManager
    private let protectedWrite: (Data, URL) throws -> Void
    private let overwriteWrite: (Data, URL) throws -> Void

    init(
        fileURL: URL,
        fileManager: FileManager = .default,
        protectedWrite: @escaping (Data, URL) throws -> Void = { data, url in
            try data.write(to: url, options: [.atomic, .completeFileProtectionUntilFirstUserAuthentication])
        },
        overwriteWrite: @escaping (Data, URL) throws -> Void = { data, url in
            try data.write(to: url, options: [.atomic])
        },
    ) {
        self.fileURL = fileURL
        self.fileManager = fileManager
        self.protectedWrite = protectedWrite
        self.overwriteWrite = overwriteWrite
    }

    /// Default location alongside the SwiftData store.
    static func defaultURL(storeDirectory: URL) -> URL {
        storeDirectory.appending(path: "vault-primary.pending-killphrase-rehash.json")
    }

    /// Read all pending entries. Returns an empty array if no file exists.
    func read() throws -> [Entry] {
        guard fileManager.fileExists(atPath: fileURL.path(percentEncoded: false)) else {
            return []
        }
        let data = try Data(contentsOf: fileURL)
        guard data.isEmpty == false else { return [] }
        return try JSONDecoder().decode([Entry].self, from: data)
    }

    /// Write a snapshot. Overwrites any existing file. File protection is
    /// applied so the data is unreadable until the user has authenticated
    /// the device at least once after boot.
    func write(_ entries: [Entry]) throws {
        let data = try JSONEncoder().encode(entries)
        try protectedWrite(data, fileURL)
    }

    /// Overwrite the file with zeros, then delete. Best-effort residue
    /// minimisation; the file system may still retain copies depending on
    /// underlying storage.
    func clear() throws {
        guard fileManager.fileExists(atPath: fileURL.path(percentEncoded: false)) else {
            return
        }
        if let size = try? fileManager.attributesOfItem(
            atPath: fileURL.path(percentEncoded: false),
        )[.size] as? Int, size > 0 {
            let zeros = Data(count: size)
            try? overwriteWrite(zeros, fileURL)
        }
        try fileManager.removeItem(at: fileURL)
    }
}
