import Foundation
import TestHelpers
import Testing
@testable import VaultiOS

@MainActor
struct VaultAboutViewSnapshotTests {
    @Test
    func layout() {
        let sut = VaultAboutView(
            viewModel: .init(),
            appVersionText: "Version 2.0 (Build 100001)",
        )
        .framedForTest(height: 1200)

        assertSnapshot(of: sut, as: .image)
    }
}
