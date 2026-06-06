import CryptoEngine
import Foundation
import FoundationExtensions

public struct DerivedEncryptionKey: Equatable, Hashable, Sendable {
    /// The derived key (via keygen) from the user's password.
    /// (We don't store the password, only the derived key).
    public var key: KeyData<32>
    /// The salt used in the keygen process to derive `key`.
    public var salt: Data
    /// The keygen that was used to derive this password.
    public var keyDervier: VaultKeyDeriver.Signature

    public init(key: KeyData<32>, salt: Data, keyDervier: VaultKeyDeriver.Signature) {
        self.key = key
        self.salt = salt
        self.keyDervier = keyDervier
    }
}

extension DerivedEncryptionKey: CustomDebugStringConvertible {
    public var debugDescription: String {
        "DerviedEncryptionKey(data: \(key.data.toHexString()), salt: \(salt.toHexString()), keyDeriver: \(keyDervier.rawValue))"
    }
}

// MARK: - Keygen

extension DerivedEncryptionKey {
    public func newVaultKeyWithRandomIV() throws -> VaultKey {
        .init(key: key, iv: .random())
    }
}
