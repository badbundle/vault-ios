import Foundation
import FoundationExtensions

/// A symmetric key used for encryption and decryption.
public struct VaultKey {
    /// The key.
    public var key: KeyData<32>
    /// Initialization vector.
    public var iv: KeyData<32>

    public init(key: KeyData<32>, iv: KeyData<32>) {
        self.key = key
        self.iv = iv
    }
}
