import Foundation
import FoundationExtensions
import Testing
@testable import VaultFeed

struct VaultItemTagTests {
    @Test
    func equal_checksWholeObject() {
        let id = makeUniqueIdentifier()

        let tag1 = VaultItemTag(id: id, name: "same")
        let tag2 = VaultItemTag(id: id, name: "same")
        #expect(tag1 == tag2)

        let tagOne = VaultItemTag(id: id, name: "one")
        let tagTwo = VaultItemTag(id: id, name: "two")
        #expect(tagOne != tagTwo)

        let tagWithId1 = VaultItemTag(id: makeUniqueIdentifier(), name: "one")
        let tagWithId2 = VaultItemTag(id: makeUniqueIdentifier(), name: "two")
        #expect(tagWithId1 != tagWithId2)
    }

    @Test
    func hashable_onWholeObject() {
        let id = makeUniqueIdentifier()

        let tag1 = VaultItemTag(id: id, name: "same")
        let tag2 = VaultItemTag(id: id, name: "same")
        #expect(tag1.hashValue == tag2.hashValue)

        let one = VaultItemTag(id: id, name: "one")
        let two = VaultItemTag(id: id, name: "two")
        #expect(one.hashValue != two.hashValue)

        let tagWithId1 = VaultItemTag(id: makeUniqueIdentifier(), name: "one")
        let tagWithId2 = VaultItemTag(id: makeUniqueIdentifier(), name: "two")
        #expect(tagWithId1.hashValue != tagWithId2.hashValue)
    }
}

// MARK: - Helpers

extension VaultItemTagTests {
    private func makeUniqueIdentifier() -> Identifier<VaultItemTag> {
        .init(id: UUID())
    }
}
