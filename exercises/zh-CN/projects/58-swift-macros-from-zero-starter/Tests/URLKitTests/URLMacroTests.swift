import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest
@testable import URLKitMacros

final class URLMacroTests: XCTestCase {
    private let macros: [String: Macro.Type] = [
        // TODO: 注册 URLMacro
    ]

    func test_合法_URL_字面量展开为_URL_string_unwrap() {
        // TODO: 用 assertMacroExpansion 验证：
        //   #URL("https://example.com")
        // 展开为：
        //   URL(string: "https://example.com")!
    }

    func test_非字符串字面量参数应当报编译错误() {
        // TODO: 验证 #URL(some_var) 这种写法时 diagnostics 包含 "字符串字面量" 字样
    }

    func test_不合法_URL_应当报编译错误() {
        // TODO: 验证 #URL(" ") 时 diagnostics 包含 "合法的 URL" 字样
    }
}
