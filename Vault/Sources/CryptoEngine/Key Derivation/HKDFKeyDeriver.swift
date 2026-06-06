import Foundation
import FoundationExtensions
internal import CryptoSwift

public struct HKDFKeyDeriver< let bytes: Int>: KeyDeriver {
    private let parameters: Parameters

    public init(parameters: Parameters) {
        self.parameters = parameters
    }

    public func key(password: Data, salt: Data) throws -> KeyData<bytes> {
        let engine = try HKDF(
            password: password.byteArray,
            salt: salt.byteArray,
            info: nil,
            keyLength: bytes,
            variant: parameters.variant.hmacVariant,
        )
        let data = try Data(engine.calculate())
        return try KeyData(data: data)
    }

    public var uniqueAlgorithmIdentifier: String {
        let parameters = [
            "keyLength=\(bytes)",
            "variant=\(parameters.variant)",
        ]
        let parameterDescription = parameters.joined(separator: ";")
        return "HKDF<\(parameterDescription)>"
    }
}

// MARK: - Parameters

extension HKDFKeyDeriver {
    public struct Parameters: Sendable {
        public enum Variant: Sendable {
            case sha256
            case sha3_sha512
        }

        public var variant: Variant

        public init(variant: Variant) {
            self.variant = variant
        }
    }
}

extension HKDFKeyDeriver.Parameters.Variant {
    fileprivate var hmacVariant: HMAC.Variant {
        switch self {
        case .sha256: .sha2(.sha256)
        case .sha3_sha512: .sha3(.sha512)
        }
    }
}
