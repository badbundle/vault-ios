import Combine
import CryptoEngine
import Foundation
import TestHelpers
import Testing
import VaultCore
@testable import VaultFeed

@MainActor
struct TOTPCodePublisherTests {
    @Test
    func renderedCodePublisher_publishesCodesOnEpochSecondsTick() async throws {
        let (timer, sut) = makeSUT(digits: 8)

        let expected = [
            "07081804",
            "14050471",
            "69279037",
        ]
        try await sut.renderedCodePublisher().expect(firstValues: expected) { @MainActor in
            timer.timerUpdatedPublisherSubject.send(OTPCodeTimerState(
                startTime: 1_111_111_109,
                endTime: 1_111_111_109 + 1,
            ))
            timer.timerUpdatedPublisherSubject.send(OTPCodeTimerState(
                startTime: 1_111_111_111,
                endTime: 1_111_111_111 + 1,
            ))
            timer.timerUpdatedPublisherSubject.send(OTPCodeTimerState(
                startTime: 2_000_000_000,
                endTime: 2_000_000_000 + 1,
            ))
        }
    }

    @Test
    func renderedCodePublisher_rendersZeroLengthCodes() async throws {
        let (timer, sut) = makeSUT(digits: 0)

        let expected = ["", ""]
        try await sut.renderedCodePublisher().expect(firstValues: expected) { @MainActor in
            timer.timerUpdatedPublisherSubject.send(OTPCodeTimerState(
                startTime: 1_111_111_109,
                endTime: 1_111_111_109 + 1,
            ))
            timer.timerUpdatedPublisherSubject.send(OTPCodeTimerState(
                startTime: 1_111_111_111,
                endTime: 1_111_111_111 + 1,
            ))
        }
    }

    @Test
    func renderedCodePublisher_rendersCodesWithLeadingZeros() async throws {
        let (timer, sut) = makeSUT(digits: 20)

        let expected = [
            "00000000000907081804",
            "00000000000414050471",
        ]
        try await sut.renderedCodePublisher().expect(firstValues: expected) { @MainActor in
            timer.timerUpdatedPublisherSubject.send(OTPCodeTimerState(
                startTime: 1_111_111_109,
                endTime: 1_111_111_109 + 1,
            ))
            timer.timerUpdatedPublisherSubject.send(OTPCodeTimerState(
                startTime: 1_111_111_111,
                endTime: 1_111_111_111 + 1,
            ))
        }
    }

    // MARK: - Helpers

    private func makeSUT(digits: UInt16) -> (OTPCodeTimerUpdaterMock, some OTPCodePublisher) {
        let timer = OTPCodeTimerUpdaterMock()
        let sut = TOTPCodePublisher(timer: timer, totpGenerator: fixedGenerator(timeInterval: 30, digits: digits))
        return (timer, sut)
    }

    private func fixedGenerator(timeInterval: UInt64, digits: UInt16) -> TOTPGenerator {
        let hotpGenerator = HOTPGenerator(secret: hotpRfcSecretData(), digits: digits, algorithm: .sha1)
        return TOTPGenerator(generator: hotpGenerator, timeInterval: timeInterval)
    }
}
