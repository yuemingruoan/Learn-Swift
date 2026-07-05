import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest
@testable import URLKitMacros

final class URLMacroTests: XCTestCase {
    private let macros: [String: Macro.Type] = [
        "URL": URLMacro.self,
    ]

    func test_合法_URL_字面量展开为_URL_string_unwrap() {
        assertMacroExpansion(
            #"""
            let u = #URL("https://example.com")
            """#,
            expandedSource: #"""
            let u = URL(string: "https://example.com")!
            """#,
            macros: macros
        )
    }

    func test_非字符串字面量参数应当报错() {
        assertMacroExpansion(
            #"""
            let s = "https://example.com"
            let u = #URL(s)
            """#,
            expandedSource: #"""
            let s = "https://example.com"
            let u = #URL(s)
            """#,
            diagnostics: [
                DiagnosticSpec(message: "#URL 的参数必须是字符串字面量", line: 2, column: 9),
            ],
            macros: macros
        )
    }

    func test_不合法_URL_应当报错() {
        assertMacroExpansion(
            #"""
            let u = #URL(" ")
            """#,
            expandedSource: #"""
            let u = #URL(" ")
            """#,
            diagnostics: [
                DiagnosticSpec(message: "不是合法的 URL： ", line: 1, column: 9),
            ],
            macros: macros
        )
    }
}
