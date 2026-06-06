import Foundation
import Testing
@testable import VaultFeed

@Suite
struct PersistedLocalVaultStoreFactoryTests {
    @Test
    func makeVaultStore_createsEmptyStoreWhenNoExistingStoreExists() async throws {
        let directory = try makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let archiveURL = directory.appending(path: "failed-store")
        let sut = PersistedLocalVaultStoreFactory(
            storageDirectory: directory,
            archiveDirectoryName: { "failed-store" },
        )

        let store = sut.makeVaultStore()

        let result = try await store.retrieve(query: .init())
        #expect(result == .empty())
        #expect(FileManager.default.fileExists(atPath: archiveURL.path(percentEncoded: false)) == false)
    }

    @Test
    func makeVaultStore_archivesUnreadableExistingStoreThenCreatesFreshStore() async throws {
        let directory = try makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let storeURL = directory.appending(path: "vault-primary.sqlite")
        let walURL = sidecarURL(for: storeURL, suffix: "-wal")
        let shmURL = sidecarURL(for: storeURL, suffix: "-shm")
        let pendingKillphraseURL = directory.appending(path: "vault-primary.pending-killphrase-rehash.json")
        let pendingSearchPassphraseURL = directory
            .appending(path: "vault-primary.pending-search-passphrase-rehash.json")
        try Data("not a sqlite store".utf8).write(to: storeURL)
        try Data("wal".utf8).write(to: walURL)
        try Data("shm".utf8).write(to: shmURL)
        try Data("[]".utf8).write(to: pendingKillphraseURL)
        try Data("[]".utf8).write(to: pendingSearchPassphraseURL)
        let archiveURL = directory.appending(path: "failed-store")
        let sut = PersistedLocalVaultStoreFactory(
            storageDirectory: directory,
            archiveDirectoryName: { "failed-store" },
        )

        let store = sut.makeVaultStore()

        let result = try await store.retrieve(query: .init())
        #expect(result == .empty())
        #expect(FileManager.default
            .fileExists(atPath: archiveURL.appending(path: storeURL.lastPathComponent).path(percentEncoded: false)))
        #expect(FileManager.default
            .fileExists(atPath: archiveURL.appending(path: walURL.lastPathComponent).path(percentEncoded: false)))
        #expect(FileManager.default
            .fileExists(atPath: archiveURL.appending(path: shmURL.lastPathComponent).path(percentEncoded: false)))
        #expect(
            FileManager.default.fileExists(
                atPath: archiveURL.appending(path: pendingKillphraseURL.lastPathComponent).path(percentEncoded: false),
            ),
        )
        #expect(
            FileManager.default.fileExists(
                atPath: archiveURL.appending(path: pendingSearchPassphraseURL.lastPathComponent)
                    .path(percentEncoded: false),
            ),
        )
        #expect(FileManager.default.fileExists(atPath: pendingKillphraseURL.path(percentEncoded: false)) == false)
        #expect(FileManager.default.fileExists(atPath: pendingSearchPassphraseURL.path(percentEncoded: false)) == false)
    }

    private func makeTemporaryDirectory() throws -> URL {
        let url = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    private func sidecarURL(for storeURL: URL, suffix: String) -> URL {
        URL(fileURLWithPath: storeURL.path(percentEncoded: false) + suffix)
    }
}
