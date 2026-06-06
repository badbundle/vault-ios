import Foundation
import SwiftUI
import TestHelpers
import Testing
import VaultFeed
@testable import VaultiOS

@MainActor
final class HOTPCodePreviewViewSnapshotTests {
    @Test
    func layout_codeVisible() {
        let sut = makeSUT(state: .visible("123456"))

        assertSnapshot(of: sut, as: .image)
    }

    @Test
    func layout_codeError() {
        let error = PresentationError(userTitle: "userTitle", debugDescription: "debugDescription")
        let sut = makeSUT(state: .error(error, digits: 6))

        assertSnapshot(of: sut, as: .image)
    }

    @Test
    func layout_codeNotReady() {
        let sut = makeSUT(state: .notReady)

        assertSnapshot(of: sut, as: .image)
    }

    @Test
    func layout_noMoreCodes() {
        let sut = makeSUT(state: .finished)

        assertSnapshot(of: sut, as: .image)
    }

    @Test
    func layout_obfuscateWithoutMessage() {
        let sut = makeSUT(state: .visible("123456"), behaviour: .editingState(message: nil))

        assertSnapshot(of: sut, as: .image)
    }

    @Test
    func layout_obfuscateWithMessage() {
        let sut = makeSUT(state: .visible("123456"), behaviour: .editingState(message: "Custom message"))

        assertSnapshot(of: sut, as: .image)
    }

    @Test
    func layout_obfuscateWithLongMessage() {
        let sut = makeSUT(state: .visible("123456"), behaviour: .editingState(message: longMessage()))

        assertSnapshot(of: sut, as: .image)
    }

    @Test
    func textWrapping_longCodeMaintainsSameSizeForAllDigits() {
        let digits = [6, 7, 8, 20]
        for count in digits {
            let code = String(Array(repeating: Character("0"), count: count))
            let sut = makeSUT(state: .visible(code))

            assertSnapshot(of: sut, as: .image, named: "\(count)-digits")
        }
    }

    @Test
    func textWrapping_longIssuerStaysOnTwoLines() {
        let sut = makeSUT(issuer: longMessage())

        assertSnapshot(of: sut, as: .image)
    }

    @Test
    func textWrapping_longAccountNameStaysOnTwoLines() {
        let sut = makeSUT(accountName: longMessage())

        assertSnapshot(of: sut, as: .image)
    }

    // MARK: - Helpers

    private func makeSUT(
        accountName: String = "Test",
        issuer: String = "Issuer",
        state: OTPCodeState = .visible("123456"),
        behaviour: VaultItemViewBehaviour = .normal,
    ) -> some View {
        let preview = OTPCodePreviewViewModel(
            accountName: accountName,
            issuer: issuer,
            color: .default,
            isLocked: false,
            fixedCodeState: state,
        )
        return HOTPCodePreviewView(
            buttonView: OTPCodeButtonIcon(isError: false),
            previewViewModel: preview,
            behaviour: behaviour,
        )
        .frame(width: 250)
    }

    private func longMessage() -> String {
        """
        This is a very long string which should be long because it is so long \
        This is a very long string which should be long because it is so long \
        This is a very long string which should be long because it is so long
        """
    }
}
