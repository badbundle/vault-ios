import Foundation
import SwiftData
import Testing
@testable import VaultFeed

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
        #expect(fileExists(at: archiveURL) == false)
    }

    @Test
    func makeVaultStore_preservesExistingValidStoreContentsAcrossReopen() async throws {
        let directory = try makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let factory = PersistedLocalVaultStoreFactory(
            storageDirectory: directory,
            archiveDirectoryName: { "failed-store" },
        )
        var openedStore: PersistedLocalVaultStore? = factory.makeVaultStore()
        let item = uniqueVaultItem().makeWritable()
        let itemID = try await #require(openedStore).insert(item: item)
        openedStore = nil

        let reopenedStore = factory.makeVaultStore()
        let result = try await reopenedStore.retrieve(query: .init())

        #expect(result.items.map(\.id).contains(itemID))
        #expect(fileExists(at: directory.appending(path: "failed-store")) == false)
    }

    @Test
    func makeVaultStore_archivesUnreadableExistingStoreThenCreatesFreshStore() async throws {
        let directory = try makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let storeURL = url(for: .primary, in: directory)
        let walURL = url(for: .wal, in: directory)
        let shmURL = url(for: .shm, in: directory)
        let pendingKillphraseURL = url(for: .pendingKillphrase, in: directory)
        let pendingSearchPassphraseURL = url(for: .pendingSearchPassphrase, in: directory)
        let corruptData = Data("not a sqlite store".utf8)
        let walData = Data("wal".utf8)
        let shmData = Data("shm".utf8)
        let pendingKillphraseData = Data("[{\"itemID\":\"00000000-0000-0000-0000-000000000001\",\"phrase\":\"one\"}]"
            .utf8)
        let pendingSearchPassphraseData = Data(
            "[{\"itemID\":\"00000000-0000-0000-0000-000000000002\",\"phrase\":\"two\"}]"
                .utf8,
        )
        try corruptData.write(to: storeURL)
        try walData.write(to: walURL)
        try shmData.write(to: shmURL)
        try pendingKillphraseData.write(to: pendingKillphraseURL)
        try pendingSearchPassphraseData.write(to: pendingSearchPassphraseURL)
        let archiveURL = directory.appending(path: "failed-store")
        let sut = PersistedLocalVaultStoreFactory(
            storageDirectory: directory,
            archiveDirectoryName: { "failed-store" },
        )

        let store = sut.makeVaultStore()
        let itemID = try await store.insert(item: uniqueVaultItem().makeWritable())
        let reopenedStore = PersistedLocalVaultStoreFactory(
            storageDirectory: directory,
            archiveDirectoryName: { "unused" },
        ).makeVaultStore()
        let result = try await reopenedStore.retrieve(query: .init())

        #expect(result.items.map(\.id).contains(itemID))
        #expect(try Data(contentsOf: archiveURL.appending(path: storeURL.lastPathComponent)) == corruptData)
        #expect(try Data(contentsOf: archiveURL.appending(path: walURL.lastPathComponent)) == walData)
        #expect(try Data(contentsOf: archiveURL.appending(path: shmURL.lastPathComponent)) == shmData)
        #expect(try Data(contentsOf: archiveURL.appending(path: pendingKillphraseURL.lastPathComponent)) ==
            pendingKillphraseData)
        #expect(
            try Data(contentsOf: archiveURL.appending(path: pendingSearchPassphraseURL.lastPathComponent))
                == pendingSearchPassphraseData,
        )
        #expect(fileExists(at: pendingKillphraseURL) == false)
        #expect(fileExists(at: pendingSearchPassphraseURL) == false)
    }

    @Test
    func makeVaultStore_archivesUnreadableStoreIntoNextUniqueDirectoryWhenArchiveExists() async throws {
        let directory = try makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let storeURL = url(for: .primary, in: directory)
        let corruptData = Data("not a sqlite store".utf8)
        try corruptData.write(to: storeURL)
        try FileManager.default.createDirectory(
            at: directory.appending(path: "failed-store"),
            withIntermediateDirectories: true,
        )
        let sut = PersistedLocalVaultStoreFactory(
            storageDirectory: directory,
            archiveDirectoryName: { "failed-store" },
        )

        let store = sut.makeVaultStore()
        let result = try await store.retrieve(query: .init())

        let archiveURL = directory.appending(path: "failed-store-2")
        #expect(result == .empty())
        #expect(try Data(contentsOf: archiveURL.appending(path: storeURL.lastPathComponent)) == corruptData)
    }

    @Test
    func makeVaultStoreOrThrow_doesNotRecoverWhenInitialOpenSucceeds() throws {
        let directory = makeDirectoryURL()
        let storeURL = url(for: .primary, in: directory)
        let fileSystem = FakeRecoveryFileSystem(existingFiles: [storeURL])
        let opener = ScriptedStoreOpener(results: [.success])
        let sut = makeSUT(directory: directory, opener: opener, fileSystem: fileSystem)

        _ = try sut.makeVaultStoreOrThrow()

        #expect(opener.openedStoreURLs == [storeURL])
        #expect(fileSystem.createdDirectories == [])
        #expect(fileSystem.movedItems.isEmpty)
    }

    @Test(arguments: FatalMessageScenario.all)
    func makeVaultStore_routesUnrecoverableFailuresThroughFatalMessage(_ scenario: FatalMessageScenario) throws {
        let directory = makeDirectoryURL()
        let primaryURL = url(for: .primary, in: directory)
        let fileSystem = switch scenario.failure {
        case .noActiveFiles:
            FakeRecoveryFileSystem()
        case .createDirectory:
            FakeRecoveryFileSystem(
                existingFiles: [primaryURL],
                createDirectoryError: FactoryTestError.createDirectory,
            )
        case .retryOpen:
            FakeRecoveryFileSystem(existingFiles: [primaryURL])
        }
        let opener = ScriptedStoreOpener(results: scenario.openResults)
        let recorder = try FailureRecorder()
        let sut = makeSUT(
            directory: directory,
            opener: opener,
            fileSystem: fileSystem,
            failureHandler: recorder.record,
        )

        _ = sut.makeVaultStore()

        #expect(recorder.messages.count == 1)
        #expect(recorder.messages.first?.hasPrefix(scenario.expectedPrefix) == true)
        #expect(recorder.messages.first?.contains(scenario.expectedErrorDescription) == true)
    }

    @Test
    func makeVaultStoreOrThrow_failsWithoutRecoveryWhenInitialOpenFailsAndNoActiveFilesExist() {
        let directory = makeDirectoryURL()
        let opener = ScriptedStoreOpener(results: [.failure(FactoryTestError.initialOpen)])
        let fileSystem = FakeRecoveryFileSystem()
        let sut = makeSUT(directory: directory, opener: opener, fileSystem: fileSystem)

        expectStoreConnectionError(.unableToConnect) {
            _ = try sut.makeVaultStoreOrThrow()
        }

        #expect(opener.openedStoreURLs == [url(for: .primary, in: directory)])
        #expect(fileSystem.createdDirectories == [])
        #expect(fileSystem.movedItems.isEmpty)
    }

    @Test(arguments: ActiveFileScenario.all)
    func makeVaultStoreOrThrow_openOnlyModeFailsWithoutRecoveryWhenInitialOpenFails(
        _ scenario: ActiveFileScenario,
    ) {
        let directory = makeDirectoryURL()
        let activeURLs = Set(scenario.files.map { url(for: $0, in: directory) })
        let opener = ScriptedStoreOpener(results: [.failure(FactoryTestError.initialOpen)])
        let fileSystem = FakeRecoveryFileSystem(existingFiles: activeURLs)
        let sut = makeSUT(
            directory: directory,
            opener: opener,
            fileSystem: fileSystem,
            recoveryMode: .openOnly,
        )

        expectStoreConnectionError(.unableToConnect) {
            _ = try sut.makeVaultStoreOrThrow()
        }

        #expect(opener.openedStoreURLs == [url(for: .primary, in: directory)])
        #expect(fileSystem.createdDirectories == [])
        #expect(fileSystem.movedItems.isEmpty)
        for activeURL in activeURLs {
            #expect(fileSystem.fileExists(at: activeURL))
        }
    }

    @Test(arguments: ActiveFileScenario.all)
    func makeVaultStoreOrThrow_archivesActiveFileCombinations(_ scenario: ActiveFileScenario) throws {
        let directory = makeDirectoryURL()
        let archiveURL = directory.appending(path: "failed-store")
        let activeURLs = Set(scenario.files.map { url(for: $0, in: directory) })
        let fileSystem = FakeRecoveryFileSystem(existingFiles: activeURLs)
        let opener = ScriptedStoreOpener(results: [.failure(FactoryTestError.initialOpen), .success])
        let sut = makeSUT(directory: directory, opener: opener, fileSystem: fileSystem)

        _ = try sut.makeVaultStoreOrThrow()

        #expect(fileSystem.createdDirectories == [archiveURL])
        #expect(Set(fileSystem.movedItems.map(\.sourceURL)) == activeURLs)
        #expect(Set(fileSystem.movedItems.map(\.destinationURL)) ==
            Set(activeURLs.map { archiveURL.appending(path: $0.lastPathComponent) }))
        #expect(opener.openedStoreURLs == [url(for: .primary, in: directory), url(for: .primary, in: directory)])
    }

    @Test(arguments: [
        ArchiveNameScenario(existingDirectories: [], expectedName: "failed-store"),
        ArchiveNameScenario(existingDirectories: ["failed-store"], expectedName: "failed-store-2"),
        ArchiveNameScenario(existingDirectories: ["failed-store", "failed-store-2"], expectedName: "failed-store-3"),
    ])
    func makeVaultStoreOrThrow_usesUniqueArchiveDirectory(_ scenario: ArchiveNameScenario) throws {
        let directory = makeDirectoryURL()
        let existingDirectories = Set(scenario.existingDirectories.map { directory.appending(path: $0) })
        let fileSystem = FakeRecoveryFileSystem(
            existingFiles: [url(for: .primary, in: directory)],
            existingDirectories: existingDirectories,
        )
        let opener = ScriptedStoreOpener(results: [.failure(FactoryTestError.initialOpen), .success])
        let sut = makeSUT(directory: directory, opener: opener, fileSystem: fileSystem)

        _ = try sut.makeVaultStoreOrThrow()

        let expectedArchiveURL = directory.appending(path: scenario.expectedName)
        #expect(fileSystem.createdDirectories == [expectedArchiveURL])
        #expect(fileSystem.movedItems.map(\.destinationURL) == [
            expectedArchiveURL.appending(path: url(for: .primary, in: directory).lastPathComponent),
        ])
    }

    @Test(arguments: DisappearingFileScenario.all)
    func makeVaultStoreOrThrow_continuesWhenFileDisappearsDuringRecovery(_ scenario: DisappearingFileScenario) throws {
        let directory = makeDirectoryURL()
        let disappearingURL = url(for: scenario.disappearingFile, in: directory)
        let fileSystem = FakeRecoveryFileSystem(
            existingFiles: Set(scenario.existingFiles.map { url(for: $0, in: directory) }),
            disappearingFiles: [disappearingURL],
        )
        let opener = ScriptedStoreOpener(results: [.failure(FactoryTestError.initialOpen), .success])
        let sut = makeSUT(directory: directory, opener: opener, fileSystem: fileSystem)

        _ = try sut.makeVaultStoreOrThrow()

        #expect(fileSystem.createdDirectories == [directory.appending(path: "failed-store")])
        #expect(fileSystem.movedItems.map(\.sourceURL) == scenario.movedFiles.map { url(for: $0, in: directory) })
        #expect(opener.openedStoreURLs.count == 2)
    }

    @Test
    func makeVaultStoreOrThrow_failsWhenArchiveDirectoryCannotBeCreated() {
        let directory = makeDirectoryURL()
        let fileSystem = FakeRecoveryFileSystem(
            existingFiles: [url(for: .primary, in: directory)],
            createDirectoryError: FactoryTestError.createDirectory,
        )
        let opener = ScriptedStoreOpener(results: [.failure(FactoryTestError.initialOpen), .success])
        let sut = makeSUT(directory: directory, opener: opener, fileSystem: fileSystem)

        expectStoreConnectionError(.unableToRecover) {
            _ = try sut.makeVaultStoreOrThrow()
        }

        #expect(opener.openedStoreURLs.count == 1)
        #expect(fileSystem.movedItems.isEmpty)
    }

    @Test(arguments: LiveMoveFailureScenario.all)
    func makeVaultStoreOrThrow_failsWhenLiveFileCannotBeMoved(_ scenario: LiveMoveFailureScenario) {
        let directory = makeDirectoryURL()
        let failingURL = url(for: scenario.failingFile, in: directory)
        let fileSystem = FakeRecoveryFileSystem(
            existingFiles: Set(scenario.existingFiles.map { url(for: $0, in: directory) }),
            moveErrors: [failingURL: FactoryTestError.move],
        )
        let opener = ScriptedStoreOpener(results: [.failure(FactoryTestError.initialOpen), .success])
        let sut = makeSUT(directory: directory, opener: opener, fileSystem: fileSystem)

        expectStoreConnectionError(.unableToRecover) {
            _ = try sut.makeVaultStoreOrThrow()
        }

        #expect(opener.openedStoreURLs.count == 1)
        #expect(fileSystem.fileExists(at: failingURL))
    }

    @Test
    func makeVaultStoreOrThrow_failsWhenRecoverySucceedsButRetryOpenFails() {
        let directory = makeDirectoryURL()
        let primaryURL = url(for: .primary, in: directory)
        let fileSystem = FakeRecoveryFileSystem(existingFiles: [primaryURL])
        let opener = ScriptedStoreOpener(results: [
            .failure(FactoryTestError.initialOpen),
            .failure(FactoryTestError.retryOpen),
        ])
        let sut = makeSUT(directory: directory, opener: opener, fileSystem: fileSystem)

        expectStoreConnectionError(.unableToConnectAfterRecovery) {
            _ = try sut.makeVaultStoreOrThrow()
        }

        #expect(fileSystem.movedItems.map(\.sourceURL) == [primaryURL])
        #expect(opener.openedStoreURLs.count == 2)
    }
}

