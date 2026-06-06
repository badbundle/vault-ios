import Combine
import SwiftUI
import TestHelpers
import Testing
import VaultFeed
import VaultiOSShared
@testable import VaultiOS

@MainActor
final class OTPCodeTextViewSnapshotTests {
    @Test
    func visible_defaultCode() {
        let view = makeSUT(codeState: .visible("123456"))

        assertSnapshot(of: view, as: .image)
    }

    @Test
    func visible_staysOnSingleLineForLongCode() {
        let view = makeSUT(codeState: .visible("123456123456123456"))

        assertSnapshot(of: view, as: .image)
    }

    @Test
    func error_staysOnSingleLine() {
        let view = makeSUT(codeState: .error(.init(userTitle: "err", debugDescription: "err"), digits: 20))

        assertSnapshot(of: view, as: .image)
    }

    @Test
    func obfuscated_staysOnSingleLine() {
        let view = makeSUT(codeState: .obfuscated(.expiry))

        assertSnapshot(of: view, as: .image)
    }
}

// MARK: - Helpers

extension OTPCodeTextViewSnapshotTests {
    private func makeSUT(codeState: OTPCodeState) -> some View {
        OTPCodeTextView(codeState: codeState)
            .frame(width: 100, height: 100)
    }
}
