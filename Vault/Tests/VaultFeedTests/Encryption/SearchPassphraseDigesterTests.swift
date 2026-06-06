import CryptoKit
import Foundation
import FoundationExtensions
import Testing
@testable import VaultFeed

struct SearchPassphraseDigesterTests {
    @Test
    func makeDigest_generatesSixteenByteSalt() {
        let sut = makeSUT()

        let digest = sut.makeDigest(phrase: "hello")

        #expect(digest.salt.count == SearchPassphraseDigester.saltLength)
    }

    @Test
    func makeDigest_generatesThirtyTwoByteDigest() {
        let sut = makeSUT()

        let digest = sut.makeDigest(phrase: "hello")

        #expect(digest.digest.count == 32)
    }

    @Test
    func makeDigest_usesDistinctSaltsAcrossCalls() {
        let sut = makeSUT()

        let first = sut.makeDigest(phrase: "hello")
        let second = sut.makeDigest(phrase: "hello")

        #expect(first.salt != second.salt)
        #expect(first.digest != second.digest)
    }

    @Test
    func matches_returnsTrueForCorrectPhrase() {
        let sut = makeSUT()
        let digest = sut.makeDigest(phrase: "correct horse battery staple")

        #expect(sut.matches(query: "correct horse battery staple", salt: digest.salt, digest: digest.digest))
    }

    @Test
    func matches_returnsFalseForWrongPhrase() {
        let sut = makeSUT()
        let digest = sut.makeDigest(phrase: "correct horse battery staple")

        #expect(sut.matches(query: "wrong", salt: digest.salt, digest: digest.digest) == false)
    }

    @Test
    func matches_returnsFalseForWrongSalt() {
        let sut = makeSUT()
        let digest = sut.makeDigest(phrase: "hello")
        let otherSalt = Data(repeating: 0xFF, count: SearchPassphraseDigester.saltLength)

        #expect(sut.matches(query: "hello", salt: otherSalt, digest: digest.digest) == false)
    }

    @Test
    func matches_returnsFalseForDifferentKey() throws {
        let phrase = "secret"
        let keyA = try KeyData<32>(data: Data(repeating: 0x01, count: 32))
        let keyB = try KeyData<32>(data: Data(repeating: 0x02, count: 32))
        let digesterA = SearchPassphraseDigester(key: keyA)
        let digesterB = SearchPassphraseDigester(key: keyB)
        let digest = digesterA.makeDigest(phrase: phrase)

        #expect(digesterB.matches(query: phrase, salt: digest.salt, digest: digest.digest) == false)
        #expect(digesterA.matches(query: phrase, salt: digest.salt, digest: digest.digest))
    }

    @Test
    func matches_isCaseInsensitive() {
        let sut = makeSUT()
        let digest = sut.makeDigest(phrase: "Hello")

        #expect(sut.matches(query: "hello", salt: digest.salt, digest: digest.digest))
        #expect(sut.matches(query: "HELLO", salt: digest.salt, digest: digest.digest))
        #expect(sut.matches(query: "hElLo", salt: digest.salt, digest: digest.digest))
    }

    @Test
    func matches_handlesUnicodeNormalizationVariants() {
        let sut = makeSUT()
        // "café" composed (NFC: U+00E9) vs decomposed (NFD: e + U+0301).
        // The digester normalises both sides, so these must match.
        let composed = "caf\u{00E9}"
        let decomposed = "cafe\u{0301}"
        let digest = sut.makeDigest(phrase: composed)

        #expect(sut.matches(query: decomposed, salt: digest.salt, digest: digest.digest))
        #expect(sut.matches(query: decomposed.uppercased(), salt: digest.salt, digest: digest.digest))
    }

    @Test
    func matches_returnsFalseForEmptyQuery() {
        let sut = makeSUT()
        let digest = sut.makeDigest(phrase: "hello")

        #expect(sut.matches(query: "", salt: digest.salt, digest: digest.digest) == false)
    }
}

extension SearchPassphraseDigesterTests {
    private func makeSUT() -> SearchPassphraseDigester {
        SearchPassphraseDigester(key: testKey())
    }

    private func testKey() -> KeyData<32> {
        (try? KeyData<32>(data: Data(repeating: 0xBB, count: 32))) ?? .zero()
    }
}