enum StoreFile {
    case primary
    case wal
    case shm
    case pendingKillphrase
    case pendingSearchPassphrase
}

struct ActiveFileScenario: CustomStringConvertible {
    let description: String
    let files: [StoreFile]

    static let all: [Self] = [
        .init(description: "primary only", files: [.primary]),
        .init(description: "primary and WAL", files: [.primary, .wal]),
        .init(description: "primary and SHM", files: [.primary, .shm]),
        .init(description: "primary and sidecars", files: [.primary, .wal, .shm]),
        .init(description: "primary and pending killphrase", files: [.primary, .pendingKillphrase]),
        .init(description: "primary and pending search passphrase", files: [.primary, .pendingSearchPassphrase]),
        .init(
            description: "primary and both pending files",
            files: [.primary, .pendingKillphrase, .pendingSearchPassphrase],
        ),
        .init(description: "sidecars and pending files without primary", files: [
            .wal,
            .shm,
            .pendingKillphrase,
            .pendingSearchPassphrase,
        ]),
    ]
}

struct ArchiveNameScenario {
    let existingDirectories: [String]
    let expectedName: String
}

struct FatalMessageScenario: CustomStringConvertible {
    enum Failure {
        case noActiveFiles
        case createDirectory
        case retryOpen
    }

    let description: String
    let failure: Failure
    let openResults: [ScriptedStoreOpener.Result]
    let expectedPrefix: String
    let expectedErrorDescription: String

