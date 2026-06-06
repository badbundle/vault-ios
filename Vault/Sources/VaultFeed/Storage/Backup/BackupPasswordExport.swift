import Foundation
import FoundationExtensions
import VaultKeygen

public struct BackupPasswordExport {
    /// The version for this export, since it may be exported and imported
    /// by different versions of the vault app binary.
    var version: SemVer
    var key: KeyData<32>
    var salt: Data
    var keyDeriver: VaultKeyDeriver.Signature
}

extension BackupPasswordExport: Codable {
    enum CodingKeys: String, CodingKey {
        case version = "VERSION"
        case key = "KEY"
        case salt = "SALT"
        case keyDeriver = "KEY_DERIVER"
    }
}

// MARK: - Versions

extension BackupPasswordExport {
    static func createV1Export(
        key: KeyData<32>,
        salt: Data,
        keyDeriver: VaultKeyDeriver.Signature,
    ) -> BackupPasswordExport {
        BackupPasswordExport(
            version: "1.0.0",
            key: key,
            salt: salt,
            keyDeriver: keyDeriver,
        )
    }
}
