import CryptoEngine
import Foundation
import FoundationExtensions

final class VaultDecryptor {
    private let decryptor: AESGCMDecryptor
    init(key: KeyData<32>) {
        decryptor = AESGCMDecryptor(key: key.data)
    }

    func decrypt(encryptedVault: EncryptedVault) throws -> IntermediateEncodedVault {
        let decrypted = try decryptor.decrypt(
            message: .init(ciphertext: encryptedVault.data, authenticationTag: encryptedVault.authentication),
            iv: encryptedVault.encryptionIV,
        )
        return IntermediateEncodedVault(data: decrypted)
    }
}
