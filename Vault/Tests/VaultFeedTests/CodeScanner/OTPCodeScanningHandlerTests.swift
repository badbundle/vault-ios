import Foundation
import Testing
@testable import VaultFeed

struct OTPCodeScanningHandlerTests {
    let sut = OTPCodeScanningHandler()

    @Test
    func hasPartialState_isFalse() {
        #expect(sut.hasPartialState == false)
    }

    @Test(arguments: ["", "invalid", "invalid://totp/issuer"])
    func decode_invalidDataReturnsInvalidCode(string: String) {
        let result = sut.decode(data: string)
        #expect(result == .continueScanning(.invalidCode))
    }

    @Test
    func decode_successCompletesWithExpectedCode() {
        let result = sut.decode(data: "otpauth://totp/issuer?secret=AA&algorithm=SHA256&digits=7&period=32")

        switch result {
        case let .endScanning(.dataRetrieved(code)):
            #expect(code.data.secret.base32EncodedString == "AA======")
            #expect(code.data.algorithm == .sha256)
            #expect(code.type.kind == .totp)
            #expect(code.data.digits == .init(value: 7))
        default:
            Issue.record("Expected completedScanning, got \(result)")
        }
    }
}
