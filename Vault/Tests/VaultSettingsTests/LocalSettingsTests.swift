import Foundation
import FoundationExtensions
import TestHelpers
import Testing
import VaultSettings

@MainActor
struct LocalSettingsTests {
    @Test
    func pasteTimeToLive_defaultsToDefaultValue() throws {
        let defaults = try Defaults.nonPersistent()
        let sut = try makeSUT(defaults: defaults)

        #expect(sut.state.pasteTimeToLive == .default)
    }

    @Test
    func pasteTimeToLive_savesStateAfterStateChanged() throws {
        let defaults = try Defaults.nonPersistent()
        let sutSave = try makeSUT(defaults: defaults)
        sutSave.state.pasteTimeToLive = .init(duration: 1234)

        let sutRetrieve = try makeSUT(defaults: defaults)
        #expect(sutRetrieve.state.pasteTimeToLive == .init(duration: 1234))
    }
}

// MARK: - Helpers

extension LocalSettingsTests {
    private func makeSUT(defaults: Defaults) throws -> LocalSettings {
        LocalSettings(defaults: defaults)
    }
}

extension UserDefaults {
    private var allStoredKeys: [String] {
        dictionaryRepresentation().keys.map(\.self)
    }
}
