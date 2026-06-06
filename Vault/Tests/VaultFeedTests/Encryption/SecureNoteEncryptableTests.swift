import Foundation
import TestHelpers
import Testing
@testable import VaultFeed

@MainActor
struct SecureNoteEncryptableTests {
    @Test
    func init_fromEncryptedContainer() {
        let container = SecureNote.EncryptedContainer(
            title: "This is a test",
            contents: "Test contents",
            format: .markdown,
        )
        let note = SecureNote(encryptedContainer: container)

        #expect(note.title == container.title)
        #expect(note.contents == container.contents)
        #expect(note.format == container.format.toTextFormat())
    }

    @Test
    func encryptedContainer_encodedFormat() throws {
        let note = SecureNote(title: "Hello world", contents: "This is my contents", format: .markdown)

        let container = try note.makeEncryptedContainer()
        let encodedContainer = try testEncoder().encode(container)

        let string = try #require(String(data: encodedContainer, encoding: .utf8))
        assertSnapshot(of: string, as: .lines)
    }
}

// MARK: - Helpers

extension SecureNoteEncryptableTests {
    /// Encodes into a test format, actual prod encoding may differ.
    private func testEncoder() -> JSONEncoder {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        encoder.dataEncodingStrategy = .base64
        encoder.dateEncodingStrategy = .millisecondsSince1970
        encoder.outputFormatting = [.sortedKeys, .prettyPrinted]
        return encoder
    }
}
