import Foundation
import FoundationExtensions
import TestHelpers
import Testing
import VaultCore
@testable import VaultFeed

struct VaultItemTests {
    @Test
    func isContentEqual_comparesIDs() {
        let id = Identifier<VaultItem>()
        let item1 = makeVaultItem(id: id)
        let item2 = makeVaultItem(id: id)

        #expect(item1.isContentEqual(to: item2))

        let item3 = makeVaultItem(id: Identifier<VaultItem>())
        let item4 = makeVaultItem(id: Identifier<VaultItem>())

        #expect(!item3.isContentEqual(to: item4))
    }

    @Test
    func isContentEqual_comparesContent() {
        let id = Identifier<VaultItem>()
        let item1 = makeVaultItem(id: id, userDescription: "hello")
        let item2 = makeVaultItem(id: id, userDescription: "hello")

        #expect(item1.isContentEqual(to: item2))

        let item3 = makeVaultItem(id: id, userDescription: "NO")
        let item4 = makeVaultItem(id: id, userDescription: "YES")

        #expect(!item3.isContentEqual(to: item4))
    }

    @Test
    func isContentEqual_doesNotCompareCreatedDate() {
        let id = Identifier<VaultItem>()
        let date = Date(timeIntervalSince1970: 1234)
        let item1 = makeVaultItem(id: id, created: date)
        let item2 = makeVaultItem(id: id, created: date)

        #expect(item1.isContentEqual(to: item2))

        let item3 = makeVaultItem(id: id, created: Date(timeIntervalSince1970: 10000))
        let item4 = makeVaultItem(id: id, created: Date(timeIntervalSince1970: 12345))

        #expect(item3.isContentEqual(to: item4), "Even though they differ, created date is not compared")
    }

    @Test
    func isContentEqual_doesNotCompareUpdatedDate() {
        let id = Identifier<VaultItem>()
        let date = Date(timeIntervalSince1970: 1234)
        let item1 = makeVaultItem(id: id, updated: date)
        let item2 = makeVaultItem(id: id, updated: date)

        #expect(item1.isContentEqual(to: item2))

        let item3 = makeVaultItem(id: id, updated: Date(timeIntervalSince1970: 10000))
        let item4 = makeVaultItem(id: id, updated: Date(timeIntervalSince1970: 12345))

        #expect(item3.isContentEqual(to: item4), "Even though they differ, updated date is not compared")
    }
}

// MARK: - Helpers

extension VaultItemTests {
    private func makeVaultItem(
        id: Identifier<VaultItem>,
        created: Date = Date(timeIntervalSince1970: 100),
        updated: Date = Date(timeIntervalSince1970: 200),
        relativeOrder: UInt64 = .min,
        userDescription: String = "Any",
        tags: Set<Identifier<VaultItemTag>> = [],
        visibility: VaultItemVisibility = .always,
        searchableLevel: VaultItemSearchableLevel = .full,
        searchPassphrase: SearchPassphraseDigest? = nil,
        killphrase: KillphraseDigest? = nil,
        lockState: VaultItemLockState = .notLocked,
        color: VaultItemColor? = nil,
        format: TextFormat = .markdown,
    ) -> VaultItem {
        VaultItem(
            metadata: .init(
                id: id,
                created: created,
                updated: updated,
                relativeOrder: relativeOrder,
                userDescription: userDescription,
                tags: tags,
                visibility: visibility,
                searchableLevel: searchableLevel,
                searchPassphrase: searchPassphrase,
                killphrase: killphrase,
                lockState: lockState,
                color: color,
                showInQuickType: true,
                previewMode: .titleAndFirstLine,
            ),
            item: .secureNote(.init(title: "title", contents: "contents", format: format)),
        )
    }
}
