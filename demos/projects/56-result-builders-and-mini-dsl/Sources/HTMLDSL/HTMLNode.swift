import Foundation

public enum HTMLNode {
    case text(String)
    indirect case element(String, [(String, String)], [HTMLNode])

    public func render(indent: Int = 0) -> String {
        // Each nested level adds two leading spaces.
        let indentation = String(repeating: "  ", count: indent)

        switch self {
        case .text(let content):
            return indentation + content

        case .element(let tag, let attrs, let children):
            var openingTag = "<\(tag)"
            for (name, value) in attrs {
                openingTag += " \(name)=\"\(value)\""
            }

            if children.isEmpty {
                return indentation + openingTag + "/>"
            }

            var childLines: [String] = []
            for child in children {
                childLines.append(child.render(indent: indent + 1))
            }

            let openingLine = indentation + openingTag + ">"
            let body = childLines.joined(separator: "\n")
            let closingLine = indentation + "</\(tag)>"

            return openingLine + "\n" + body + "\n" + closingLine
        }
    }
}
