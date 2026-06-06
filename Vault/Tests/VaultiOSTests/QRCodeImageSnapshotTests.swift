import Foundation
import TestHelpers
import Testing
@testable import VaultiOS

@MainActor
struct QRCodeImageSnapshotTests {
    @Test
    func image_rendersCode() {
        let sut = QRCodeImage(data: Data(repeating: 0x32, count: 100))
            .frame(width: 100, height: 100)

        assertSnapshot(of: sut, as: .image)
    }
}
