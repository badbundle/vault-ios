import Foundation
import FoundationExtensions
import VaultCore
public import VaultFeed

/// Reads the shared vault store from the widget extension process and
/// surfaces only those items that pass `VaultItemWidgetEligibility`.
///
/// The widget extension cannot link `VaultiOS` (and therefore cannot use
/// `VaultRoot.vaultStore`), so this type opens its own `PersistedLocalVaultStore`
/// pointed at the same App Group container.
public actor WidgetVaultLoader {
    /// Process-wide default instance. Widget timeline providers should reuse
    /// the same loader across calls so the underlying `ModelContainer` is
    /// built once.
    public static let shared = WidgetVaultLoader()

    private let store: PersistedLocalVaultStore

    public init(store: PersistedLocalVaultStore? = nil) {
        if let store {
            self.store = store
        } else {
            self.store = PersistedLocalVaultStoreFactory(
                storageDirectory: VaultSharedStorage.directory(),
            ).makeVaultStore()
        }
    }

    /// All items that are currently eligible to appear in a widget. Hidden,
    /// locked, killphrase-protected, and search-passphrase items are filtered
    /// out — see `VaultItemWidgetEligibility`.
    public func eligibleItems() async throws -> [VaultItem] {
        let result = try await store.retrieve(query: .init())
        return result.items.filter(VaultItemWidgetEligibility.isEligible)
    }

    /// Fetch a single eligible item by id. Returns `nil` when the item does
    /// not exist or has become ineligible since the user configured the widget.
    /// The two states are indistinguishable to callers by design (manifesto C2).
    public func eligibleItem(id: UUID) async throws -> VaultItem? {
        let result = try await store.retrieve(query: .init())
        guard let item = result.items.first(where: { $0.id.rawValue == id }) else {
            return nil
        }
        return VaultItemWidgetEligibility.isEligible(item) ? item : nil
    }
}
