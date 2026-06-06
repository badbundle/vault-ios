import CryptoEngine
import CryptoSwift
import Foundation
import Testing

struct AESGCMDecryptorTests {
    @Test
    func decrypt_decryptsEmptyMessageWithAnyTag() throws {
        let key = Data(hex: "00000000000000000000000000000000")
        let iv = Data(hex: "000000000000000000000000")
        let plaintext = Data(hex: "")
        let message = AESGCMEncryptedMessage(
            ciphertext: Data(hex: ""),
            authenticationTag: Data(hex: "anytag"),
        )

        let sut = makeSUT(key: key)
        let decrypted = try sut.decrypt(message: message, iv: iv)

        #expect(decrypted == plaintext)
    }

    @Test
    func decrypt_decryptsNonEmptyMessage() throws {
        let key = Data(hex: "0xfeffe9928665731c6d6a8f9467308308")
        let iv = Data(hex: "0xcafebabefacedbaddecaf888")
        let plaintext =
            Data(
                hex: "0xd9313225f88406e5a55909c5aff5269a86a7a9531534f7da2e4c303d8a318a721c3c0c95956809532fcf0e2449a6b525b16aedf5aa0de657ba637b391aafd255",
            )
        let message = AESGCMEncryptedMessage(
            ciphertext: Data(
                hex: "0x42831ec2217774244b7221b784d0d49ce3aa212f2c02a4e035c17e2329aca12e21d514b25466931c7d8f6a5aac84aa051ba30b396a0aac973d58e091473f5985",
            ),
            authenticationTag: Data(hex: "0x4d5c2af327cd64a62cf35abd2ba6fab4"),
        )

        let sut = makeSUT(key: key)
        let decrypted = try sut.decrypt(message: message, iv: iv)

        #expect(decrypted == plaintext)
    }

    @Test
    func decrypt_throwsErrorIfTagIsBadForNonEmptyMessage() {
        let key = Data(hex: "0xfeffe9928665731c6d6a8f9467308308")
        let iv = Data(hex: "0xcafebabefacedbaddecaf888")
        let message = AESGCMEncryptedMessage(
            ciphertext: Data(
                hex: "0x42831ec2217774244b7221b784d0d49ce3aa212f2c02a4e035c17e2329aca12e21d514b25466931c7d8f6a5aac84aa051ba30b396a0aac973d58e091473f5985",
            ),
            authenticationTag: Data(hex: "0x4d5c2af327cd64a62cf35abd2ba6fab5"), // tag is slightly off
        )

        let sut = makeSUT(key: key)
        #expect(throws: (any Error).self, performing: {
            try sut.decrypt(message: message, iv: iv)
        })
    }
}

// MARK: - Helpers

extension AESGCMDecryptorTests {
    private func makeSUT(key: Data = anyData()) -> AESGCMDecryptor {
        AESGCMDecryptor(key: key)
    }
}
