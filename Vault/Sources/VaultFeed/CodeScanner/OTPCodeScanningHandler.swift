import Foundation
import VaultCore

/// Handles the scanning of OTP codes from a single QR code.
public final class OTPCodeScanningHandler: CodeScanningHandler {
    public init() {}

    public func decode(data: String) -> CodeScanningResult<OTPAuthCode> {
        do {
            guard let uri = OTPAuthURI(string: data) else {
                throw URLError(.badURL)
            }
            let code = try OTPAuthURIDecoder().decode(uri: uri)
            return .endScanning(.dataRetrieved(code))
        } catch {
            return .continueScanning(.invalidCode)
        }
    }

    public var hasPartialState: Bool {
        false
    }

    public func makeSimulatedHandler() -> some SimulatedCodeScanningHandler<OTPAuthCode> {
        SimulatedOTPCodeScanningHandler()
    }
}

final class SimulatedOTPCodeScanningHandler: SimulatedCodeScanningHandler {
    init() {}

    func decodeSimulated() -> CodeScanningResult<OTPAuthCode> {
        do {
            let demoCode = try makeDemoCode()
            return .endScanning(.dataRetrieved(demoCode))
        } catch {
            return .endScanning(.unrecoverableError)
        }
    }

    private func makeDemoCode() throws -> OTPAuthCode {
        try OTPAuthCode(
            type: .totp(period: 30),
            data: .init(secret: .base32EncodedString("AA"), accountName: "Test Account", issuer: "Test Issuer"),
        )
    }
}
