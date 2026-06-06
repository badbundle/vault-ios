import Foundation
import Testing
@testable import VaultFeed

struct AutoBackupProviderCoverageTests {
    @Test
    func iCloudDriveProvider_unconfiguredStateIsAvailableForSetup() async throws {
        let sut = iCloudDriveProvider()

        #expect(sut.id == iCloudDriveProvider.providerID)
        #expect(sut.displayName == "Files")
        #expect(sut.iconSystemName == "folder")
        #expect(await sut.folderDisplayName == nil)
        #expect(await sut.isConfigured == false)
        #expect(await sut.configurationSummary == nil)
        #expect(await sut.isAvailable)
        #expect(await sut.configurationData != nil)
    }

    @Test
    func iCloudDriveProvider_restoresAndClearsConfiguration() async throws {
        let sut = iCloudDriveProvider()
        let config = iCloudDriveProviderConfiguration(
            folderBookmark: Data([0, 1, 2]),
            folderDisplayName: "Backups",
        )
        let data = try JSONEncoder().encode(config)

        try await sut.restoreConfiguration(from: data)

        #expect(await sut.isConfigured)
        #expect(await sut.folderDisplayName == "Backups")
        #expect(await sut.configurationSummary == "Backups")
        #expect(await sut.isAvailable == false)

        await sut.clearConfiguration()

        #expect(await sut.isConfigured == false)
        #expect(await sut.folderDisplayName == nil)
    }

    @Test
    func iCloudDriveProvider_restoreRejectsInvalidData() async {
        let sut = iCloudDriveProvider()

        await #expect(throws: (any Error).self) {
            try await sut.restoreConfiguration(from: Data("invalid".utf8))
        }
    }

    @Test
    func iCloudDriveProvider_unconfiguredOperationsThrowProviderNotConfigured() async {
        let sut = iCloudDriveProvider()

        await expectProviderNotConfigured {
            try await sut.write(data: Data("payload".utf8), filename: "backup.pdf")
        }
        await expectProviderNotConfigured {
            _ = try await sut.listBackups()
        }
        await expectProviderNotConfigured {
            try await sut.delete(filename: "backup.pdf")
        }
    }

    @Test
    func autoBackupErrorsExposeDescriptionsAndRecoverySuggestions() {
        let cases: [AutoBackupError] = [
            .noProviderSelected,
            .providerNotConfigured,
            .providerUnavailable(reason: "Unavailable"),
            .accessDenied,
            .backupPasswordNotSet,
            .pdfGenerationFailed(reason: "PDF"),
            .writeFailed(reason: "Write"),
            .cleanupFailed(reason: "Cleanup"),
            .networkUnavailable,
            .storageFull,
            .unknown(reason: "Unknown"),
        ]

        for error in cases {
            #expect(error.errorDescription?.isEmpty == false)
            #expect(error.recoverySuggestion?.isEmpty == false)
        }
    }
}

private func expectProviderNotConfigured(
    _ operation: () async throws -> Void,
    sourceLocation: SourceLocation = #_sourceLocation,
) async {
    do {
        try await operation()
        Issue.record("Expected providerNotConfigured", sourceLocation: sourceLocation)
    } catch let error as AutoBackupError {
        #expect(error == .providerNotConfigured, sourceLocation: sourceLocation)
    } catch {
        Issue.record("Expected AutoBackupError, got \(error)", sourceLocation: sourceLocation)
    }
}
