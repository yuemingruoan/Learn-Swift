import Foundation
import SwiftSyntax
import SwiftSyntaxMacros

enum URLMacroError: Error, CustomStringConvertible {
    case requireStringLiteral
    case invalidURL(String)

    var description: String {
        switch self {
        case .requireStringLiteral:
            return "#URL 的参数必须是字符串字面量"
        case .invalidURL(let s):
            return "不是合法的 URL：\(s)"
        }
    }
}

public struct URLMacro: ExpressionMacro {
    public static func expansion(
        of node: some FreestandingMacroExpansionSyntax,
        in context: some MacroExpansionContext
    ) throws -> ExprSyntax {
        guard let argument = node.arguments.first?.expression,
              let literal = argument.as(StringLiteralExprSyntax.self),
              literal.segments.count == 1,
              case let .stringSegment(segment) = literal.segments.first
        else {
            throw URLMacroError.requireStringLiteral
        }

        let text = segment.content.text
        guard Foundation.URL(string: text) != nil else {
            throw URLMacroError.invalidURL(text)
        }

        return "URL(string: \(literal: text))!"
    }
}
