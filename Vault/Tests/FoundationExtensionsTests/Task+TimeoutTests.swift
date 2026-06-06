import Foundation
import FoundationExtensions
import TestHelpers
import Testing

struct TaskTimeoutTests {
    @Test
    func timeoutReturnsTimeoutError() async throws {
        let parent = Task {
            try await Task.withTimeout(delay: .milliseconds(100)) {
                try await suspendForever()
            }
        }
        try await Task.sleep(for: .milliseconds(500))
        await #expect(throws: TimeoutError.self, performing: {
            try await parent.value
        })
    }

    @Test
    func cancelledReturnsCancelledError() async {
        let parent = Task {
            try await Task.withTimeout(delay: .milliseconds(500)) {
                try await suspendForever()
            }
        }
        parent.cancel()

        await #expect(throws: CancellationError.self, performing: {
            try await parent.value
        })
    }

    @Test
    func returnsValue() async throws {
        let pending = Pending<Int>()
        let parent = Task {
            try await Task.withTimeout(delay: .seconds(10)) {
                try await pending.wait()
            }
        }
        try await Task.sleep(for: .milliseconds(100))
        await pending.fulfill(101)
        let value = try await parent.value

        #expect(value == 101)
    }
}