    static let all: [Self] = [
        .init(
            description: "initial open fails with no active files",
            failure: .noActiveFiles,
            openResults: [.failure(FactoryTestError.initialOpen)],
            expectedPrefix: "Unable to connect to PersistedLocalVaultStore:",
            expectedErrorDescription: "initialOpen",
        ),
        .init(
            description: "archive directory creation fails",
            failure: .createDirectory,
            openResults: [.failure(FactoryTestError.initialOpen)],
            expectedPrefix: "Unable to recover PersistedLocalVaultStore:",
            expectedErrorDescription: "createDirectory",
        ),
        .init(
            description: "retry open fails after recovery",
            failure: .retryOpen,
            openResults: [
                .failure(FactoryTestError.initialOpen),
                .failure(FactoryTestError.retryOpen),
            ],
            expectedPrefix: "Unable to connect to PersistedLocalVaultStore after recovery:",
            expectedErrorDescription: "retryOpen",
        ),
    ]
}

struct DisappearingFileScenario: CustomStringConvertible {
    let description: String
    let existingFiles: [StoreFile]
    let disappearingFile: StoreFile
    let movedFiles: [StoreFile]

    static let all: [Self] = [
        .init(description: "primary disappears", existingFiles: [.primary], disappearingFile: .primary, movedFiles: []),
        .init(
            description: "WAL disappears",
            existingFiles: [.primary, .wal],
            disappearingFile: .wal,
            movedFiles: [.primary],
        ),
        .init(
            description: "SHM disappears",
            existingFiles: [.primary, .shm],
            disappearingFile: .shm,
            movedFiles: [.primary],
        ),
        .init(
            description: "pending killphrase disappears",
            existingFiles: [.primary, .pendingKillphrase],
            disappearingFile: .pendingKillphrase,
            movedFiles: [.primary],
        ),
        .init(
            description: "pending search passphrase disappears",
            existingFiles: [.primary, .pendingSearchPassphrase],
            disappearingFile: .pendingSearchPassphrase,
            movedFiles: [.primary],
        ),
    ]
}

