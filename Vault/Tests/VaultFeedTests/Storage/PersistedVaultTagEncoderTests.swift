import Foundation
import SwiftData
import TestHelpers
import Testing
@testable import VaultFeed

final class PersistedVaultTagEncoderTests {
    private let context: ModelContext

    init() throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: PersistedVaultItem.self, configurations: config)
        context = ModelContext(container)
    }
}

// MARK: - Encoding

extension PersistedVaultTagEncoderTests {
    @Test
    func encode_newItemCreatedUUID() {
        let sut = makeSUT()

        var seenIds = Set<UUID>()
        for _ in 1 ... 100 {
            let item = makeWritableVaultItemTag()
            let encoded = encode(sut: sut, tag: item)
            seenIds.insert(encoded.id)
        }
        #expect(seenIds.count == 100)
    }

    @Test
    func encode_name() {
        let name = "my tag name"
        let sut = makeSUT()
        let item = makeWritableVaultItemTag(name: name)

        let encoded = encode(sut: sut, tag: item)

        #expect(encoded.title == name)
    }

    @Test
    func encode_colorWithValues() {
        let sut = makeSUT()
        let color = VaultItemColor(red: 0.5, green: 0.6, blue: 0.7)
        let item = makeWritableVaultItemTag(color: color)

        let encoded = encode(sut: sut, tag: item)

        #expect(encoded.color?.red == 0.5)
        #expect(encoded.color?.green == 0.6)
        #expect(encoded.color?.blue == 0.7)
    }

    @Test
    func encode_iconName() {
        let name = "my icon name"
        let sut = makeSUT()
        let item = makeWritableVaultItemTag(iconName: name)

        let encoded = encode(sut: sut, tag: item)

        #expect(encoded.iconName == name)
    }
}

// MARK: - Helpers

extension PersistedVaultTagEncoderTests {
    private func makeSUT() -> PersistedVaultTagEncoder {
        PersistedVaultTagEncoder()
    }

    private func encode(
        sut: PersistedVaultTagEncoder,
        tag: VaultItemTag.Write,
        existing: PersistedVaultTag? = nil,
    ) -> PersistedVaultTag {
        let tag = sut.encode(tag: tag, existing: existing)
        context.insert(tag)
        return tag
    }

    private func makeWritableVaultItemTag(
        name: String = "Any",
        color: VaultItemColor = .tagDefault,
        iconName: String = VaultItemTag.defaultIconName,
    ) -> VaultItemTag.Write {
        .init(
            name: name,
            color: color,
            iconName: iconName,
        )
    }

    private func makePersistedTag(
        id: UUID = UUID(),
        title: String = "Any",
        color: PersistedColor? = nil,
        iconName: String? = nil,
    ) -> PersistedVaultTag {
        let tag = PersistedVaultTag(id: id, title: title, color: color, iconName: iconName, items: [])
        context.insert(tag)
        return tag
    }
}
