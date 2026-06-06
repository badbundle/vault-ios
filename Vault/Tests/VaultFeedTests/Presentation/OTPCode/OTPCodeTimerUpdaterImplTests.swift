import Combine
import Foundation
import TestHelpers
import Testing
import VaultCore
import VaultFeed

@MainActor
struct OTPCodeTimerUpdaterImplTests {
    @Test
    func timerUpdatedPublisher_publishesInitialValueImmediately() async throws {
        let clock = EpochClockMock(currentTime: 62)
        let sut = makeSUT(clock: clock, period: 30)

        let expected = [OTPCodeTimerState(startTime: 60, endTime: 90)]
        try await sut.timerUpdatedPublisher.expect(firstValues: expected) {
            // noop
        }
    }

    @Test
    func timerUpdatedPublisher_publishesStateForCurrentTimeOnTimerFinish() async throws {
        let clock = EpochClockMock(currentTime: 32)
        let timer = IntervalTimerMock()
        let sut = makeSUT(clock: clock, timer: timer, period: 30)

        let expected = [
            OTPCodeTimerState(startTime: 30, endTime: 60), // initial time
            OTPCodeTimerState(startTime: 60, endTime: 90),
        ]
        try await sut.timerUpdatedPublisher.expect(firstValues: expected) { @MainActor in
            clock.currentTime = 62
            try await timer.finishTimer()
        }
    }

    @Test
    func recalculate_forcesPublishOfCurrentTimerState() async throws {
        let clock = EpochClockMock(currentTime: 32)
        let timer = IntervalTimerMock()
        let sut = makeSUT(clock: clock, timer: timer, period: 30)

        let expected = [
            OTPCodeTimerState(startTime: 30, endTime: 60), // initial time
            OTPCodeTimerState(startTime: 300, endTime: 330),
            OTPCodeTimerState(startTime: 330, endTime: 360),
        ]
        try await sut.timerUpdatedPublisher.expect(firstValues: expected) {
            clock.currentTime = 301
            await sut.recalculate()
            clock.currentTime = 330
            await sut.recalculate()
        }
    }

    @Test
    func recalculate_publishesDuplicateStatesIfRecalculatingInSamePeriod() async throws {
        let clock = EpochClockMock(currentTime: 32)
        let sut = makeSUT(clock: clock, period: 30)

        let expected = [
            OTPCodeTimerState(startTime: 30, endTime: 60), // initial time
            OTPCodeTimerState(startTime: 30, endTime: 60),
            OTPCodeTimerState(startTime: 30, endTime: 60),
        ]
        try await sut.timerUpdatedPublisher.expect(firstValues: expected) {
            await sut.recalculate()
            await sut.recalculate()
        }
    }

    // MARK: - Helpers

    private func makeSUT(
        clock: EpochClockMock,
        timer: IntervalTimerMock = IntervalTimerMock(),
        period: UInt64,
    ) -> OTPCodeTimerUpdaterImpl {
        OTPCodeTimerUpdaterImpl(timer: timer, period: period, clock: clock)
    }
}