struct LiveMoveFailureScenario: CustomStringConvertible {
    let description: String
    let existingFiles: [StoreFile]
    let failingFile: StoreFile

    static let all: [Self] = [
        .init(description: "primary move fails", existingFiles: [.primary], failingFile: .primary),
        .init(description: "WAL move fails", existingFiles: [.primary, .wal], failingFile: .wal),
        .init(description: "SHM move fails", existingFiles: [.primary, .shm], failingFile: .shm),
        .init(
            description: "pending killphrase move fails",
            existingFiles: [.primary, .pendingKillphrase],
            failingFile: .pendingKillphrase,
        ),
        .init(
            description: "pending search passphrase move fails",
            existingFiles: [.primary, .pendingSearchPassphrase],
            failingFile: .pendingSearchPassphrase,
        ),
    ]
}

private enum StoreConnectionErrorCase {
    case unableToConnect
    case unableToRecover
    case unableToConnectAfterRecovery
}

private enum FactoryTestError: Error {
    case initialOpen
    case retryOpen
    case createDirectory
    case move
    case missingFile
}

final class ScriptedStoreOpener: PersistedLocalVaultStoreOpening {
    enum Result {
        case success
        case failure(any Error & Sendable)
    }

    private var results: [Result]
    private(set) var openedStoreURLs: [URL] = []

