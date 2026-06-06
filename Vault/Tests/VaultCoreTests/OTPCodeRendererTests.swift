import CryptoEngine
import Foundation
import TestHelpers
import Testing
@testable import VaultCore

struct OTPCodeRendererTests {
    @Test(arguments: [
        (1, 1, "1"),
        (1234, 4, "1234"),
        (12345, 5, "12345"),
    ])
    func render_numberOfLength(code: BigUInt, digits: UInt16, expected: String) {
        let sut = OTPCodeRenderer()
        #expect(sut.render(code: code, digits: digits) == expected)
    }

    @Test(arguments: [
        (1, 6, "000001"),
        (1234, 5, "01234"),
        (1234, 6, "001234"),
    ])
    func render_padsWithLeadingZeros(code: BigUInt, digits: UInt16, expected: String) {
        let sut = OTPCodeRenderer()
        #expect(sut.render(code: code, digits: digits) == expected)
    }

    @Test(arguments: [
        (1, 0, ""),
        (1234, 0, ""),
        (1234, 1, "4"),
        (1234, 2, "34"),
        (1234, 3, "234"),
    ])
    func render_codeTooLongTruncatesToSuffix(code: BigUInt, digits: UInt16, expected: String) {
        let sut = OTPCodeRenderer()
        #expect(sut.render(code: code, digits: digits) == expected)
    }
}
