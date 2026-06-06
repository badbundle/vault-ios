import Foundation

/// Encodes according to the spec for *otpauth*.
///
/// https://docs.yubico.com/yesdk/users-manual/application-oath/uri-string-format.html
public struct OTPAuthURIEncoder {
    public enum URIEncodingError: Error {
        case badURIComponents
    }

    public init() {}

    public func encode(code: OTPAuthCode) throws(URIEncodingError) -> OTPAuthURI {
        var components = URLComponents()
        components.scheme = OTPAuthURI.otpAuthScheme
        components.host = makeFormatted(type: code.type)
        components.path = makePath(code: code)
        components.queryItems = makeQueryParameters(code: code)
        guard let url = components.url else {
            throw URIEncodingError.badURIComponents
        }
        return url
    }
}

// MARK: - Helpers

extension OTPAuthURIEncoder {
    private func makePath(code: OTPAuthCode) -> String {
        "/" + makeFormattedLabel(code: code)
    }

    private func makeQueryParameters(code: OTPAuthCode) -> [URLQueryItem] {
        var queryItems = [URLQueryItem]()
        queryItems.append(
            .otpAuth(.secret, value: makeFormatted(secret: code.data.secret)),
        )
        queryItems.append(
            .otpAuth(.algorithm, value: formatted(algorithm: code.data.algorithm)),
        )
        queryItems.append(
            .otpAuth(.digits, value: "\(code.data.digits.value)"),
        )
        if code.data.issuer.isNotEmpty {
            queryItems.append(
                .otpAuth(.issuer, value: code.data.issuer),
            )
        }
        switch code.type {
        case let .totp(period):
            queryItems.append(
                .otpAuth(.period, value: "\(period)"),
            )
        case let .hotp(counter):
            queryItems.append(
                .otpAuth(.counter, value: "\(counter)"),
            )
        }
        return queryItems
    }

    private func makeFormatted(secret: OTPAuthSecret) -> String {
        base32Encode(secret.data)
    }

    private func makeFormattedLabel(code: OTPAuthCode) -> String {
        if code.data.issuer.isNotEmpty {
            "\(code.data.issuer):\(code.data.accountName)"
        } else {
            code.data.accountName
        }
    }

    private func makeFormatted(type: OTPAuthType) -> String {
        switch type {
        case .totp:
            "totp"
        case .hotp:
            "hotp"
        }
    }

    private func formatted(algorithm: OTPAuthAlgorithm) -> String {
        switch algorithm {
        case .sha1:
            "SHA1"
        case .sha256:
            "SHA256"
        case .sha512:
            "SHA512"
        }
    }
}

extension URLQueryItem {
    static func otpAuth(_ parameter: OTPAuthURI.Parameter, value: String) -> URLQueryItem {
        URLQueryItem(name: parameter.rawValue, value: value)
    }
}