    init(results: [Result]) {
        self.results = results
    }

    func open(storeURL: URL) throws -> PersistedLocalVaultStore {
        openedStoreURLs.append(storeURL)
        guard results.isEmpty == false else { return try makeInMemoryStore() }

        switch results.removeFirst() {
        case .success:
            return try makeInMemoryStore()
        case let .failure(error):
            throw error
        }
    }
}

private final class FailureRecorder {
    private let fallbackStore: PersistedLocalVaultStore
    private(set) var messages: [String] = []

    init() throws {
        fallbackStore = try makeInMemoryStore()
    }

    func record(_ message: String) -> PersistedLocalVaultStore {
        messages.append(message)
        return fallbackStore
    }
}

private final class FakeRecoveryFileSystem: PersistedLocalVaultStoreRecoveryFileSystem {
    private var existingFiles: Set<String>
    private var existingDirectories: Set<String>
    private let disappearingFiles: Set<String>
    private let createDirectoryError: (any Error)?
    private let moveErrors: [String: any Error]
    private(set) var createdDirectories: [URL] = []
    private(set) var movedItems: [(sourceURL: URL, destinationURL: URL)] = []

    init(
        existingFiles: Set<URL> = [],
        existingDirectories: Set<URL> = [],
        disappearingFiles: Set<URL> = [],
        createDirectoryError: (any Error)? = nil,
        moveErrors: [URL: any Error] = [:],
    ) {
        self.existingFiles = Set(existingFiles.map(key(for:)))
        self.existingDirectories = Set(existingDirectories.map(key(for:)))
        self.disappearingFiles = Set(disappearingFiles.map(key(for:)))
        self.createDirectoryError = createDirectoryError
        self.moveErrors = Dictionary(uniqueKeysWithValues: moveErrors.map { (key(for: $0.key), $0.value) })
    }

