import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest
@testable import MacrosKitMacros

final class StringifyMacroTests: XCTestCase {
    private let macros: [String: Macro.Type] = [
        "stringify": StringifyMacro.self,
    ]

    func test_stringify_展开为表达式与其源代码字符串的二元组() {
        assertMacroExpansion(
            """
            let pair = #stringify(1 + 2)
            """,
            expandedSource: """
            let pair = (1 + 2, "1 + 2")
            """,
            macros: macros
        )
    }

    func test_stringify_保留参数原文_包含变量名与函数调用() {
        assertMacroExpansion(
            """
            let r = #stringify(add(3, 4))
            """,
            expandedSource: #"""
            let r = (add(3, 4), "add(3, 4)")
            """#,
            macros: macros
        )
    }

    func test_stringify_对字符串字面量也保留源代码() {
        assertMacroExpansion(
            #"""
            let r = #stringify("hi")
            """#,
            expandedSource: #"""
            let r = ("hi", "\"hi\"")
            """#,
            macros: macros
        )
    }
}
