import Foundation
import FoundationExtensions
import TestHelpers
import Testing
@testable import CryptoEngine

struct PBKDF2KeyDeriverTests {
    @Test
    func key_doesNotThrowForValidParameters() async {
        let sut = PBKDF2KeyDeriver<8>(parameters: .fastForTesting)

        #expect(throws: Never.self) {
            try sut.key(password: anyData(), salt: anyData())
        }
    }

    @Test
    func key_throwsIfMissingSalt() async {
        let sut = PBKDF2KeyDeriver<8>(parameters: .fastForTesting)

        #expect(throws: (any Error).self) {
            try sut.key(password: anyData(), salt: emptyData())
        }
    }

    @Test
    func key_generatesValidKeyWithSalt() async throws {
        let password = Data(byteString: "hello world")
        let salt = Data(hex: "ABCDEF")
        let sut = PBKDF2KeyDeriver<8>(parameters: .fastForTesting)

        let key = try sut.key(password: password, salt: salt)
        #expect(key.data.toHexString() == "98daafce2dc5444d")
    }

    @Test
    func key_generatesTheSameKeyMultipleTimes() async throws {
        let password = Data(byteString: "hello world")
        let salt = Data(hex: "ABCDEF")
        let sut = PBKDF2KeyDeriver<8>(parameters: .fastForTesting)

        let expected = try KeyData<8>(data: Data(hex: "98daafce2dc5444d"))
        let keys = try [
            sut.key(password: password, salt: salt),
            sut.key(password: password, salt: salt),
            sut.key(password: password, salt: salt),
        ]
        #expect(keys == [expected, expected, expected])
    }

    @Test
    func uniqueAlgorithmIdentifier_matchesParameters() {
        let sut = PBKDF2KeyDeriver<8>(parameters: .init(
            iterations: 456,
            variant: .sha384,
        ))

        #expect(sut.uniqueAlgorithmIdentifier == "PBKDF2<keyLength=8;iterations=456;variant=sha384>")
    }
}

extension PBKDF2KeyDeriver.Parameters {
    static var fastForTesting: Self {
        .init(iterations: 100, variant: .sha384)
    }
}
