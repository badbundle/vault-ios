import Foundation
import FoundationExtensions
import Testing

struct IdentifierTests {
    @Test
    func new_usesRandomUUID() throws {
        var seen = Set<UUID>()
        for _ in 0 ..< 100 {
            let id = Identifier<Int>.new()
            try #require(!seen.contains(id.id))
            seen.insert(id.id)
        }
    }

    @Test
    func init_defaultUsesRandomUUID() throws {
        var seen = Set<UUID>()
        for _ in 0 ..< 100 {
            let id = Identifier<Int>()
            try #require(!seen.contains(id.id))
            seen.insert(id.id)
        }
    }

    @Test
    func init_fromUUID() {
        let fixed = UUID()
        let id = Identifier<Int>(id: fixed)

        #expect(id.id == fixed)
    }

    @Test
    func init_rawValue() throws {
        let fixed = UUID()
        let id1 = try #require(Identifier<Int>(rawValue: fixed))

        #expect(id1.id == fixed)
    }

    @Test
    func equatable_equals() {
        let fixed = UUID()
        let id1 = Identifier<Int>(id: fixed)
        let id2 = Identifier<Int>(id: fixed)

        #expect(id1 == id2)
    }

    @Test
    func hashable_hashesSameIDs() {
        var set = Set<Identifier<Int>>()

        let fixed = UUID()
        let id1 = Identifier<Int>(id: fixed)
        let id2 = Identifier<Int>(id: fixed)

        set.insert(id1)
        set.insert(id2)

        #expect(set.count == 1)
    }

    @Test
    func uuidString_creates() {
        let fixed = UUID()
        let id1 = Identifier<Int>.uuidString(fixed.uuidString)
        let id2 = Identifier<Int>(id: fixed)

        #expect(id1 == id2)
    }

    @Test
    func map_usesSameIdentifier() {
        let fixed = UUID()
        let id1 = Identifier<Int>(id: fixed)
        let id2: Identifier<String> = id1.map()

        #expect(id1.id == id2.id)
    }

    @Test
    func rawValue_isUUID() {
        let fixed = UUID()
        let id1 = Identifier<Int>(id: fixed)

        #expect(id1.rawValue == fixed)
    }
}
