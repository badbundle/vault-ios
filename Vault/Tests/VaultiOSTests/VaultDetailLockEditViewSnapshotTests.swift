import Foundation
import SwiftUI
import TestHelpers
import Testing
@testable import VaultiOS

@MainActor
struct VaultDetailLockEditViewSnapshotTests {
    @Test
    func layout_locked() {
        let sut = VaultDetailLockEditView(
            title: "My title",
            description: "My description",
            lockState: .constant(.lockedWithNativeSecurity),
        )
        .framedForTest()

        assertSnapshot(of: sut, as: .image)
    }

    @Test
    func layout_notLocked() {
        let sut = VaultDetailLockEditView(
            title: "My title",
            description: "My description",
            lockState: .constant(.notLocked),
        )
        .framedForTest()

        assertSnapshot(of: sut, as: .image)
    }
}
