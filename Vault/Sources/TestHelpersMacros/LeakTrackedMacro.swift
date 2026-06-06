import SwiftCompilerPlugin
import SwiftDiagnostics
import SwiftSyntax
import SwiftSyntaxMacros

@main
struct TestHelpersMacrosPlugin: CompilerPlugin {
    let providingMacros: [any Macro.Type] = [LeakTrackedMacro.self]
}

/// Body macro that wraps the function body in a `withLeakTracking { ... }` scope. Apply alongside
/// `@Test` so that any object registered via `trackForMemoryLeaks(_:)` inside the body is verified
/// at body exit.
///
/// The decorated function must be `throws` (or `async throws`) — `withLeakTracking` is `rethrows`
/// and a leak that propagates the closure's throws needs an enclosing throwing context.
public struct LeakTrackedMacro: BodyMacro {
    public static func expansion(
        of _: AttributeSyntax,
        providingBodyFor declaration: some DeclSyntaxProtocol & WithOptionalCodeBlockSyntax,
        in context: some MacroExpansionContext,
    ) throws -> [CodeBlockItemSyntax] {
        guard let function = declaration.as(FunctionDeclSyntax.self), let body = function.body else {
            context.diagnose(.init(
                node: Syntax(declaration),
                message: SimpleDiagnostic("@LeakTracked must be applied to a function with a body."),
            ))
            return []
        }

        let isAsync = function.signature.effectSpecifiers?.asyncSpecifier != nil
        let throwsKeyword = function.signature.effectSpecifiers?.throwsClause
        if throwsKeyword == nil {
            context.diagnose(.init(
                node: Syntax(function.signature),
                message: SimpleDiagnostic(
                    "@LeakTracked requires the function to be marked `throws` (or `async throws`).",
                ),
            ))
        }

        let statements = body.statements
        let wrapperCall: ExprSyntax = if isAsync {
            "try await withLeakTracking { () async throws in \(statements) }"
        } else {
            "try withLeakTracking { () throws in \(statements) }"
        }

        return [CodeBlockItemSyntax(item: .expr(wrapperCall))]
    }
}

private struct SimpleDiagnostic: DiagnosticMessage {
    let message: String

    init(_ message: String) {
        self.message = message
    }

    var diagnosticID: MessageID {
        MessageID(domain: "TestHelpersMacros", id: "LeakTracked")
    }

    var severity: DiagnosticSeverity {
        .error
    }
}
