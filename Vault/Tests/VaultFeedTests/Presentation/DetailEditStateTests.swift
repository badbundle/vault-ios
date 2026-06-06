import Foundation
import FoundationExtensions
import TestHelpers
import Testing
@testable import VaultFeed

@MainActor
struct DetailEditStateTests {
    @Test
    func init_isInitiallyNotPerformingAnyOperations() {
        let sut = makeSUT()

        #expect(!sut.isSaving)
        #expect(!sut.isInEditMode)
    }

    @Test
    func startEditing_setsModeToEditing() {
        let sut = makeSUT()

        sut.startEditing()

        #expect(sut.isInEditMode)
    }

    @Test
    func saveChanges_setsIsSavingToTrue() async throws {
        let sut = makeSUT()

        let savingStart = Pending.signal()
        let task = Task {
            try await sut.saveChanges {
                await savingStart.fulfill()
                try await suspendForever()
            }
        }

        try await savingStart.wait()

        #expect(sut.isSaving)

        task.cancel()
    }

    @Test
    func saveChanges_hasNoEffectIfCalledWhileExistingSaveInProgress() async throws {
        let sut = makeSUT()

        let savingStart1 = Pending.signal()
        let task1 = Task {
            try await sut.saveChanges {
                await savingStart1.fulfill()
                try await suspendForever()
            }
        }

        try await savingStart1.wait()

        try await confirmation(timeout: .seconds(1), expectedCount: 0) { confirmation in
            try await sut.saveChanges {
                confirmation.confirm()
            }
        }

        task1.cancel()
    }

    @Test
    func saveChanges_successSetsEditModeToFalse() async throws {
        let sut = makeSUT()
        sut.startEditing()

        try await sut.saveChanges { /* noop */ }

        #expect(!sut.isInEditMode)
    }

    @Test
    func saveChanges_failureDoesNotChangeEditMode() async {
        let sut = makeSUT()
        sut.startEditing()

        try? await sut.saveChanges { throw TestError() }

        #expect(sut.isInEditMode)
    }

    @Test
    func saveChanges_failureThrowsError() async {
        let sut = makeSUT()

        // TODO: replace with "#expect(throws: OperationError.save)" in Swift 6.1
        // https://github.com/swiftlang/swift-testing/pull/624
        do {
            try await sut.saveChanges {
                throw TestError()
            }
            Issue.record("Expected error to be thrown")
        } catch DetailEditState<MockState>.OperationError.save {
            // expected
        } catch {
            Issue.record("Unexpected error type")
        }
    }

    @Test
    func deleteItem_setsIsSavingToTrue() async throws {
        let sut = makeSUT()

        let deletingStart = Pending.signal()
        let task = Task {
            try await sut.deleteItem {
                await deletingStart.fulfill()
                try await suspendForever()
            } finished: {
                // noop
            }
        }

        try await deletingStart.wait()

        #expect(sut.isSaving)

        task.cancel()
    }

    @Test
    func deleteItem_hasNoEffectIfCalledWhileExistingSaveInProgress() async throws {
        let sut = makeSUT()

        let startDeleting1 = Pending.signal()
        let task1 = Task {
            try await sut.deleteItem {
                await startDeleting1.fulfill()
                try await suspendForever()
            } finished: {
                // noop
            }
        }

        try await startDeleting1.wait()

        try await confirmation(timeout: .seconds(1), expectedCount: 0) { confirmation in
            try await sut.deleteItem {
                confirmation.confirm()
            } finished: {
                confirmation.confirm()
            }
        }

        task1.cancel()
    }

    @Test
    func deleteItem_successCallsFinished() async throws {
        let sut = makeSUT()

        var called = [String]()
        try await sut.deleteItem {
            called.append("delete")
        } finished: {
            called.append("finished")
        }

        #expect(called == ["delete", "finished"])
    }

    @Test
    func deleteItem_failureDoesNotCallFinished() async throws {
        let sut = makeSUT()

        try await confirmation(timeout: .milliseconds(200), expectedCount: 0) { confirmation in
            try? await sut.deleteItem {
                throw TestError()
            } finished: {
                confirmation.confirm()
            }
        }
    }

    @Test
    func deleteItem_failureDoesNotChangeEditMode() async {
        let sut = makeSUT()
        sut.startEditing()

        try? await sut.deleteItem {
            throw TestError()
        } finished: {
            // noop
        }

        #expect(sut.isInEditMode)
    }

    @Test
    func deleteItem_failureThrowsError() async {
        let sut = makeSUT()

        // TODO: replace with "#expect(throws: OperationError.delete)" in Swift 6.1
        // https://github.com/swiftlang/swift-testing/pull/624
        do {
            try await sut.deleteItem {
                throw TestError()
            } finished: {
                // noop
            }
            Issue.record("Expected error to be thrown")
        } catch DetailEditState<MockState>.OperationError.delete {
            // expected
        } catch {
            Issue.record("Unexpected error")
        }
    }

    @Test
    func operationErrorsExposeDescriptions() {
        #expect(DetailEditState<MockState>.OperationError.save.description.isEmpty == false)
        #expect(DetailEditState<MockState>.OperationError.delete.description.isEmpty == false)
        #expect(DetailEditState<MockState>.OperationError.save.errorDescription?.isEmpty == false)
        #expect(DetailEditState<MockState>.OperationError.delete.errorDescription?.isEmpty == false)
    }

    @Test
    func exitCurrentModeClearingDirtyState_clearsDirtyStateInEditMode() {
        let sut = makeSUT()
        sut.startEditing()

        var clearedState = false
        var exitedEditor = false
        sut.exitCurrentModeClearingDirtyState {
            clearedState = true
        } finished: {
            exitedEditor = true
        }

        #expect(clearedState)
        #expect(!exitedEditor, "Should not have exited editor")
    }

    @Test
    func exitCurrentModeClearingDirtyState_disablesEditModeIfInEditMode() {
        let sut = makeSUT()
        sut.startEditing()

        sut.exitCurrentModeClearingDirtyState {
            // noop
        } finished: {
            // noop
        }

        #expect(!sut.isInEditMode)
    }

    @Test
    func exitCurrentModeClearingDirtyState_existsCurrentModeIfNotInEditMode() {
        let sut = makeSUT()

        var clearedState = false
        var exitedEditor = false
        sut.exitCurrentModeClearingDirtyState {
            clearedState = true
        } finished: {
            exitedEditor = true
        }

        #expect(exitedEditor)
        #expect(!clearedState, "Should not have cleared state")
    }
}

// MARK: - Helpers

extension DetailEditStateTests {
    typealias MockState = String

    @MainActor
    private func makeSUT() -> DetailEditState<MockState> {
        DetailEditState<MockState>()
    }
}
