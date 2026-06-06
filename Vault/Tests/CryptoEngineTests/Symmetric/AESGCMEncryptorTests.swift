import CryptoEngine
import CryptoSwift
import Foundation
import Testing

struct AESGCMEncryptorTests {
    @Test(arguments: [
        Data(),
        Data.random(count: 1),
        Data.random(count: 15),
        Data.random(count: 100),
    ])
    func encrypt_throwsForInvalidKeyByteLength(key: Data) throws {
        let sut = makeSUT(key: key)

        #expect(throws: (any Error).self) {
            try sut.encrypt(plaintext: anyData(), iv: Data())
        }
    }

    @Test
    func encrypt_performsKnownGoodOperationWithZero() throws {
        let key = Data(hex: "0x00000000000000000000000000000000")
        let iv = Data(hex: "0x000000000000000000000000")
        let sut = makeSUT(key: key)

        let message = Data()
        let result = try sut.encrypt(plaintext: message, iv: iv)

        #expect(result.ciphertext == Data([]))
        #expect(result.authenticationTag == Data(hex: "58e2fccefa7e3061367f1d57a4e7455a"))
    }

    @Test
    func encrypt_performsKnownGoodOperationWithMessage() throws {
        let key = Data(hex: "0xfeffe9928665731c6d6a8f9467308308")
        let iv = Data(hex: "0xcafebabefacedbaddecaf888")
        let sut = makeSUT(key: key)

        let message =
            Data(
                hex: "0xd9313225f88406e5a55909c5aff5269a86a7a9531534f7da2e4c303d8a318a721c3c0c95956809532fcf0e2449a6b525b16aedf5aa0de657ba637b391aafd255",
            )
        let result = try sut.encrypt(plaintext: message, iv: iv)

        #expect(
            result.ciphertext ==
                Data(
                    hex: "0x42831ec2217774244b7221b784d0d49ce3aa212f2c02a4e035c17e2329aca12e21d514b25466931c7d8f6a5aac84aa051ba30b396a0aac973d58e091473f5985",
                ),
        )
        #expect(result.authenticationTag == Data(hex: "0x4d5c2af327cd64a62cf35abd2ba6fab4"))
    }
}

// MARK: - Helpers

extension AESGCMEncryptorTests {
    private func makeSUT(key: Data = anyData()) -> AESGCMEncryptor {
        AESGCMEncryptor(key: key)
    }
}
