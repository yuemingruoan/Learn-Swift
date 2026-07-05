import Foundation

@discardableResult
public func element(
    _ tag: String,
    attrs: [(String, String)] = [],
    @HTMLBuilder children: () -> [HTMLNode]
) -> HTMLNode {
    .element(tag, attrs, children())
}

public func html(@HTMLBuilder _ children: () -> [HTMLNode]) -> HTMLNode {
    element("html", children: children)
}

public func head(@HTMLBuilder _ children: () -> [HTMLNode]) -> HTMLNode {
    element("head", children: children)
}

public func body(@HTMLBuilder _ children: () -> [HTMLNode]) -> HTMLNode {
    element("body", children: children)
}

public func title(@HTMLBuilder _ children: () -> [HTMLNode]) -> HTMLNode {
    element("title", children: children)
}

public func h1(@HTMLBuilder _ children: () -> [HTMLNode]) -> HTMLNode {
    element("h1", children: children)
}

public func h2(@HTMLBuilder _ children: () -> [HTMLNode]) -> HTMLNode {
    element("h2", children: children)
}

public func p(@HTMLBuilder _ children: () -> [HTMLNode]) -> HTMLNode {
    element("p", children: children)
}

public func div(@HTMLBuilder _ children: () -> [HTMLNode]) -> HTMLNode {
    element("div", children: children)
}

public func article(@HTMLBuilder _ children: () -> [HTMLNode]) -> HTMLNode {
    element("article", children: children)
}

public func a(href: String, @HTMLBuilder _ children: () -> [HTMLNode]) -> HTMLNode {
    element("a", attrs: [("href", href)], children: children)
}

public func text(_ s: String) -> HTMLNode {
    .text(s)
}

public struct Post: Sendable {
    public let title: String
    public let body: String
    public init(title: String, body: String) {
        self.title = title
        self.body = body
    }
}
