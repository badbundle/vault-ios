import Foundation
import SwiftUI
import TestHelpers
import Testing
@testable import VaultiOS

@MainActor
struct VaultDetailKillphraseEditViewSnapshotTests {
    @Test
    func layout_notEnabled() {
        let sut = VaultDetailKillphraseEditView(
            title: "This is my title",
            description: "This is my description",
            hiddenWithKillphraseTitle: "This is hidden with passphrase",
            killphraseEnabled: .constant(false),
            newKillphrase: .constant(""),
        )
        .framedForTest()

        assertSnapshot(of: sut, as: .image)
    }

    @Test
    func layout_enabled() {
        let sut = VaultDetailKillphraseEditView(
            title: "This is my title",
            description: "This is my description",
            hiddenWithKillphraseTitle: "This is hidden with passphrase",
            killphraseEnabled: .constant(true),
            newKillphrase: .constant("this is kill"),
        )
        .framedForTest()

        assertSnapshot(of: sut, as: .image)
    }
}
