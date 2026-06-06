import Combine
import Foundation
import TestHelpers
import Testing
import VaultCore
import VaultFeed

@MainActor
struct OTPCodeIncrementerViewModelTests {
    @Test @LeakTracked
    func isButtonEnabled_isInitiallyTrue() {
        let sut = makeSUT()

        #expect(sut.isButtonEnabled)
    }

    @Test @LeakTracked
    func isButtonEnabled_becomesDisabledAfterIncrementing() async throws {
        let sut = makeSUT()

        try await sut.incrementCounter()

        #expect(sut.isButtonEnabled == false)
    }

    @Test @LeakTracked
    func isButtonEnabled_hasNoEffectIncrementingCounterMoreThanOnce() async throws {
        let sut = makeSUT()

        try await sut.incrementCounter()
        try await sut.incrementCounter()

        #expect(sut.isButtonEnabled == false)
    }

    @Test @LeakTracked
    func isButtonEnabled_enablesAfterTimerCompletion() async throws {
        let timer = IntervalTimerMock()
        let sut = makeSUT(timer: timer)

        try await sut.incrementCounter()
        #expect(sut.isButtonEnabled == false)

        try await timer.finishTimer()
        #expect(sut.isButtonEnabled == true)
    }

    @Test @LeakTracked
    func incrementCounter_incrementsCounterWhileButtonEnabled() async throws {
        let codePublisher = HOTPCodePublisher(hotpGenerator: .init(secret: Data()))
        let sut = makeSUT(codePublisher: codePublisher)

        try await codePublisher.counterIncrementedPublisher().expect(valueCount: 1) {
            try await sut.incrementCounter()
        }
    }

    @Test @LeakTracked
    func incrementCounter_doesNotIncrementCounterWhileButtonDisabled() async throws {
        let codePublisher = HOTPCodePublisher(hotpGenerator: .init(secret: Data()))
        let sut = makeSUT(codePublisher: codePublisher)

        try await sut.incrementCounter() // disable button

        try await codePublisher.counterIncrementedPublisher()
            .dropFirst() // the renderer publishes the first value right away, so ignore that
            .expect(valueCount: 0) {
                try? await sut.incrementCounter()
            }
    }

    @Test @LeakTracked
    func incrementCounter_incrementsStore() async throws {
        let incrementerStore = VaultStoreHOTPIncrementerMock()
        let sut = makeSUT(incrementerStore: incrementerStore)

        try await confirmation { confirmation in
            incrementerStore.incrementCounterHandler = { _ in
                confirmation.confirm()
            }
            try await sut.incrementCounter()
        }
    }

    @Test @LeakTracked
    func incrementCounter_doesNotTriggerPublishIfIncrementFailed() async throws {
        let codePublisher = HOTPCodePublisher(hotpGenerator: .init(secret: Data()))
        let incrementerStore = VaultStoreHOTPIncrementerMock()
        let sut = makeSUT(codePublisher: codePublisher, incrementerStore: incrementerStore)

        incrementerStore.incrementCounterHandler = { _ in
            throw TestError()
        }

        try await codePublisher.counterIncrementedPublisher()
            .dropFirst() // the renderer publishes the first value right away, so ignore that
            .expect(valueCount: 0) {
                try? await sut.incrementCounter()
            }
    }

    // MARK: - Helpers

    private func makeSUT(
        codePublisher: HOTPCodePublisher = HOTPCodePublisher(hotpGenerator: .init(secret: Data())),
        timer: IntervalTimerMock = IntervalTimerMock(),
        incrementerStore: VaultStoreHOTPIncrementerMock = VaultStoreHOTPIncrementerMock(),
    ) -> OTPCodeIncrementerViewModel {
        trackForMemoryLeaks(codePublisher)
        trackForMemoryLeaks(timer)
        trackForMemoryLeaks(incrementerStore)
        return trackForMemoryLeaks(OTPCodeIncrementerViewModel(
            id: .new(),
            codePublisher: codePublisher,
            timer: timer,
            initialCounter: 0,
            incrementerStore: incrementerStore,
        ))
    }
}

extension HOTPCodePublisher {
    @MainActor
    func counterIncrementedPublisher() -> AnyPublisher<Void, any Error> {
        renderedCodePublisher().map { _ in }.eraseToAnyPublisher()
    }
}