    func fileExists(at url: URL) -> Bool {
        existingFiles.contains(key(for: url)) || existingDirectories.contains(key(for: url))
    }

    func createDirectory(at url: URL) throws {
        if let createDirectoryError {
            throw createDirectoryError
        }
        createdDirectories.append(url)
        existingDirectories.insert(key(for: url))
    }

    func moveItem(at sourceURL: URL, to destinationURL: URL) throws {
        let sourceKey = key(for: sourceURL)
        if disappearingFiles.contains(sourceKey) {
            existingFiles.remove(sourceKey)
            throw FactoryTestError.missingFile
        }
        if let error = moveErrors[sourceKey] {
            throw error
        }
        guard existingFiles.remove(sourceKey) != nil else {
            throw FactoryTestError.missingFile
        }

        movedItems.append((sourceURL, destinationURL))
        existingFiles.insert(key(for: destinationURL))
    }
}

private func makeSUT(
    directory: URL,
    opener: ScriptedStoreOpener,
    fileSystem: FakeRecoveryFileSystem,
    archiveDirectoryName: @escaping () -> String = { "failed-store" },
    recoveryMode: PersistedLocalVaultStoreFactory.RecoveryMode = .recoverExistingStore,
    failureHandler: @escaping (String) -> PersistedLocalVaultStore = { fatalError($0) },
) -> PersistedLocalVaultStoreFactory {
    PersistedLocalVaultStoreFactory(
        storageDirectory: directory,
        storeOpener: opener,
        fileSystem: fileSystem,
        archiveDirectoryName: archiveDirectoryName,
        recoveryMode: recoveryMode,
        failureHandler: failureHandler,
    )
}

private func expectStoreConnectionError(
    _ expected: StoreConnectionErrorCase,
    performing operation: () throws -> Void,
) {
    do {
        try operation()
        Issue.record("Expected \(expected)")
    } catch let error as PersistedLocalVaultStoreFactory.StoreConnectionError {
        switch (expected, error) {
        case (.unableToConnect, .unableToConnect),
             (.unableToRecover, .unableToRecover),
             (.unableToConnectAfterRecovery, .unableToConnectAfterRecovery):
            break
        default:
            Issue.record("Expected \(expected), got \(error)")
        }
    } catch {
        Issue.record("Expected \(expected), got \(error)")
    }
}

private func makeTemporaryDirectory() throws -> URL {
    let url = makeDirectoryURL()
    try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
    return url
}

private func makeInMemoryStore() throws -> PersistedLocalVaultStore {
    let container = try ModelContainer(
        for: PersistedVaultItem.self,
        configurations: .init(isStoredInMemoryOnly: true),
    )
    return PersistedLocalVaultStore(modelContainer: container)
}

private func makeDirectoryURL() -> URL {
    FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
}

private func url(for file: StoreFile, in directory: URL) -> URL {
    switch file {
    case .primary:
        directory.appending(path: "vault-primary.sqlite")
    case .wal:
        URL(fileURLWithPath: url(for: .primary, in: directory).path(percentEncoded: false) + "-wal")
    case .shm:
        URL(fileURLWithPath: url(for: .primary, in: directory).path(percentEncoded: false) + "-shm")
    case .pendingKillphrase:
        directory.appending(path: "vault-primary.pending-killphrase-rehash.json")
    case .pendingSearchPassphrase:
        directory.appending(path: "vault-primary.pending-search-passphrase-rehash.json")
    }
}

private func fileExists(at url: URL) -> Bool {
    FileManager.default.fileExists(atPath: url.path(percentEncoded: false))
}

private func key(for url: URL) -> String {
    url.path(percentEncoded: false)
}
