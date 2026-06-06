import Foundation
import TestHelpers
import Testing
import VaultCore
import VaultFeed

@MainActor
struct CodeScanningManagerTests {
    @Test
    func init_initialStateIsDisabled() {
        let sut = makeSUT()

        #expect(sut.scanningState == .disabled)
    }

    @Test
    func startScanning_setsStateToStart() {
        let sut = makeSUT()

        sut.startScanning()

        #expect(sut.scanningState == .scanning)
    }

    @Test
    func disable_setsStateToDisabled() {
        let sut = makeSUT()

        sut.startScanning()
        sut.disable()

        #expect(sut.scanningState == .disabled)
    }

    @Test
    func scan_setsStateToInvalidForInvalidCode() {
        let timer = IntervalTimerMock()
        let handler = CodeScanningHandlerMock()
        handler.decodeHandler = { _ in .continueScanning(.invalidCode) }
        handler.makeSimulatedHandlerHandler = { SimulatedCodeScanningHandlerMock() }
        let sut = makeSUT(intervalTimer: timer, handler: handler)
        sut.startScanning()

        sut.scan(text: "any")

        #expect(sut.scanningState == .failure(.temporary))
    }

    @Test
    func simulatedScan_triggersSimulatedHandler() {
        let simulatedHandler = SimulatedCodeScanningHandlerMock()
        simulatedHandler.decodeSimulatedHandler = { .continueScanning(.ignore) }
        let handler = CodeScanningHandlerMock()
        handler.makeSimulatedHandlerHandler = { simulatedHandler }
        handler.decodeHandler = { _ in .continueScanning(.ignore) }
        let sut = makeSUT(handler: handler)
        sut.startScanning()

        sut.simulatedScan()

        #expect(simulatedHandler.decodeSimulatedCallCount == 1)
        #expect(handler.decodeCallCount == 0)
    }

    @Test
    func scan_triggersNormalHandler() {
        let simulatedHandler = SimulatedCodeScanningHandlerMock()
        simulatedHandler.decodeSimulatedHandler = { .continueScanning(.ignore) }
        let handler = CodeScanningHandlerMock()
        handler.makeSimulatedHandlerHandler = { simulatedHandler }
        handler.decodeHandler = { _ in .continueScanning(.ignore) }
        let sut = makeSUT(handler: handler)
        sut.startScanning()

        sut.scan(text: "some data")

        #expect(simulatedHandler.decodeSimulatedCallCount == 0)
        #expect(handler.decodeCallCount == 1)
    }

    @Test
    func scan_returnsToScanningAfterInvalidCodeFailure() async throws {
        let timer = IntervalTimerMock()
        let handler = CodeScanningHandlerMock()
        handler.decodeHandler = { _ in .continueScanning(.invalidCode) }
        handler.makeSimulatedHandlerHandler = { SimulatedCodeScanningHandlerMock() }
        let sut = makeSUT(intervalTimer: timer, handler: handler)
        sut.startScanning()

        sut.scan(text: "any")
        try await timer.finishTimer()

        #expect(sut.scanningState == .scanning)
    }

    @Test
    func scan_successSetsStateToSuccess() {
        let timer = IntervalTimerMock()
        let handler = CodeScanningHandlerMock()
        handler.decodeHandler = { _ in .continueScanning(.success) }
        handler.makeSimulatedHandlerHandler = { SimulatedCodeScanningHandlerMock() }
        let sut = makeSUT(intervalTimer: timer, handler: handler)
        sut.startScanning()

        sut.scan(text: "any")

        #expect(sut.scanningState == .success(.temporary))
    }

    @Test
    func scan_publishesScannedCodeAfterDelayWhenCompletedScanning() async throws {
        let timer = IntervalTimerMock()
        let handler = CodeScanningHandlerMock()
        handler.decodeHandler = { _ in .endScanning(.dataRetrieved("any")) }
        handler.makeSimulatedHandlerHandler = { SimulatedCodeScanningHandlerMock() }
        let sut = makeSUT(intervalTimer: timer)
        sut.startScanning()

        sut.scan(text: "any")

        try await confirmation { confirm in
            let results = sut.itemScannedPublisher().collectFirst(1).sink { _ in
                confirm()
            }

            try await timer.finishTimer()

            withExtendedLifetime(results) {}
        }

        #expect(sut.scanningState == .success(.complete))
    }

    @Test
    func scan_unrecoverableErrorSetsStateToDataError() {
        let timer = IntervalTimerMock()
        let handler = CodeScanningHandlerMock()
        handler.decodeHandler = { _ in .endScanning(.unrecoverableError) }
        handler.makeSimulatedHandlerHandler = { SimulatedCodeScanningHandlerMock() }
        let sut = makeSUT(intervalTimer: timer, handler: handler)
        sut.startScanning()

        sut.scan(text: "any")

        #expect(sut.scanningState == .failure(.unrecoverable))
    }

    @Test
    func scan_returnsToScanningAfterDelayWhenContinueScanningReturned() async throws {
        let timer = IntervalTimerMock()
        let handler = CodeScanningHandlerMock()
        handler.decodeHandler = { _ in .continueScanning(.success) }
        handler.makeSimulatedHandlerHandler = { SimulatedCodeScanningHandlerMock() }
        let sut = makeSUT(intervalTimer: timer, handler: handler)
        sut.startScanning()

        sut.scan(text: "any")
        #expect(sut.scanningState == .success(.temporary))

        try await timer.finishTimer()
        #expect(sut.scanningState == .scanning)
    }

    @Test
    func scan_scanningStateUnchangedIfShouldIgnore() {
        let timer = IntervalTimerMock()
        let handler = CodeScanningHandlerMock()
        handler.decodeHandler = { _ in .continueScanning(.ignore) }
        handler.makeSimulatedHandlerHandler = { SimulatedCodeScanningHandlerMock() }
        let sut = makeSUT(intervalTimer: timer, handler: handler)
        sut.startScanning()

        sut.scan(text: "any")

        #expect(sut.scanningState == .scanning)
    }
}

extension CodeScanningManagerTests {
    private func makeSUT(
        intervalTimer: IntervalTimerMock = IntervalTimerMock(),
        handler: CodeScanningHandlerMock = .defaultCompletedScanning,
        sourceLocation _: SourceLocation = #_sourceLocation,
    ) -> CodeScanningManager<CodeScanningHandlerMock> {
        CodeScanningManager(intervalTimer: intervalTimer, handler: handler)
    }
}

extension CodeScanningHandlerMock {
    fileprivate static var defaultCompletedScanning: CodeScanningHandlerMock {
        let mock = CodeScanningHandlerMock()
        mock.decodeHandler = { _ in .endScanning(.dataRetrieved("any")) }
        mock.makeSimulatedHandlerHandler = { SimulatedCodeScanningHandlerMock() }
        return mock
    }
}
