import Combine
import CryptoEngine
import Foundation
import Testing
@testable import VaultFeed

@MainActor
struct HOTPCodePublisherTests {
    @Test
    func renderedCodePublisher_doesNotPublishesInitialCodeImmediately() async throws {
        let sut = makeSUT(digits: 8)

        try await sut.renderedCodePublisher().expect(valueCount: 0) {
            // noop
        }
    }

    @Test
    func renderedCodePublisher_publishesCodesOnCounterChangeOnly() async throws {
        let sut = makeSUT(digits: 8)

        let expected = ["94287082", "37359152"]
        try await sut.renderedCodePublisher().expect(firstValues: expected) { @MainActor in
            sut.set(counter: 1)
            sut.set(counter: 2)
        }
    }

    @Test
    func renderedCodePublisher_publishesZeroLengthCode() async throws {
        let sut = makeSUT(digits: 0)

        let expected = ["", ""]
        try await sut.renderedCodePublisher().expect(firstValues: expected) { @MainActor in
            sut.set(counter: 1)
            sut.set(counter: 2)
        }
    }

    @Test
    func renderedCodePublisher_publishesCodesWithLeadingZeros() async throws {
        let sut = makeSUT(digits: 20)

        let expected = ["00000000001094287082", "00000000000137359152"]
        try await sut.renderedCodePublisher().expect(firstValues: expected) { @MainActor in
            sut.set(counter: 1)
            sut.set(counter: 2)
        }
    }

    // MARK: - Helpers

    private func makeSUT(digits: UInt16) -> HOTPCodePublisher {
        HOTPCodePublisher(hotpGenerator: fixedGenerator(digits: digits))
    }

    private func fixedGenerator(digits: UInt16) -> HOTPGenerator {
        HOTPGenerator(secret: hotpRfcSecretData(), digits: digits, algorithm: .sha1)
    }
}
