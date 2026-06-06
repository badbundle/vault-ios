import Foundation
import TestHelpers
import Testing
@testable import VaultiOS

@MainActor
final class OpenSourceViewSnapshotTests {
    @Test
    func deviceSize() {
        let view = OpenSourceView()
            .framedForTest()

        assertSnapshot(of: view, as: .image)
    }
}
