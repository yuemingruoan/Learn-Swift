import SwiftCompilerPlugin
import SwiftSyntaxMacros

@main
struct MacrosKitPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        StringifyMacro.self,
    ]
}
