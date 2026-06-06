import Foundation
import FoundationExtensions
import VaultCore

public final class VaultBackupDecryptor {
    private let key: KeyData<32>

    public init(key: KeyData<32>) {
        self.key = key
    }

    public enum Error: Swift.Error {
        case incompatibleVersion
        case decryptionFailed(any Swift.Error)
        case decodingFailed(any Swift.Error)
    }

    /// Throws decryption error if fails.
    /// Performs no other validation.
    public func verifyCanDecrypt(encryptedVault: EncryptedVault) throws(Error) {
        try withMappedError {
            _ = try VaultDecryptor(key: key).decrypt(encryptedVault: encryptedVault)
        } error: {
            Error.decryptionFailed($0)
        }
    }

    public func decryptBackupPayload(from encryptedVault: EncryptedVault) throws(Error) -> VaultBackupPayload {
        // Encrypted vault version.
        guard encryptedVault.version.isCompatible(with: "1.0.0") else {
            throw Error.incompatibleVersion
        }
        let encodedVault = try withMappedError {
            try VaultDecryptor(key: key).decrypt(encryptedVault: encryptedVault)
        } error: {
            Error.decryptionFailed($0)
        }
        let backupPayload = try withMappedError {
            try IntermediateEncodedVaultDecoder().decode(encodedVault: encodedVault)
        } error: {
            Error.decodingFailed($0)
        }
        return backupPayload
    }
}
