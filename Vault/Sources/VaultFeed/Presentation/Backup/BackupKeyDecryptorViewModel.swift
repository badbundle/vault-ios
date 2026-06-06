import Combine
import Foundation
import FoundationExtensions
import VaultBackup
import VaultKeygen

@MainActor
@Observable
public final class BackupKeyDecryptorViewModel {
    public enum DecryptionKeyState: Equatable, Hashable {
        case none
        case error(PresentationError)
        case validDecryptionKey

        public var isSuccess: Bool {
            switch self {
            case .validDecryptionKey: true
            case .none, .error: false
            }
        }

        public var isError: Bool {
            switch self {
            case .error: true
            case .none, .validDecryptionKey: false
            }
        }

        public var title: String {
            switch self {
            case .validDecryptionKey: "Decrypted"
            case let .error(error): error.userTitle
            case .none: "Encrypted"
            }
        }

        public var description: String? {
            switch self {
            case .validDecryptionKey: "Your vault has been decrypted."
            case let .error(error): error.userDescription
            case .none: "Your password is needed to decrypt the encrypted vault. Make sure this matches the original password used at the time this backup was created."
            }
        }
    }

    public var enteredPassword = ""
    public private(set) var decryptionKeyState: DecryptionKeyState = .none
    public private(set) var isDecrypting = false
    private let decryptedVaultSubject: PassthroughSubject<VaultApplicationPayload, Never>

    private let encryptedVault: EncryptedVault
    private let keyDeriverFactory: any VaultKeyDeriverFactory
    private let encryptedVaultDecoder: any EncryptedVaultDecoder<KeyData<32>>

    public init(
        encryptedVault: EncryptedVault,
        keyDeriverFactory: any VaultKeyDeriverFactory,
        encryptedVaultDecoder: any EncryptedVaultDecoder<KeyData<32>>,
        decryptedVaultSubject: PassthroughSubject<VaultApplicationPayload, Never>,
    ) {
        self.encryptedVault = encryptedVault
        self.keyDeriverFactory = keyDeriverFactory
        self.encryptedVaultDecoder = encryptedVaultDecoder
        self.decryptedVaultSubject = decryptedVaultSubject
    }

    private struct MissingPasswordError: Error, LocalizedError {
        var errorDescription: String? {
            "Password Required"
        }

        var failureReason: String? {
            "The password cannot be empty"
        }
    }

    public var canAttemptDecryption: Bool {
        enteredPassword.isNotEmpty
    }

    public func attemptDecryption() async {
        do {
            guard enteredPassword.isNotEmpty else { throw MissingPasswordError() }
            isDecrypting = true
            defer { isDecrypting = false }
            let signature = try VaultKeyDeriver.Signature(tryFromString: encryptedVault.keygenSignature)
            let keyDeriver = keyDeriverFactory.lookupVaultKeyDeriver(signature: signature)
            let password = enteredPassword
            let salt = encryptedVault.keygenSalt
            let generatedKey = try await Task.background {
                try keyDeriver.recreateEncryptionKey(password: password, salt: salt)
            }
            let vaultApplicationPayload = try encryptedVaultDecoder.decryptAndDecode(
                key: generatedKey.key,
                encryptedVault: encryptedVault,
            )
            decryptionKeyState = .validDecryptionKey
            decryptedVaultSubject.send(vaultApplicationPayload)
        } catch let error as any LocalizedError {
            decryptionKeyState = .error(.init(localizedError: error))
        } catch {
            decryptionKeyState = .error(PresentationError(
                userTitle: "Password Generation Error",
                userDescription: "Please try again.",
                debugDescription: error.localizedDescription,
            ))
        }
    }
}
