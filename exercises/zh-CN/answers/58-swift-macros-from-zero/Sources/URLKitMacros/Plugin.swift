import SwiftCompilerPlugin
import SwiftSyntaxMacros

@main
struct URLKitPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        URLMacro.self,
    ]
}
