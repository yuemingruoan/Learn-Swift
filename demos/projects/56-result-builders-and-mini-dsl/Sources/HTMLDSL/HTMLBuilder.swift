import Foundation

@resultBuilder
public enum HTMLBuilder {
    public static func buildExpression(_ node: HTMLNode) -> [HTMLNode] {
        [node]
    }

    public static func buildExpression(_ nodes: [HTMLNode]) -> [HTMLNode] {
        nodes
    }

    public static func buildBlock(_ parts: [HTMLNode]...) -> [HTMLNode] {
        parts.flatMap { $0 }
    }

    public static func buildOptional(_ component: [HTMLNode]?) -> [HTMLNode] {
        component ?? []
    }

    public static func buildEither(first component: [HTMLNode]) -> [HTMLNode] {
        component
    }

    public static func buildEither(second component: [HTMLNode]) -> [HTMLNode] {
        component
    }

    public static func buildArray(_ components: [[HTMLNode]]) -> [HTMLNode] {
        components.flatMap { $0 }
    }

    public static func buildLimitedAvailability(_ component: [HTMLNode]) -> [HTMLNode] {
        component
    }

    public static func buildFinalResult(_ component: [HTMLNode]) -> [HTMLNode] {
        component
    }
}
