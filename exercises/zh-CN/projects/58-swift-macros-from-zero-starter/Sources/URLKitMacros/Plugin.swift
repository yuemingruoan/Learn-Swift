import SwiftCompilerPlugin
import SwiftSyntaxMacros

@main
struct URLKitPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        // TODO: 在这里注册你写的 URLMacro
    ]
}
