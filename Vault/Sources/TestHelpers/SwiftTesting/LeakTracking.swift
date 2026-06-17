import Foundation
import FoundationExtensions
import Testing

/// Tracks weak references to objects that should deallocate by the end of a leak-tracking scope.
///
/// You normally do not interact with `LeakTracker` directly — call ``withLeakTracking(_:)`` and
/// register objects inside the closure via ``trackForMemoryLeaks(_:sourceLocation:)``.
public final class LeakTracker: Sendable {
    @TaskLocal
    public static var current: LeakTracker?

    // `WeakBox<AnyObject>` is not `Sendable` because `AnyObject` has no `Sendable` constraint, but
    // all reads/writes of `Entry` go through the `SharedMutex` below, which serialises access. The
    // `weak` storage itself is implemented atomically by the runtime.
    // swiftlint:disable:next no_unchecked_sendable
    private struct Entry: @unchecked Sendable {
        let ref: WeakBox<AnyObject>
        let typeName: String
        let sourceLocation: SourceLocation
    }

    private let entries = SharedMutex<[Entry]>([])

    init() {}

    fileprivate func track(_ instance: AnyObject, typeName: String, sourceLocation: SourceLocation) {
        let entry = Entry(ref: WeakBox(instance), typeName: typeName, sourceLocation: sourceLocation)
        entries.modify { $0.append(entry) }
    }

    func verify() {
        let snapshot = entries.modify { current -> [Entry] in
            let copy = current
            current.removeAll()
            return copy
        }
        for entry in snapshot where entry.ref.value != nil {
            Issue.record(
                "Potential memory leak: \(entry.typeName) was not deallocated at end of test scope.",
                sourceLocation: entry.sourceLocation,
            )
        }
    }
}

/// Runs `body` with a fresh ``LeakTracker`` installed as ``LeakTracker/current``, then verifies on
/// exit that every object registered via ``trackForMemoryLeaks(_:sourceLocation:)`` has been
/// deallocated. Any live reference is reported as an `Issue` against the current test.
///
/// Wrap the body of each `@Test` that constructs reference-type SUTs:
/// ```swift
/// @Test
/// func myTest() throws {
///     try withLeakTracking {
///         let sut = makeSUT()
///         #expect(sut.foo)
///     }
/// }
/// ```
///
/// The closure's body locals must be released before `verify()` runs, so the scope must be a
/// closure (not the `@Test` method itself). Swift Testing retains the test method's stack frame
/// for the duration of any `TestScoping`-based trait, which is why a trait-based approach causes
/// false positives — see git history for the abandoned `.trackLeaks` trait.
public func withLeakTracking<R>(
    _ body: () throws -> R,
) rethrows -> R {
    let tracker = LeakTracker()
    let result = try LeakTracker.$current.withValue(tracker) {
        try body()
    }
    tracker.verify()
    return result
}

public func withLeakTracking<R>(
    isolation _: isolated (any Actor)? = #isolation,
    _ body: () async throws -> R,
) async rethrows -> R {
    let tracker = LeakTracker()
    let result = try await LeakTracker.$current.withValue(tracker) {
        try await body()
    }
    tracker.verify()
    return result
}

/// Registers `instance` with the currently active ``LeakTracker``. When the enclosing
/// ``withLeakTracking(_:)`` scope ends, an Issue is recorded if `instance` has not been
/// deallocated.
///
/// Must be called inside ``withLeakTracking(_:)``. Calls outside record an Issue at
/// `sourceLocation` so misuse is loud.
///
/// Returns its argument so it can be chained at the construction site:
/// ```swift
/// let sut = trackForMemoryLeaks(VaultStore(...))
/// ```
@discardableResult
public func trackForMemoryLeaks<T: AnyObject>(
    _ instance: @autoclosure () -> T,
    sourceLocation: SourceLocation = #_sourceLocation,
) -> T {
    let value = instance()
    guard let tracker = LeakTracker.current else {
        Issue.record(
            "trackForMemoryLeaks called without an active withLeakTracking scope.",
            sourceLocation: sourceLocation,
        )
        return value
    }
    tracker.track(value, typeName: String(describing: T.self), sourceLocation: sourceLocation)
    return value
}
