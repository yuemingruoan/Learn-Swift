import Foundation

public enum MenuNode {
    case item(String)
    indirect case submenu(String, [MenuNode])

    public func render(indent: Int = 0) -> String {
        let pad = String(repeating: "  ", count: indent)
        switch self {
        case .item(let s):
            return "\(pad)- \(s)"
        case .submenu(let title, let children):
            let header = "\(pad)+ \(title)"
            let body = children
                .map { $0.render(indent: indent + 1) }
                .joined(separator: "\n")
            if body.isEmpty { return header }
            return "\(header)\n\(body)"
        }
    }
}

@resultBuilder
public enum MenuBuilder {
    public static func buildExpression(_ node: MenuNode) -> [MenuNode] {
        [node]
    }

    public static func buildExpression(_ nodes: [MenuNode]) -> [MenuNode] {
        nodes
    }

    public static func buildBlock(_ parts: [MenuNode]...) -> [MenuNode] {
        parts.flatMap { $0 }
    }

    public static func buildOptional(_ component: [MenuNode]?) -> [MenuNode] {
        component ?? []
    }

    public static func buildEither(first component: [MenuNode]) -> [MenuNode] {
        component
    }

    public static func buildEither(second component: [MenuNode]) -> [MenuNode] {
        component
    }

    public static func buildArray(_ components: [[MenuNode]]) -> [MenuNode] {
        components.flatMap { $0 }
    }
}

public func item(_ title: String) -> MenuNode {
    .item(title)
}

public func submenu(title: String, @MenuBuilder _ children: () -> [MenuNode]) -> MenuNode {
    .submenu(title, children())
}

public func menu(title: String, @MenuBuilder _ children: () -> [MenuNode]) -> MenuNode {
    .submenu(title, children())
}

let isPro = true
let recent = ["a.swift", "b.swift"]

let m = menu(title: "主菜单") {
    item("新建文件")
    item("打开文件")
    if isPro {
        item("导出 PDF")
    } else {
        item("升级到 Pro")
    }
    for name in recent {
        item("最近：\(name)")
    }
    submenu(title: "设置") {
        item("外观")
        item("快捷键")
    }
}

print(m.render())
