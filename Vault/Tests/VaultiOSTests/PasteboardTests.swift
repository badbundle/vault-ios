import Combine
import Foundation
import FoundationExtensions
import Testing
import VaultCore
import VaultFeed
import VaultSettings
@testable import VaultiOS

@MainActor
final class PasteboardTests {
    @Test
    func init_hasNoSideEffects() async {
        let pasteboard = SystemPasteboardMock()

        await confirmation(expectedCount: 0) { confirm in
            pasteboard.copyHandler = { _, _, _ in
                confirm()
            }

            _ = makeSUT(pasteboard: pasteboard)
        }
    }

    @Test
    func copy_copiesToPasteboard() async {
        let pasteboard = SystemPasteboardMock()
        let sut = makeSUT(pasteboard: pasteboard)
        let action = VaultTextCopyAction(
            text: "hello world, this is my string",
            requiresAuthenticationToCopy: false,
            contentType: .otp,
        )

        await confirmation { confirm in
            pasteboard.copyHandler = { copiedString, _, _ in
                #expect(copiedString == action.text)
                confirm()
            }

            sut.copy(action)
        }
    }

    @Test
    func copy_emitsDidPasteEvent() async throws {
        let sut = makeSUT()
        let action = anyAction()

        try await sut.didPaste().expect(valueCount: 3) {
            sut.copy(action)
            sut.copy(action)
            sut.copy(action)
        }
    }

    @Test
    func copy_usesTTLFromSettings() async throws {
        let ttl = PasteTTL(duration: 1234)
        let pasteboard = SystemPasteboardMock()
        let defaults = try makeDefaults()
        let settings = LocalSettings(defaults: defaults)
        let sut = makeSUT(pasteboard: pasteboard, localSettings: settings)

        settings.state.pasteTimeToLive = ttl

        await confirmation { confirm in
            pasteboard.copyHandler = { _, actualTTL, _ in
                #expect(actualTTL == ttl.duration)
                confirm()
            }

            sut.copy(anyAction())
        }
    }

    @Test
    func copy_isLocalOnlyWhenUniversalClipboardDisabledForType() async throws {
        let pasteboard = SystemPasteboardMock()
        let defaults = try makeDefaults()
        let settings = LocalSettings(defaults: defaults)
        settings.state.allowUniversalClipboardForOTPs = false
        let sut = makeSUT(pasteboard: pasteboard, localSettings: settings)

        await confirmation { confirm in
            pasteboard.copyHandler = { _, _, localOnly in
                #expect(localOnly == true)
                confirm()
            }

            sut.copy(anyAction(contentType: .otp))
        }
    }

    @Test
    func copy_isNotLocalOnlyWhenUniversalClipboardEnabledForType() async throws {
        let pasteboard = SystemPasteboardMock()
        let defaults = try makeDefaults()
        let settings = LocalSettings(defaults: defaults)
        settings.state.allowUniversalClipboardForOTPs = true
        let sut = makeSUT(pasteboard: pasteboard, localSettings: settings)

        await confirmation { confirm in
            pasteboard.copyHandler = { _, _, localOnly in
                #expect(localOnly == false)
                confirm()
            }

            sut.copy(anyAction(contentType: .otp))
        }
    }

    @Test
    func copy_universalClipboardPolicyIsPerType() throws {
        let pasteboard = SystemPasteboardMock()
        let defaults = try makeDefaults()
        let settings = LocalSettings(defaults: defaults)
        settings.state.allowUniversalClipboardForOTPs = true
        settings.state.allowUniversalClipboardForPasswords = false
        let sut = makeSUT(pasteboard: pasteboard, localSettings: settings)

        var observed: [(PasteboardContentType, Bool)] = []
        pasteboard.copyHandler = { _, _, localOnly in
            // record only; assertions after
            observed.append((.otp, localOnly))
        }
        sut.copy(anyAction(contentType: .otp))

        pasteboard.copyHandler = { _, _, localOnly in
            observed.append((.password, localOnly))
        }
        sut.copy(anyAction(contentType: .password))

        #expect(observed.count == 2)
        #expect(observed[0] == (.otp, false))
        #expect(observed[1] == (.password, true))
    }
}

// MARK: - Helpers

extension PasteboardTests {
    private func makeSUT(
        pasteboard: SystemPasteboardMock = SystemPasteboardMock(),
        localSettings: LocalSettings = LocalSettings(defaults: .init(userDefaults: .standard)),
        file _: StaticString = #filePath,
        line _: UInt = #line,
    ) -> Pasteboard {
        Pasteboard(pasteboard, localSettings: localSettings)
    }

    private func makeDefaults() throws -> Defaults {
        let userDefaults = try #require(UserDefaults(suiteName: #file))
        userDefaults.removePersistentDomain(forName: #file)
        return Defaults(userDefaults: userDefaults)
    }

    private func anyAction(
        text: String = "any",
        contentType: PasteboardContentType = .otp,
    ) -> VaultTextCopyAction {
        VaultTextCopyAction(text: text, requiresAuthenticationToCopy: false, contentType: contentType)
    }
}
