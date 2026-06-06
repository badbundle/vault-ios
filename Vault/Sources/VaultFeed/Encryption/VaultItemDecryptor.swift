import Foundation
import FoundationExtensions
import VaultKeygen

/// Use for decrypting and decoding encrypted vault items.
///
/// Counterpart to `VaultItemEncryptor`.
struct VaultItemDecryptor {
    private let key: DerivedEncryptionKey

    init(key: DerivedEncryptionKey) {
        self.key = key
    }

    enum Error: Swift.Error {
        case decryptionFailed(any Swift.Error)
        case decodingFailed(any Swift.Error)
        case mismatchedItemIdentifier(expected: String, actual: String)
    }

    /// Decrypts the identifier for this item, so we know what kind of item it is.
    func decryptItemIdentifier(item: EncryptedItem) throws(Error) -> String {
        let decryptor = AESGCMDecryptor(key: key.key.data)
        let item = try withMappedError {
            try decryptor.decrypt(
                message: .init(ciphertext: item.data, authenticationTag: item.authentication),
                iv: item.encryptionIV,
            )
        } error: {
            Error.decryptionFailed($0)
        }

        let basicFormatDecoded = try withMappedError {
            try makeDecoder().decode(BasicVaultItemEncryptedContainer.self, from: item)
        } error: {
            Error.decodingFailed($0)
        }

        return basicFormatDecoded.itemIdentifier
    }

    /// Decodes and decrypts an encryptable item from the vault.
    func decrypt<T: VaultItemEncryptable>(item: EncryptedItem, expectedItemIdentifier: String) throws(Error) -> T {
        let decryptor = AESGCMDecryptor(key: key.key.data)
        let item = try withMappedError {
            try decryptor.decrypt(
                message: .init(ciphertext: item.data, authenticationTag: item.authentication),
                iv: item.encryptionIV,
            )
        } error: {
            Error.decryptionFailed($0)
        }
        let basicFormatDecoded = try withMappedError {
            try makeDecoder().decode(BasicVaultItemEncryptedContainer.self, from: item)
        } error: {
            Error.decodingFailed($0)
        }

        guard expectedItemIdentifier == basicFormatDecoded.itemIdentifier else {
            throw Error.mismatchedItemIdentifier(
                expected: expectedItemIdentifier,
                actual: basicFormatDecoded.itemIdentifier,
            )
        }

        let decoded = try withMappedError {
            try makeDecoder().decode(T.EncryptedContainer.self, from: item)
        } error: {
            Error.decodingFailed($0)
        }
        return T(encryptedContainer: decoded)
    }

    /// A basic container that conforms to `VaultItemEncryptedContainer` so we can extract minimal information,
    /// confirming that the given item is of the item type that we expect.
    private struct BasicVaultItemEncryptedContainer: VaultItemEncryptedContainer {
        var itemIdentifier: String
        var title: String
    }

    private func makeDecoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .millisecondsSince1970
        decoder.dataDecodingStrategy = .base64
        return decoder
    }
}
