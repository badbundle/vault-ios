import Foundation
import FoundationExtensions
internal import CryptoSwift

public struct PBKDF2KeyDeriver< let bytes: Int>: KeyDeriver {
    public let parameters: Parameters

    public init(parameters: Parameters) {
        self.parameters = parameters
    }

    public func key(password: Data, salt: Data) throws -> KeyData<bytes> {
        let engine = try PKCS5.PBKDF2(
            password: password.byteArray,
            salt: salt.byteArray,
            iterations: parameters.iterations,
            keyLength: bytes,
            variant: parameters.variant.hmacVariant,
        )
        let data = try Data(engine.calculate())
        return try KeyData(data: data)
    }

    public var uniqueAlgorithmIdentifier: String {
        let parameters = [
            "keyLength=\(bytes)",
            "iterations=\(parameters.iterations)",
            "variant=\(parameters.variant)",
        ]
        let parametersDescription = parameters.joined(separator: ";")
        return "PBKDF2<\(parametersDescription)>"
    }
}

// MARK: - Parameters

extension PBKDF2KeyDeriver {
    public struct Parameters: Sendable {
        public enum Variant: Equatable, Sendable {
            case sha384
        }

        public var iterations: Int
        public var variant: Variant

        public init(iterations: Int, variant: Variant) {
            self.iterations = iterations
            self.variant = variant
        }
    }
}

extension PBKDF2KeyDeriver.Parameters.Variant {
    fileprivate var hmacVariant: HMAC.Variant {
        switch self {
        case .sha384: .sha2(.sha384)
        }
    }
}
