# 56. Result Builder 与 DSL 练习答案

对应章节：

- [56. Result Builder 与 DSL：从语法转写到 mini HTML builder](../../../docs/zh-CN/chapters/56-result-builders-and-mini-dsl.md)

如果你想一边看答案一边运行 starter project，可以打开：

- `exercises/zh-CN/projects/56-result-builders-and-mini-dsl-starter`

如果你想直接运行本章练习的参考工程，也可以打开：

- `exercises/zh-CN/answers/56-result-builders-and-mini-dsl`

说明：

- 每道题的**完整描述**在教程正文的「练习」一节：[56. Result Builder 与 DSL](../../../docs/zh-CN/chapters/56-result-builders-and-mini-dsl.md#练习)。这里只放参考实现与逐题讲解。
- 本章练习核心是亲手实现一个完整的 result builder，覆盖 `if` / `if-else` / `for` 三种结构
- 通过这个练习你应该能脱口说出每一个 `build*` 方法对应什么语法

## 任务 1：实现 `MenuBuilder`

> 从零做一个命令行菜单 DSL，让 `menu/submenu/item` + `if`/`for` 能拼成一棵菜单树并 `render()`。（完整描述见正文）

### 参考实现

```swift
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
    public static func buildExpression(_ node: MenuNode) -> [MenuNode] { [node] }
    public static func buildExpression(_ nodes: [MenuNode]) -> [MenuNode] { nodes }
    public static func buildBlock(_ parts: [MenuNode]...) -> [MenuNode] {
        parts.flatMap { $0 }
    }
    public static func buildOptional(_ component: [MenuNode]?) -> [MenuNode] {
        component ?? []
    }
    public static func buildEither(first component: [MenuNode]) -> [MenuNode] { component }
    public static func buildEither(second component: [MenuNode]) -> [MenuNode] { component }
    public static func buildArray(_ components: [[MenuNode]]) -> [MenuNode] {
        components.flatMap { $0 }
    }
}

public func item(_ title: String) -> MenuNode { .item(title) }
public func submenu(title: String, @MenuBuilder _ children: () -> [MenuNode]) -> MenuNode {
    .submenu(title, children())
}
public func menu(title: String, @MenuBuilder _ children: () -> [MenuNode]) -> MenuNode {
    .submenu(title, children())
}
```

### 解题点评

- 用同一个 `MenuNode.submenu` 表达"顶层菜单"和"子菜单"，让 `menu` 与 `submenu` 共用类型
- `buildExpression` 的两个重载是关键：一个收单节点，一个收节点数组——这让 builder 内部全程在 `[MenuNode]` 上工作
- `submenu(title:_:)` 把闭包参数标 `@MenuBuilder`，这样它的内部也可以用 `if` / `for`
- 如果你忘了写 `buildOptional`，单边 `if` 直接编译错；忘了写 `buildEither`，`if-else` 也编译错——这正是工程里常见的"按需实现 build 方法"的模式

## 任务 2：读一段 DSL，写出它的展开形态

> 把一段含"顺序 + `if/else` + `for-in`"的 `HTMLBuilder` 代码手写成 `build*` 调用形态，并顺带想清楚该不该实现 `buildArray`。（完整描述见正文）

下面这段代码用本章的 `HTMLBuilder` 写成，里面同时出现了"顺序 + `if/else` + `for-in`"三种结构：

```swift
func makePage(isAdmin: Bool, tags: [String]) -> HTMLNode {
    div {
        h1 { text("Dashboard") }
        if isAdmin {
            p { text("admin panel") }
        } else {
            p { text("guest view") }
        }
        for tag in tags {
            p { text(tag) }
        }
    }
}
```

请写出 `div { ... }` 这个闭包体被编译器改写成 `build*` 方法调用后的大致形态，并列表说明每个语法结构对应哪个 `build*` 方法。

### 每个语法结构对应的 build 方法

按出现顺序：

| 代码片段 | 用到的 build 方法 |
| --- | --- |
| 每一条裸的 `h1 { ... }` / `p { ... }` | `buildExpression`（把单个 `HTMLNode` 包成 `[HTMLNode]`） |
| 闭包体里"顺序排列的几段"最后拼到一起 | `buildBlock(_:)` |
| `if isAdmin { ... } else { ... }` | `buildEither(first:)` / `buildEither(second:)` |
| `for tag in tags { ... }` | `buildArray(_:)`（循环体每轮先各自 `buildBlock`，再整体交给 `buildArray`） |

### 展开形态（伪代码）

```swift
func makePage(isAdmin: Bool, tags: [String]) -> HTMLNode {
    // 第 1 段：顺序里的第一项
    let _0 = HTMLBuilder.buildExpression(h1 { text("Dashboard") })

    // 第 2 段：if-else 的两支，各自先 buildExpression + buildBlock，再 buildEither
    let _1: [HTMLNode]
    if isAdmin {
        _1 = HTMLBuilder.buildEither(
            first: HTMLBuilder.buildBlock(
                HTMLBuilder.buildExpression(p { text("admin panel") })
            )
        )
    } else {
        _1 = HTMLBuilder.buildEither(
            second: HTMLBuilder.buildBlock(
                HTMLBuilder.buildExpression(p { text("guest view") })
            )
        )
    }

    // 第 3 段：for-in，每轮 buildBlock 一次，攒成二维数组后交给 buildArray
    var loopAcc: [[HTMLNode]] = []
    for tag in tags {
        loopAcc.append(
            HTMLBuilder.buildBlock(
                HTMLBuilder.buildExpression(p { text(tag) })
            )
        )
    }
    let _2 = HTMLBuilder.buildArray(loopAcc)

    // 三段顺序项最终拼成一个 [HTMLNode]
    let children = HTMLBuilder.buildBlock(_0, _1, _2)
    return .element("div", [], children)
}
```

要点：

- 因为本章的 `HTMLBuilder` 全程在 `[HTMLNode]` 上工作，所以每一条裸表达式都先经过 `buildExpression` 变成 `[HTMLNode]`，后面的 `buildBlock` / `buildEither` / `buildArray` 才能类型统一地拼接
- `if-else` 的关键不是"哪支被执行"，而是两支都被包进同一个 `buildEither` 形态里，这样无论走哪支，`children` 那一项的类型都一致
- `for-in` 是先把每一轮的结果 `buildBlock` 成一项，攒成二维数组，再用 `buildArray` 拍平

### 该不该实现 `buildArray`

- 实现它，闭包体里就能直接写 `for-in` 批量生成内容，写起来最顺手——本章 DSL 就是这么做的
- 不实现，是为了**禁止**在闭包体里随手 `for-in`。典型理由有两类：一是性能/复杂度，循环动态展开会让结果数量不可控；二是稳定标识，像 SwiftUI 的 `ViewBuilder` 就不让你直接 `for-in`，而是逼你走 `ForEach(_:id:)`，好给每个元素一个稳定的身份做 diff
- 结论：要不要 `buildArray` 取决于"你愿不愿意让使用者在闭包里写循环"。要可控、要稳定标识就别实现，转而提供一个能为每个元素保留身份的专用入口

### result builder 处理 `switch` / 多分支时的通用注意点

如果把上面的 `if/else` 换成一个三分支的 `switch`：

```swift
div {
    h1 { text("Dashboard") }
    switch role {
    case .admin: p { text("admin panel") }
    case .guest: p { text("guest view") }
    case .banned: p { text("no access") }
    }
}
```

要让这段能编译，本章的 `HTMLBuilder` 需要满足两点：

- `switch` 同样被转写成嵌套的 `buildEither(first:)` / `buildEither(second:)`，所以**必须实现 `buildEither` 这一对方法**——只实现了 `buildOptional`（单边 `if`）是不够的
- 每个 `case` 分支体仍然各自走一遍 `buildBlock`（哪怕分支里只有一条表达式），再被 `buildEither` 包起来

也就是说，多分支选择对 result builder 的要求和 `if-else` 是同一套：核心是 `buildEither`。如果你的 builder 没实现它，`switch` 和 `if-else` 都会直接编译报错，错误信息通常指向"缺少 `buildEither` 重载"。设计 builder 时，要不要支持分支选择，就取决于你愿不愿意实现这对方法。

## 自检清单

完成本章练习后，你应当能脱口回答：

- result builder 是运行时机制还是编译期机制？
- `buildBlock` / `buildOptional` / `buildEither` / `buildArray` 各自对应什么语法结构？
- 一个 result builder 该不该实现 `buildArray`？实现与不实现各有什么取舍？
- 何时需要 `buildExpression`？

如果其中任意一条不能立刻回答出来，建议回到正文相应模块再读一遍。
