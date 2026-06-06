import Foundation
import FoundationExtensions
import VaultFeed

func anyVaultItemMetadata(
    lockState: VaultItemLockState = .notLocked,
) -> VaultItem.Metadata {
    .init(
        id: Identifier<VaultItem>(),
        created: Date(),
        updated: Date(),
        relativeOrder: .min,
        userDescription: "any",
        tags: [],
        visibility: .always,
        searchableLevel: .full,
        searchPassphrase: nil,
        killphrase: nil,
        lockState: lockState,
        color: .black,
        showInQuickType: true,
        previewMode: .titleAndFirstLine,
    )
}

func anyVaultItem() -> VaultItem {
    VaultItem(
        metadata: anyVaultItemMetadata(),
        item: .secureNote(.init(title: "hello", contents: "hello", format: .markdown)),
    )
}

/// No-op key store for autofill snapshot tests that don't exercise the
/// killphrase digest path. Returns a fixed all-zero key so `loadOrCreate`
/// never fatal-errors when called from VaultDataModel.setup().
struct StubKillphraseKeyStore: KillphraseKeyStore {
    func loadOrCreate() async throws -> KeyData<32> {
        .zero()
    }
}

/// No-op key store for autofill snapshot tests that don't exercise the
/// search-passphrase digest path.
struct StubSearchPassphraseKeyStore: SearchPassphraseKeyStore {
    func loadOrCreate() async throws -> KeyData<32> {
        .zero()
    }
}
