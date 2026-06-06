import Foundation
import FoundationExtensions
import TestHelpers
import Testing
import VaultCore
@testable import VaultBackup

struct VaultBackupDecryptorTests {
    @Test
    func decryptBackupPayload_throwsForIncompatibleVersion() throws {
        let key = KeyData<32>.repeating(byte: 0xAA)
        let sut = makeSUT(key: key)

        let encryptedVault = EncryptedVault(
            version: "2.0.0",
            data: Data(),
            authentication: Data(),
            encryptionIV: Data(),
            keygenSalt: Data(),
            keygenSignature: "my-signature",
        )

        #expect(throws: (any Error).self) {
            try sut.decryptBackupPayload(from: encryptedVault)
        }
    }

    @Test
    func decryptBackupPayload_decryptsVaultWithCorrectKey() throws {
        let key = KeyData<32>.repeating(byte: 0xAA)
        let sut = makeSUT(key: key)

        let encryptedVault = EncryptedVault(
            version: "1.0.0",
            data: Data(hex: """
            866de95d08a6b24751cdc4e9ab793585614c2062ba690a77762735d1abc866835ad0b54d1e3f29e9ffc4ad1d26a55e3a198ca9f685225042d331df50d64ad495f2a75c30000c6929c6e38a1bbfa16f0d3b81581c0d8f18ffc1df7ec773cfaa16068eb9b00c2de1268a459b3a6ae081dcdf81fe06d80ee23c8c44cb8ae6c61f519ffd7b1ce50efdbcd35e2a1e1eebd0571c924e0ad55f3f85a07b203005aea9e1314e85d36d065de2
            """),
            authentication: Data(hex: """
            f5228102f094dbc0703270d39bac6b81
            """),
            encryptionIV: Data(hex: """
            abababababababababababababababababababababababababababababababab
            """),
            keygenSalt: Data(),
            keygenSignature: "my-signature",
        )

        let backup = try sut.decryptBackupPayload(from: encryptedVault)

        #expect(backup.items == [])
        #expect(backup.obfuscationPadding == Data())
        #expect(backup.version == "1.0.0")
        #expect(backup.created == .init(timeIntervalSince1970: 1234))
    }

    @Test
    func decryptBackupPayload_failsToDecryptGoodPayloadForInvalidKey() throws {
        let key = KeyData<32>.repeating(byte: 0xBB)
        let sut = makeSUT(key: key)

        let encryptedVault = EncryptedVault(
            version: "1.0.0",
            data: Data(hex: """
            866de95d08a6b24751cdc4e9ab793585614c2062ba690a77762735d1abc866835ad0b54d1e3f29e9ffc4ad1d26a55e3a198ca9f685225042d331df50d64ad495f2a75c30000c6929c6e38a1bbfa16f0d3b81581c0d8f18ffc1df7ec773cfaa16068eb9b00c2de1268a459b3a6ae081dcdf81fe06d80ee23c8c44cb8ae6c61f519ffd7b1ce50efdbcd35e2a1e1eebd0571c924e0ad55f3f85a07b203005aea9e1314e85d36d065de2
            """),
            authentication: Data(hex: """
            f5228102f094dbc0703270d39bac6b81
            """),
            encryptionIV: Data(hex: """
            abababababababababababababababababababababababababababababababab
            """),
            keygenSalt: Data(),
            keygenSignature: "my-signature",
        )

        #expect(throws: (any Error).self) {
            try sut.decryptBackupPayload(from: encryptedVault)
        }
    }

    @Test
    func decryptBackupPayload_failsToDecryptMalformedAuthentication() throws {
        let key = KeyData<32>.repeating(byte: 0xAA)
        let sut = makeSUT(key: key)

        let encryptedVault = EncryptedVault(
            version: "1.0.0",
            data: Data(hex: """
            866de95d08a6b24751cdc4e9ab793585614c2062ba690a77762735d1abc866835ad0b54d1e3f29e9ffc4ad1d26a55e3a198ca9f685225042d331df50d64ad495f2a75c30000c6929c6e38a1bbfa16f0d3b81581c0d8f18ffc1df7ec773cfaa16068eb9b00c2de1268a459b3a6ae081dcdf81fe06d80ee23c8c44cb8ae6c61f519ffd7b1ce50efdbcd35e2a1e1eebd0571c924e0ad55f3f85a07b203005aea9e1314e85d36d065de2
            """),
            // malformed
            authentication: Data(hex: """
            f5228102f094dbc0703270d39bac6b82
            """),
            encryptionIV: Data(hex: """
            abababababababababababababababababababababababababababababababab
            """),
            keygenSalt: Data(),
            keygenSignature: "my-signature",
        )

        #expect(throws: (any Error).self) {
            try sut.decryptBackupPayload(from: encryptedVault)
        }
    }

    @Test
    func verifyCanDecrypt_failsToDecryptGoodPayloadForInvalidKey() throws {
        let key = KeyData<32>.repeating(byte: 0xBB)
        let sut = makeSUT(key: key)

        let encryptedVault = EncryptedVault(
            version: "1.0.0",
            data: Data(hex: """
            866de95d08a6b24751cdc4e9ab793585614c2062ba690a77762735d1abc866835ad0b54d1e3f29e9ffc4ad1d26a55e3a198ca9f685225042d331df50d64ad495f2a75c30000c6929c6e38a1bbfa16f0d3b81581c0d8f18ffc1df7ec773cfaa16068eb9b00c2de1268a459b3a6ae081dcdf81fe06d80ee23c8c44cb8ae6c61f519ffd7b1ce50efdbcd35e2a1e1eebd0571c924e0ad55f3f85a07b203005aea9e1314e85d36d065de2
            """),
            authentication: Data(hex: """
            f5228102f094dbc0703270d39bac6b81
            """),
            encryptionIV: Data(hex: """
            abababababababababababababababababababababababababababababababab
            """),
            keygenSalt: Data(),
            keygenSignature: "my-signature",
        )

        #expect(throws: (any Error).self) {
            try sut.decryptBackupPayload(from: encryptedVault)
        }
    }
}

// MARK: - Helpers

extension VaultBackupDecryptorTests {
    private func makeSUT(key: KeyData<32>) -> VaultBackupDecryptor {
        VaultBackupDecryptor(key: key)
    }
}
