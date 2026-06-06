import Foundation
import Testing
import VaultCore
@testable import VaultFeed

struct VaultItemDemoFactoryTests {
    @Test
    func makeTOTPCode_returnsDemoOTPItem() {
        let sut = VaultItemDemoFactory()

        let item = sut.makeTOTPCode()

        assertCommonDemoMetadata(item, userDescription: "This is a demo TOTP code", showInQuickType: true)
        guard case let .otpCode(code) = item.item else {
            Issue.record("Expected OTP code")
            return
        }
        #expect(code.type == .totp(period: 30))
        #expect(code.data.issuer == "mcky.dev")
        #expect(code.data.accountName.hasPrefix("mcky.dev "))
    }

    @Test
    func makeHOTPCode_returnsDemoOTPItem() {
        let sut = VaultItemDemoFactory()

        let item = sut.makeHOTPCode()

        assertCommonDemoMetadata(item, userDescription: "This is a demo HOTP code", showInQuickType: true)
        guard case let .otpCode(code) = item.item else {
            Issue.record("Expected OTP code")
            return
        }
        #expect(code.data.issuer == "mcky.dev")
        #expect(code.data.accountName.hasPrefix("example.com "))
    }

    @Test
    func makeSecureNote_returnsDemoNoteItem() {
        let sut = VaultItemDemoFactory()

        let item = sut.makeSecureNote()

        assertCommonDemoMetadata(item, userDescription: "This is a demo note", showInQuickType: false)
        guard case let .secureNote(note) = item.item else {
            Issue.record("Expected secure note")
            return
        }
        #expect(note.title == "Hi there")
        #expect(note.contents.hasPrefix("This is a test "))
        #expect(note.format == .plain)
    }

    @Test
    func makeEncryptedSecureNote_returnsEncryptedDemoNoteItem() throws {
        let sut = VaultItemDemoFactory()

        let item = try sut.makeEncryptedSecureNote()

        assertCommonDemoMetadata(item, userDescription: "Hi there", showInQuickType: false)
        guard case let .encryptedItem(encrypted) = item.item else {
            Issue.record("Expected encrypted item")
            return
        }
        #expect(encrypted.title == "Hi there")
        #expect(encrypted.data.isEmpty == false)
        #expect(encrypted.authentication.isEmpty == false)
        #expect(encrypted.encryptionIV.isEmpty == false)
    }
}

private func assertCommonDemoMetadata(
    _ item: VaultItem.Write,
    userDescription: String,
    showInQuickType: Bool,
    sourceLocation: SourceLocation = #_sourceLocation,
) {
    #expect(item.relativeOrder == 0, sourceLocation: sourceLocation)
    #expect(item.userDescription == userDescription, sourceLocation: sourceLocation)
    #expect(item.color == nil, sourceLocation: sourceLocation)
    #expect(item.tags == [], sourceLocation: sourceLocation)
    #expect(item.visibility == .always, sourceLocation: sourceLocation)
    #expect(item.searchableLevel == .full, sourceLocation: sourceLocation)
    #expect(item.searchPassphraseUpdate == .clear, sourceLocation: sourceLocation)
    #expect(item.killphraseUpdate == .clear, sourceLocation: sourceLocation)
    #expect(item.lockState == .notLocked, sourceLocation: sourceLocation)
    #expect(item.showInQuickType == showInQuickType, sourceLocation: sourceLocation)
    #expect(item.previewMode == .titleAndFirstLine, sourceLocation: sourceLocation)
}
