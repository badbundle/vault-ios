import Foundation
import TestHelpers
import Testing
import VaultBackup
import VaultKeygen
@testable import VaultFeed

struct EncryptedVaultDecoderTests {
    @Test
    func verifyCanDecrypt_successIfDecryptionSuccess() throws {
        let password = DerivedEncryptionKey(key: .random(), salt: .random(count: 32), keyDervier: .testing)
        let encryptedBackup = try makeEncryptedVault(password: password, description: "my backup", items: [], tags: [])
        let sut = makeSUT()

        try sut.verifyCanDecrypt(key: password.key, encryptedVault: encryptedBackup)
    }

    @Test
    func verifyCanDecrypt_throwsDecryptionErrorIfFailed() throws {
        let password = DerivedEncryptionKey(key: .random(), salt: .random(count: 32), keyDervier: .testing)
        let encryptedBackup = try makeEncryptedVault(password: password, description: "my backup", items: [], tags: [])
        let sut = makeSUT()

        #expect(throws: EncryptedVaultDecoderError.decryption) {
            try sut.verifyCanDecrypt(key: .random(), encryptedVault: encryptedBackup)
        }
    }

    @Test
    func decryptAndDecode_decodesWithNoItems() throws {
        let password = DerivedEncryptionKey(key: .random(), salt: .random(count: 32), keyDervier: .testing)
        let encryptedBackup = try makeEncryptedVault(password: password, description: "my backup", items: [], tags: [])
        let sut = makeSUT()

        let decoded = try sut.decryptAndDecode(key: password.key, encryptedVault: encryptedBackup)

        #expect(decoded.items == [])
        #expect(decoded.tags == [])
        #expect(decoded.userDescription == "my backup")
    }

    @Test
    func decryptAndDecode_decodesWithItems() throws {
        let item1 = uniqueVaultItem()
        let tag1 = VaultItemTag(id: .init(id: UUID()), name: "tag1")
        let tag2 = VaultItemTag(id: .init(id: UUID()), name: "tag2")
        let password = DerivedEncryptionKey(key: .random(), salt: .random(count: 32), keyDervier: .testing)
        let encryptedBackup = try makeEncryptedVault(
            password: password,
            description: "my backup description",
            items: [item1],
            tags: [tag1, tag2],
        )
        let sut = makeSUT()

        let decoded = try sut.decryptAndDecode(key: password.key, encryptedVault: encryptedBackup)

        #expect(decoded.items.map(\.id) == [item1].map(\.id))
        #expect(decoded.tags == [tag1, tag2])
        #expect(decoded.userDescription == "my backup description")
    }

    @Test
    func decryptAndDecode_throwsDecryptionErrorIfFailed() throws {
        let password = DerivedEncryptionKey(key: .random(), salt: .random(count: 32), keyDervier: .testing)
        let encryptedBackup = try makeEncryptedVault(password: password, description: "my backup", items: [], tags: [])
        let sut = makeSUT()

        #expect(throws: EncryptedVaultDecoderError.decryption) {
            _ = try sut.decryptAndDecode(key: .random(), encryptedVault: encryptedBackup)
        }
    }

    @Test
    func decoderErrorsExposeLocalizedText() {
        let errors: [EncryptedVaultDecoderError] = [
            .incompatibleVersion,
            .decryption,
            .decoding,
        ]

        for error in errors {
            #expect(error.errorDescription?.isEmpty == false)
            #expect(error.failureReason?.isEmpty == false)
        }
    }
}

// MARK: - Helpers

extension EncryptedVaultDecoderTests {
    private func makeSUT() -> EncryptedVaultDecoderImpl {
        EncryptedVaultDecoderImpl()
    }

    private func makeEncryptedVault(
        password: DerivedEncryptionKey,
        description: String = "any",
        items: [VaultItem] = [],
        tags: [VaultItemTag] = [],
    ) throws -> EncryptedVault {
        let encoder = EncryptedVaultEncoder(clock: EpochClockMock(currentTime: 100), backupPassword: password)
        let payload = VaultApplicationPayload(userDescription: description, items: items, tags: tags)
        return try encoder.encryptAndEncode(payload: payload)
    }
}
