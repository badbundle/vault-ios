import Foundation
import FoundationExtensions
import PDFKit
import VaultBackup
import VaultKeygen

/// Controls the state and flow of logic during import operations.
struct BackupImportFlowState {
    /// Actions that should be taken given the current state.
    enum Action {
        /// Decryption was successful, but the data is corrupt.
        ///
        /// More details on the attached error.
        case backupDataError(any Error)
        /// Decryption password was invalid, the user should try again with a different
        /// password.
        case promptForDifferentPassword
        case readyToImport(VaultApplicationPayload)
    }

    let encryptedVault: EncryptedVault
    let encryptedVaultDecoder: any EncryptedVaultDecoder<KeyData<32>>

    /// There was a password provided, handle the state.
    func passwordProvided(password: DerivedEncryptionKey?) -> Action {
        guard let password else { return .promptForDifferentPassword }
        do {
            let applicationPayload = try encryptedVaultDecoder.decryptAndDecode(
                key: password.key,
                encryptedVault: encryptedVault,
            )
            return .readyToImport(applicationPayload)
        } catch EncryptedVaultDecoderError.decryption {
            return .promptForDifferentPassword
        } catch {
            return .backupDataError(error)
        }
    }
}
