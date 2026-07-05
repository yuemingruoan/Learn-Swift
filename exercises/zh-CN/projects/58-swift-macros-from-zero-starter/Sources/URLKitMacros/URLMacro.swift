import SwiftSyntax
import SwiftSyntaxMacros

// TODO: 实现 URLMacro: ExpressionMacro
//
// 推荐步骤：
//
// 1. 取 node.arguments.first?.expression
// 2. 用 .as(StringLiteralExprSyntax.self) 检查是否为字符串字面量
//    不是 → throw 一个自定义 error（见下面的 URLMacroError）
// 3. 取字符串字面量的真实文本：
//    let segments = literal.segments
//    确认它只有一段、且是 .stringSegment(_)
//    然后从 segment.content.text 拿到字符串
// 4. 用 Foundation.URL(string: text) 校验
//    nil 就 throw 错误
// 5. 返回 "URL(string: \(literal: text))!"
//
// 错误类型示例：
//
//     enum URLMacroError: Error, CustomStringConvertible {
//         case requireStringLiteral
//         case invalidURL(String)
//         var description: String {
//             switch self {
//             case .requireStringLiteral: return "#URL 的参数必须是字符串字面量"
//             case .invalidURL(let s):    return "不是合法的 URL：\(s)"
//             }
//         }
//     }
