/// Wraps the function body in `withLeakTracking(_:)`.
///
/// The function must be `throws` (or `async throws`).
@attached(body)
macro LeakTracked() = #externalMacro(module: "TestHelpersMacros", type: "LeakTrackedMacro")
