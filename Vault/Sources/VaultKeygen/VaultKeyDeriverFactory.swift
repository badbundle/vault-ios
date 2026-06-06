import Foundation
import FoundationExtensions

/// @mockable
public protocol VaultKeyDeriverFactory: Sendable {
    /// Create the key deriver that should be used to encrypt a vault backup.
    func makeVaultBackupKeyDeriver() -> VaultKeyDeriver
    /// Create the key deriver that should be used for encrypting individual items within a vault
    func makeVaultItemKeyDeriver() -> VaultKeyDeriver
    func lookupVaultKeyDeriver(signature: VaultKeyDeriver.Signature) -> VaultKeyDeriver
}

public struct VaultKeyDeriverFactoryImpl: VaultKeyDeriverFactory {
    public init() {}
    public func makeVaultBackupKeyDeriver() -> VaultKeyDeriver {
        #if DEBUG
        // A fast key dervier that is relatively insecure, but runs in <5s in DEBUG on any reasonable hardware.
        return VaultKeyDeriver.Backup.Fast.v1
        #else
        // This is very slow to run in DEBUG, due to lack of optimizations.
        return VaultKeyDeriver.Backup.Secure.v1
        #endif
    }

    public func makeVaultItemKeyDeriver() -> VaultKeyDeriver {
        #if DEBUG
        return VaultKeyDeriver.Item.Fast.v1
        #else
        // Very slow in DEBUG
        return VaultKeyDeriver.Item.Secure.v1
        #endif
    }

    public func lookupVaultKeyDeriver(signature: VaultKeyDeriver.Signature) -> VaultKeyDeriver {
        VaultKeyDeriver.lookup(signature: signature)
    }
}

/// Always uses and looks up the testing deriver, to ensure that tests run fast.
public struct VaultKeyDeriverFactoryTesting: VaultKeyDeriverFactory {
    public init() {}
    public func makeVaultBackupKeyDeriver() -> VaultKeyDeriver {
        .testing
    }

    public func makeVaultItemKeyDeriver() -> VaultKeyDeriver {
        .testing
    }

    public func lookupVaultKeyDeriver(signature _: VaultKeyDeriver.Signature) -> VaultKeyDeriver {
        .testing
    }
}

extension VaultKeyDeriverFactory where Self == VaultKeyDeriverFactoryTesting {
    public static var testing: Self {
        VaultKeyDeriverFactoryTesting()
    }
}

/// Always uses the key deriver that generates a key generation error.
public struct VaultKeyDeriverFactoryFailing: VaultKeyDeriverFactory {
    public init() {}
    public func makeVaultBackupKeyDeriver() -> VaultKeyDeriver {
        .failing
    }

    public func makeVaultItemKeyDeriver() -> VaultKeyDeriver {
        .failing
    }

    public func lookupVaultKeyDeriver(signature _: VaultKeyDeriver.Signature) -> VaultKeyDeriver {
        .failing
    }
}

extension VaultKeyDeriverFactory where Self == VaultKeyDeriverFactoryFailing {
    public static var failing: Self {
        VaultKeyDeriverFactoryFailing()
    }
}
