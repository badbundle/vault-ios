import Foundation
import FoundationExtensions
import TestHelpers
import Testing
@testable import CryptoEngine

struct HKDFKeyDeriverTests {
    @Test
    func key_doesNotThrowForValidParameters() {
        let sut = HKDFKeyDeriver<8>(parameters: .fastForTesting)

        #expect(throws: Never.self) {
            try sut.key(password: anyData(), salt: anyData())
        }
    }

    @Test
    func key_doesNotThrowIfNotMissingSalt() {
        let sut = HKDFKeyDeriver<8>(parameters: .fastForTesting)

        #expect(throws: Never.self, performing: {
            try sut.key(password: anyData(), salt: emptyData())
        })
    }

    @Test
    func key_generatesValidKeyWithSalt() async throws {
        // https://gchq.github.io/CyberChef/#recipe=Derive_HKDF_key(%7B'option':'Hex','string':'ABCDEF'%7D,%7B'option':'Hex','string':''%7D,'SHA256','with%20salt',8)&input=aGVsbG8gd29ybGQ
        let password = Data(byteString: "hello world")
        let salt = Data(hex: "ABCDEF")
        let sut = HKDFKeyDeriver<8>(parameters: .fastForTesting)

        let key = try sut.key(password: password, salt: salt)
        #expect(key.data.toHexString() == "e8fd40d5582c09ee")
    }

    @Test
    func uniqueAlgorithmIdentifier_matchesParameters() {
        let sut = HKDFKeyDeriver<32>(parameters: .init(
            variant: .sha3_sha512,
        ))

        #expect(sut.uniqueAlgorithmIdentifier == "HKDF<keyLength=32;variant=sha3_sha512>")
    }
}

extension HKDFKeyDeriver.Parameters {
    static var fastForTesting: Self {
        .init(variant: .sha256)
    }
}
