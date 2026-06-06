import Foundation
import Testing
@testable import TestHelpers

@Suite
struct LeakTrackingTests {
    @Test @LeakTracked
    func cleanDeallocation_recordsNoIssue() throws {
        _ = trackForMemoryLeaks(Probe())
    }

    @Test
    func retainedInstance_recordsIssue() {
        let probe = Probe()
        withKnownIssue {
            withLeakTracking {
                _ = trackForMemoryLeaks(probe)
            }
        }
        _ = probe
    }

    @Test
    func trackWithoutScope_recordsIssue() {
        withKnownIssue {
            _ = trackForMemoryLeaks(Probe())
        }
    }

    @Test @LeakTracked
    @MainActor
    func mainActor_cleanDeallocation_recordsNoIssue() throws {
        _ = trackForMemoryLeaks(Probe())
    }

    @Test @LeakTracked
    @MainActor
    func mainActor_async_cleanDeallocation_recordsNoIssue() async throws {
        _ = trackForMemoryLeaks(Probe())
    }
}

// MARK: - Helpers

extension LeakTrackingTests {
    fileprivate final class Probe {}
}
