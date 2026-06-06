import Foundation
import TestHelpers
import Testing
import VaultFeed

struct OTPCodeTimerAnimationStateTests {
    @Test
    func initialFraction_freezeIsFraction() {
        let sut = OTPCodeTimerAnimationState.freeze(fraction: 0.69)

        #expect(sut.initialFraction(currentTime: 0).isApproximatelyEqual(to: 0.69, absoluteTolerance: .ulpOfOne))
    }

    @Test
    func initialFraction_animateIsStartFraction() {
        let state = OTPCodeTimerState(startTime: 0, endTime: 10)
        let sut = OTPCodeTimerAnimationState.animate(state)

        #expect(sut.initialFraction(currentTime: 3).isApproximatelyEqual(to: 0.70, absoluteTolerance: .ulpOfOne))
    }

    @Test
    func countdownFromTimerState_nilCreatesFrozenAtZero() {
        let sut = OTPCodeTimerAnimationState.countdownFrom(timerState: nil)

        #expect(sut == .freeze(fraction: 0))
    }

    @Test
    func countdownFromTimerState_createsWithTimer() {
        let timer = OTPCodeTimerState(startTime: 100, endTime: 200)
        let sut = OTPCodeTimerAnimationState.countdownFrom(timerState: timer)

        #expect(sut == .animate(timer))
    }
}
