# 56. Result Builder 与 DSL：从语法转写到 mini HTML builder

## 阅读导航

- 前置章节：[12. 函数与代码复用](./12-functions-and-code-reuse.md)、[21. 协议：灵活的抽象](./21-protocols-flexible-abstraction.md)、[24. 泛型：可复用的抽象](./24-generics-reusable-abstractions.md)、[25. 闭包：把函数当作值](./25-closures-functions-as-values.md)、[54. 关联类型与不透明返回类型：`associatedtype` 与 `some`](./54-associated-types-and-opaque-return-types.md)
- 上一章：[55. 属性包装器原理：从零实现一个 `@propertyWrapper`](./55-property-wrappers-from-zero.md)
- 下一章：[57. KeyPath、`Identifiable` 与 `@MainActor` 小合集](./57-keypath-identifiable-and-mainactor.md)
- 适合谁读：能看懂闭包和泛型，见过 SwiftUI 或其他库里那种能在 `{ }` 里并排写多条语句的声明式写法，但还说不清 `@ViewBuilder` / `@HTMLBuilder` 这类东西到底从哪来、编译器怎样处理这些语句的读者

## 本章目标

学完这一章后，你应该能够：

- 理解 result builder 是一种编译期语法转写机制，不是运行时反射，也不是文本宏
- 说清 `@resultBuilder` 标记的类型、闭包参数上的 `@SomeBuilder`、闭包体里的多条表达式三者之间的关系
- 看懂编译器如何把 `{ a; b; c }` 改写成 `buildExpression` + `buildBlock` 这类调用
- 能够解释 `buildExpression`、`buildBlock`、`buildOptional`、`buildEither(first:)` / `buildEither(second:)`、`buildArray`、`buildLimitedAvailability`、`buildFinalResult` 各自对应什么语法结构
- 从零实现一个 mini `HTMLBuilder`，支持顺序拼接、`if`、`if-else`、`switch`、`for-in` 这几类常见结构
- 读一段 DSL（领域专用语言）代码，手写出大致展开形态，并判断一个 builder 该不该支持某种语法
- 判断什么时候适合把 API 做成 result builder，什么时候普通函数、初始化器或数组更清楚

## 本章对应资源

- 文稿：`docs/zh-CN/chapters/56-result-builders-and-mini-dsl.md`
- 示例项目：`demos/projects/56-result-builders-and-mini-dsl`
- 练习 starter：`exercises/zh-CN/projects/56-result-builders-and-mini-dsl-starter`
- 练习答案：`exercises/zh-CN/answers/56-result-builders-and-mini-dsl.md`

## 本章怎么读

建议阅读顺序：

1. 先看普通闭包为什么不能自动收集多条语句，明确 result builder 要解决的问题
2. 用最小的 `LineBuilder` 学语法转写规则
3. 逐个加上 `buildExpression`、`buildOptional`、`buildEither`、`buildArray`，理解每个方法对应的 Swift 语法
4. 再把这套机制迁移到 `HTMLNode`，理解一个树形 DSL 如何从同一套规则里长出来
5. 最后用完整 demo 和练习巩固：能手写展开形态，才算真正理解 result builder

## 正文主体

### 模块 0：从 DSL 和普通闭包的限制开始

DSL 是 domain-specific language 的缩写，中文常译作“领域专用语言”。这里的“语言”不是一门全新的编程语言，而是一套为某个具体问题设计出来的专用写法。在 Swift 里，DSL 通常由函数、类型和语法特性组合而成，让代码读起来更接近要描述的东西。

比如本章后面会实现一个 mini HTML DSL，让 Swift 代码读起来接近“声明一棵 HTML 节点树”。在进入 HTML 之前，先用一个更小的例子看清问题：假设要收集几行文本，一个自然的 DSL 可能长这样：

```swift
let lines = collect {
    "标题"
    "正文"
    "结尾"
}
```

这段代码看起来像是在“声明几行文本”，而不是手动创建数组、追加元素。关键不在 `collect` 这个名字，而在大括号里的三条字符串表达式：它们似乎被自动收集成了一个结果。

普通闭包默认没有这种能力。如果 `collect` 只是接收一个普通闭包：

```swift
func collect(_ body: () -> [String]) -> [String] {
    body()
}

let lines = collect {
    "标题"
    "正文"
}
```

这段不会得到 `["标题", "正文"]`。普通 Swift 闭包没有“把多行表达式自动收集成数组”的规则。闭包如果预期返回 `[String]`，你需要显式返回一个数组：

```swift
let lines = collect {
    return ["标题", "正文"]
}
```

如果闭包返回 `Void`，那几条字符串表达式只会成为无用表达式；如果闭包预期返回 `[String]`，编译器会认为你没有返回正确结果。无论哪一种，普通闭包都不会替你把多条语句拼起来。

result builder 解决的正是这件事：它让某些闭包体进入一套特殊的编译期转写流程。闭包体里每条表达式会先被转换成 builder 的内部组件，然后再被组合成最终结果。我们之后会带着大家实现的 `mini HTML DSL` 也是同一套机制的应用：只不过最终收集出来的不是几行字符串，而是一棵 HTML 节点树。

所以本章先回答四个问题：

1. Swift 怎么知道这个闭包要用特殊规则解释；
2. 编译器把闭包体改写成了哪些方法调用；
3. 这些方法应该怎样定义；
4. 怎样把这套机制应用到一个具体的 HTML DSL。

### 模块 1：result builder 的三块拼图

一个 result builder 由三块东西拼起来。

#### 第一块：一个标了 `@resultBuilder` 的类型

```swift
@resultBuilder
enum LineBuilder {
    static func buildBlock(_ parts: String...) -> [String] {
        parts
    }
}
```

`@resultBuilder` 告诉编译器：这个类型可以作为“闭包体转写规则”的提供者。

这里用 `enum` 是常见写法。builder 类型只需要静态方法，不需要创建实例，用 `enum` 可以直接阻止别人写 `LineBuilder()`。

#### 第二块：某个函数、属性或闭包参数使用这个 builder

最常见的是把 builder 标在闭包参数上：

```swift
func collect(@LineBuilder _ body: () -> [String]) -> [String] {
    body()
}
```

这行里的 `@LineBuilder` 很关键。它不是说 `body` 的类型变成了 `LineBuilder`；`body` 仍然是 `() -> [String]`。区别在于：调用方传进来的闭包体，会先被 `LineBuilder` 的规则改写。

也可以把 builder 标在函数本身上：

```swift
@LineBuilder
func makeLines() -> [String] {
    "标题"
    "正文"
}
```

这表示 `makeLines()` 的函数体用 `LineBuilder` 解释。

#### 第三块：闭包体里的语句被编译器改写

现在这段代码：

```swift
let lines = collect {
    "标题"
    "正文"
}
```

可以理解成被编译器改写成类似下面的形态：

```swift
let lines = collect {
    LineBuilder.buildBlock("标题", "正文")
}
```

这就是 result builder 的本质：**编译器按照固定规则，把一个闭包体转写成对 builder 静态方法的调用**。

它不是运行时反射。运行时不会扫描闭包文本，也不会猜测你写了几行。能不能编译，取决于 builder 类型上有没有对应形状的静态方法。

### 模块 2：先用 `LineBuilder` 看清最小转写

从最小版本开始：

```swift
@resultBuilder
enum LineBuilder {
    static func buildBlock(_ parts: String...) -> [String] {
        parts
    }
}

func collect(@LineBuilder _ body: () -> [String]) -> [String] {
    body()
}

let lines = collect {
    "标题"
    "正文"
    "结尾"
}

print(lines)       // ["标题", "正文", "结尾"]
```

这个版本只支持一件事：同一层里并排写多条 `String` 表达式。

它的近似展开是：

```swift
let lines = collect {
    LineBuilder.buildBlock(
        "标题",
        "正文",
        "结尾"
    )
}
```

这里有几个关键点：

- `buildBlock` 负责“同一层顺序拼接”
- 闭包体里的三条裸表达式都必须是 `String`
- `buildBlock(_ parts: String...) -> [String]` 把多个 `String` 合成一个 `[String]`
- 闭包最终仍然返回 `[String]`，所以 `collect` 的参数类型不需要变化

这一版足够解释“为什么多条语句能拼起来”，但它还很脆弱。它只适合所有裸表达式都直接是 `String` 的场景。稍微复杂一点，通常要引入 `buildExpression`。

### 模块 3：`buildExpression` 负责把“裸表达式”变成内部组件

真实 builder 里，我们通常会区分两种类型：

- `Expression`：使用者在闭包体里直接写下的东西
- `Component`：builder 内部统一搬运和拼接的东西

在刚才的最小例子里，裸表达式是 `String`，内部组件也可以暂时当作 `String`。但一旦要支持 `if`、`for`、嵌套片段，内部组件更适合统一成 `[String]`。

于是我们把 `LineBuilder` 改成这样：

```swift
@resultBuilder
enum LineBuilder {
    static func buildExpression(_ expression: String) -> [String] {
        [expression]
    }

    static func buildExpression(_ expressions: [String]) -> [String] {
        expressions
    }

    static func buildBlock(_ parts: [String]...) -> [String] {
        parts.flatMap { $0 }
    }
}
```

现在每一条裸表达式会先经过 `buildExpression`：

```swift
let lines = collect {
    "标题"
    "正文"
}
```

可以理解成：

```swift
let lines = collect {
    let part0 = LineBuilder.buildExpression("标题")
    let part1 = LineBuilder.buildExpression("正文")
    return LineBuilder.buildBlock(part0, part1)
}
```

这里的 `return` 只是伪代码，用来解释结果。真实 result builder 闭包体里一般不能显式写 `return`，否则会跳过 builder 转写并触发编译错误。

引入 `buildExpression` 后，类型关系更清楚了：

| 名称 | 在这个例子里是什么 | 作用 |
| --- | --- | --- |
| 裸表达式 | `String` 或 `[String]` | 使用者能直接写在闭包体里的东西 |
| 内部组件 | `[String]` | builder 后续统一处理的累加形态 |
| `buildExpression` | `String -> [String]`、`[String] -> [String]` | 把合法的裸表达式接入 builder |
| `buildBlock` | `[String]... -> [String]` | 把同一层组件按书写顺序拼起来 |

`buildExpression` 还有一个很实际的作用：它决定“闭包体里哪些表达式合法”。如果你只写了 `buildExpression(_ expression: String)`，那使用者在闭包体里写 `42` 就不会被接住，编译器会报类型错误。

### 模块 4：`if`、`if-else`、`for-in` 分别需要哪些方法

顺序拼接只是 result builder 的第一步。DSL 真正有用，是因为闭包里还可以嵌入条件和循环。

#### 无 `else` 的 `if`：`buildOptional`

目标写法：

```swift
let showFooter = true

let lines = collect {
    "标题"
    if showFooter {
        "页脚"
    }
}
```

单边 `if` 的问题是：条件不成立时，这一段没有内容。builder 需要一个方法来把“可能不存在的一段”统一成内部组件：

```swift
extension LineBuilder {
    static func buildOptional(_ component: [String]?) -> [String] {
        component ?? []
    }
}
```

近似展开：

```swift
let part0 = LineBuilder.buildExpression("标题")

let part1: [String]
if showFooter {
    part1 = LineBuilder.buildOptional(
        LineBuilder.buildBlock(
            LineBuilder.buildExpression("页脚")
        )
    )
} else {
    part1 = LineBuilder.buildOptional(nil)
}

let result = LineBuilder.buildBlock(part0, part1)
```

这里最重要的是类型统一：无论条件成立还是不成立，`part1` 都是 `[String]`。

#### `if-else` 与 `switch`：`buildEither(first:)` / `buildEither(second:)`

目标写法：

```swift
let isAdmin = true

let lines = collect {
    "用户信息"
    if isAdmin {
        "管理员入口"
    } else {
        "普通用户入口"
    }
}
```

`if-else` 两边都有内容。builder 用一对 `buildEither` 承载“走了哪一支”：

```swift
extension LineBuilder {
    static func buildEither(first component: [String]) -> [String] {
        component
    }

    static func buildEither(second component: [String]) -> [String] {
        component
    }
}
```

近似展开：

```swift
let part0 = LineBuilder.buildExpression("用户信息")

let part1: [String]
if isAdmin {
    part1 = LineBuilder.buildEither(
        first: LineBuilder.buildBlock(
            LineBuilder.buildExpression("管理员入口")
        )
    )
} else {
    part1 = LineBuilder.buildEither(
        second: LineBuilder.buildBlock(
            LineBuilder.buildExpression("普通用户入口")
        )
    )
}

let result = LineBuilder.buildBlock(part0, part1)
```

`switch` 也走同一类机制。多分支通常会被转成嵌套的 `buildEither`。所以一个 builder 如果不实现这两个方法，就不能支持 `if-else` 和 `switch`。

#### `for-in`：`buildArray`

目标写法：

```swift
let names = ["A", "B", "C"]

let lines = collect {
    "名单"
    for name in names {
        "用户：\(name)"
    }
}
```

循环每一轮都会生成一个组件。编译器先把每轮结果收进数组，再交给 `buildArray`：

```swift
extension LineBuilder {
    static func buildArray(_ components: [[String]]) -> [String] {
        components.flatMap { $0 }
    }
}
```

近似展开：

```swift
let part0 = LineBuilder.buildExpression("名单")

var loopParts: [[String]] = []
for name in names {
    loopParts.append(
        LineBuilder.buildBlock(
            LineBuilder.buildExpression("用户：\(name)")
        )
    )
}
let part1 = LineBuilder.buildArray(loopParts)

let result = LineBuilder.buildBlock(part0, part1)
```

`buildArray` 是可选能力。不实现它，闭包体里就不能直接写 `for-in`。这有时是刻意设计：例如某些 UI DSL 不希望使用者随手写循环，而是提供带稳定身份的专用入口，这样后续 diff、缓存或增量更新更可控。

### 模块 5：一张表看完常用 `build*` 方法

到这里，result builder 的核心方法已经出现过了。下面这张表是之后读任何 builder 的速查表。

| 方法 | 对应语法 | 什么时候需要 |
| --- | --- | --- |
| `buildExpression(_:)` | 闭包体里的裸表达式 | 想控制哪些表达式可以写进 builder，或想把表达式统一成内部组件 |
| `buildBlock(_:)` | 同一层里按顺序写多段内容 | 最常用的合并入口；本章用它作为基础入口 |
| `buildOptional(_:)` | 没有 `else` 的 `if` | 想支持单边条件内容 |
| `buildEither(first:)` / `buildEither(second:)` | `if-else`、`switch` | 想支持二选一或多分支内容 |
| `buildArray(_:)` | `for-in` | 想支持在闭包体里循环生成内容 |
| `buildLimitedAvailability(_:)` | `if #available` | 想支持可用性判断 |
| `buildFinalResult(_:)` | 最外层结果收尾 | 内部组件类型和对外返回类型不同时 |

对应到一个通用骨架，可以写成这样：

```swift
@resultBuilder
enum MyBuilder {
    static func buildExpression(_ expression: Expression) -> Component {
        // 裸表达式 -> 内部组件
    }

    static func buildBlock(_ parts: Component...) -> Component {
        // 同一层顺序拼接
    }

    static func buildOptional(_ component: Component?) -> Component {
        // if 没走时，用 nil 表示“没有这一段”
    }

    static func buildEither(first component: Component) -> Component {
        // if-else / switch 的第一支
    }

    static func buildEither(second component: Component) -> Component {
        // if-else / switch 的第二支
    }

    static func buildArray(_ components: [Component]) -> Component {
        // for-in 的每轮结果合并
    }

    static func buildLimitedAvailability(_ component: Component) -> Component {
        // if #available 的分支合并
    }

    static func buildFinalResult(_ component: Component) -> Final {
        // 内部组件 -> 对外最终结果
    }
}
```

这不是说每个 builder 都必须实现所有方法。builder 的设计，本质上就是回答这些问题：

- 闭包体里允许写哪些裸表达式？
- 内部统一搬运的 `Component` 是什么？
- 要不要支持单边 `if`？
- 要不要支持 `if-else` / `switch`？
- 要不要支持 `for-in`？
- 最终结果是不是还要再包一层？

还有一个进阶方法族叫 `buildPartialBlock`，可以让编译器用增量方式合并组件，适合更复杂或更在意类型推断性能的 builder。本章先不使用它~~(怕你们听不懂)~~。对于入门和大多数自定义 DSL，先掌握上表这组方法就够了。

### 模块 6：把机制应用到 `HTMLBuilder`

有了前面的机制，现在可以实现本章的 mini HTML DSL。它和 `LineBuilder` 的差别不在语法规则，而在要表达的数据模型：文本行用 `[String]` 表示，HTML 子节点用 `[HTMLNode]` 表示。

#### 第一步：定义结果树的节点类型

HTML 不是一串字符串，而是一棵树：一个元素有标签名、属性和子节点；文本是叶子节点。

```swift
public enum HTMLNode {
    // 文本节点，例如 "Hello"。
    case text(String)

    // 元素节点，例如 <div>...</div>。
    // 三个值分别是：标签名、属性列表、子节点列表。
    indirect case element(String, [(String, String)], [HTMLNode])

    public func render(indent: Int = 0) -> String {
        // indent 表示当前节点在树里的层级。
        // 每深一层，就多两个空格，方便打印出层级结构。
        let indentation = String(repeating: "  ", count: indent)

        switch self {
        case .text(let content):
            return indentation + content

        case .element(let tag, let attrs, let children):
            // 先拼开始标签的前半部分，例如 "<a"。
            var openingTag = "<\(tag)"

            // 再把属性一个个接上去，例如 href="https://swift.org"。
            for (name, value) in attrs {
                openingTag += " \(name)=\"\(value)\""
            }

            if children.isEmpty {
                return indentation + openingTag + "/>"
            }

            // 有子节点时，递归渲染每个子节点。
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
```

`indirect` 是因为 `HTMLNode.element` 里又包含 `[HTMLNode]`。没有 `indirect`，这个 enum 会递归包含自己，Swift 无法确定大小。

#### 第二步：确定 builder 的内部组件

一个标签的 children 本质上是一组节点，所以我们让 `HTMLBuilder` 全程在 `[HTMLNode]` 上工作：

```swift
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
```

和 `LineBuilder` 对照一下：

| 角色 | `LineBuilder` | `HTMLBuilder` |
| --- | --- | --- |
| 裸表达式 | `String` | `HTMLNode` |
| 内部组件 | `[String]` | `[HTMLNode]` |
| 顺序拼接 | `flatMap` 字符串数组 | `flatMap` 节点数组 |
| 单边 `if` | 条件不成立返回 `[]` | 条件不成立返回 `[]` |
| `for-in` | `[[String]] -> [String]` | `[[HTMLNode]] -> [HTMLNode]` |

这个对照表说明了一点：`HTMLBuilder` 没有引入新的 Swift 语法。它沿用同一套 result builder 转写规则，只是把内部组件从 `[String]` 换成了 `[HTMLNode]`。

#### 第三步：标签函数只是普通函数

`html`、`body`、`div`、`p` 都只是普通函数。它们特殊的地方只有一个：children 闭包参数标了 `@HTMLBuilder`。

```swift
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

public func h1(@HTMLBuilder _ children: () -> [HTMLNode]) -> HTMLNode {
    element("h1", children: children)
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
```

所以：

```swift
div {
    h1 { text("Welcome") }
    p { text("Hello") }
}
```

不是因为 `div` 有什么特殊语言能力，而是因为 `div` 的闭包参数是：

```swift
@HTMLBuilder _ children: () -> [HTMLNode]
```

编译器看到这个标记，才会用 `HTMLBuilder` 转写闭包体。

### 模块 7：手写一次 HTML DSL 的展开形态

看下面这段：

```swift
func makePage(isAdmin: Bool, posts: [Post]) -> HTMLNode {
    body {
        if isAdmin {
            div {
                text("欢迎管理员")
            }
        } else {
            div {
                text("欢迎访客")
            }
        }
        for post in posts {
            article {
                h1 { text(post.title) }
                p { text(post.body) }
            }
        }
    }
}
```

先看最外层 `body { ... }`。`body` 的 children 参数是 `@HTMLBuilder`，所以闭包体会被转写。大致形态如下：

```swift
func makePage(isAdmin: Bool, posts: [Post]) -> HTMLNode {
    let part0: [HTMLNode]
    if isAdmin {
        part0 = HTMLBuilder.buildEither(
            first: HTMLBuilder.buildBlock(
                HTMLBuilder.buildExpression(
                    div {
                        text("欢迎管理员")
                    }
                )
            )
        )
    } else {
        part0 = HTMLBuilder.buildEither(
            second: HTMLBuilder.buildBlock(
                HTMLBuilder.buildExpression(
                    div {
                        text("欢迎访客")
                    }
                )
            )
        )
    }

    var loopParts: [[HTMLNode]] = []
    for post in posts {
        loopParts.append(
            HTMLBuilder.buildBlock(
                HTMLBuilder.buildExpression(
                    article {
                        h1 { text(post.title) }
                        p { text(post.body) }
                    }
                )
            )
        )
    }
    let part1 = HTMLBuilder.buildArray(loopParts)

    let children = HTMLBuilder.buildBlock(part0, part1)
    return .element("body", [], children)
}
```

注意这只是帮助理解的伪代码。真实编译器展开不会按这个变量名生成源代码，但调用关系可以这样理解。

再往里看，`div { text("欢迎管理员") }` 自己也会触发一轮 `HTMLBuilder`，因为 `div` 的 children 参数同样标了 `@HTMLBuilder`：

```swift
div {
    text("欢迎管理员")
}
```

大致等价于：

```swift
let children = HTMLBuilder.buildBlock(
    HTMLBuilder.buildExpression(text("欢迎管理员"))
)
let node = .element("div", [], children)
```

这就是嵌套 DSL 的本质：每个带 `@HTMLBuilder` 闭包参数的函数，都会在自己的闭包范围内触发一次 builder 转写。

### 模块 8：完整 demo 怎么运行

demo 在 `demos/projects/56-result-builders-and-mini-dsl`，是一个最小 Swift Package：

```text
56-result-builders-and-mini-dsl/
├─ Package.swift
├─ Sources/
│  ├─ HTMLDSL/
│  │  ├─ HTMLNode.swift
│  │  ├─ HTMLBuilder.swift
│  │  └─ Tags.swift
│  └─ HTMLDemo/
│     └─ main.swift
└─ Tests/
   └─ HTMLDSLTests/
      └─ HTMLDSLTests.swift
```

`HTMLDemo/main.swift` 里会构造一页小博客：

```swift
import Foundation
import HTMLDSL

let isAdmin = true
let posts = [
    Post(title: "Hello SwiftUI", body: "今天开始学 SwiftUI"),
    Post(title: "Result Builder", body: "原来 DSL 不神秘"),
]

let page = html {
    head {
        title { text("我的博客") }
    }
    body {
        if isAdmin {
            div {
                text("欢迎管理员")
            }
        } else {
            div {
                text("欢迎访客")
            }
        }
        for post in posts {
            article {
                h1 { text(post.title) }
                p { text(post.body) }
            }
        }
        p {
            a(href: "https://swift.org") {
                text("Learn more")
            }
        }
    }
}

print(page.render())
```

运行：

```bash
cd demos/projects/56-result-builders-and-mini-dsl
swift run HTMLDemo
```

测试：

```bash
swift test
```

测试会覆盖三件事：

- 顺序拼接：`text("a")`、`text("b")` 都进入结果
- `if-else`：不同条件走不同分支
- `for-in`：数组里的每个元素都展开成子节点

### 模块 9：常见编译错误应该怎么读

result builder 的编译错误有时看起来绕，但大多能按“缺了哪个转写入口”排查。

#### 错误 1：闭包体里写了不被支持的表达式

```swift
div {
    42
}
```

`HTMLBuilder` 只有这些入口：

```swift
buildExpression(_ node: HTMLNode)
buildExpression(_ nodes: [HTMLNode])
```

`42` 是 `Int`，没有任何 `buildExpression` 能把它接成 `[HTMLNode]`，所以会报类型错误。

#### 错误 2：写了单边 `if`，但 builder 没有 `buildOptional`

```swift
div {
    if showBanner {
        p { text("banner") }
    }
}
```

如果 `HTMLBuilder` 没有 `buildOptional(_:)`，编译器不知道条件不成立时该给这一段什么组件。要么实现 `buildOptional`，要么不要支持这种写法。

#### 错误 3：写了 `if-else` 或 `switch`，但没有 `buildEither`

```swift
div {
    if isAdmin {
        text("admin")
    } else {
        text("guest")
    }
}
```

这需要 `buildEither(first:)` 和 `buildEither(second:)` 成对存在。只实现其中一个没有意义。

#### 错误 4：写了 `for-in`，但没有 `buildArray`

```swift
div {
    for tag in tags {
        p { text(tag) }
    }
}
```

如果 builder 没实现 `buildArray`，这段不能编译。要不要支持循环是设计选择，不是所有 DSL 都应该支持。

#### 错误 5：显式写了 `return`

```swift
div {
    return p { text("Hello") }
}
```

result builder 闭包体里通常不要写 `return`。显式 `return` 会阻止编译器按 builder 规则解释后续语句。让每一行保持表达式即可。

#### 关于 `let` / `var`

现代 Swift 允许在 result builder 闭包里写局部声明：

```swift
div {
    let name = "Swift"
    p { text(name) }
}
```

`let name = "Swift"` 只是声明，不会变成一个 HTML 节点，也不会传给 `buildExpression`。真正产生组件的是后面的 `p { ... }`。因此读 builder 代码时，要分清“辅助声明”和“会进入结果的表达式”。

### 模块 10：什么时候不该用 result builder

result builder 很适合描述“有嵌套、有顺序、有条件、有重复”的结构，但不适合所有 API。

#### 1. 只是组装一个普通对象

```swift
let user = User(name: "Tim", age: 30)
```

这种写法已经足够清楚。没必要为了“看起来像 DSL”而做成：

```swift
@UserBuilder
var user: User {
    Name("Tim")
    Age(30)
}
```

如果没有嵌套、条件、循环这些结构收益，普通初始化器通常更直接。

#### 2. 闭包体里要混很多不相关类型

```swift
@MyBuilder
func mixed() -> Something {
    "string"
    42
    User(name: "x")
}
```

这会迫使你给 `buildExpression` 写很多重载，或者把内部组件做成 `any` / enum 包装。除非这些类型在领域模型里确实是一类东西，否则 builder 只会让 API 更难读。

#### 3. 团队必须查实现才能懂语义

```swift
@RouteBuilder
var routes: Routes {
    GET("/users")
    POST("/users")
}
```

这类 API 是否值得做成 builder，要看它有没有显著降低阅读成本。如果团队成员看到这种 DSL 以后还必须跳进 builder 实现才能知道发生了什么，普通数组往往更好：

```swift
let routes = [
    GET("/users"),
    POST("/users"),
]
```

result builder 的目标不是让代码“看起来高级”，而是让有层级结构的代码更接近问题本身。

### 模块 11：工程设计经验

写自己的 result builder 时，先定这几个点：

- **先定内部组件类型**：本章的 `HTMLBuilder` 用 `[HTMLNode]`，所以所有方法都围绕 `[HTMLNode]` 拼接
- **用 `buildExpression` 收窄入口**：只允许领域内合法表达式进入 builder，错误越早越好
- **不要默认支持所有语法**：`buildArray`、`buildEither` 都是能力开关；不需要就不要实现
- **保持返回类型简单**：内部组件和最终结果能相同就先相同；需要对外包一层时再加 `buildFinalResult`
- **错误信息会暴露设计质量**：如果使用者经常看到很难理解的类型错误，说明 builder 的重载边界可能太松或太复杂

判断一个 builder 是否设计得好，可以问一句：

> 使用者能不能只看这段 DSL 代码就知道它在构造什么结构？

如果答案是否定的，说明这个 DSL 可能只是把普通代码藏了起来，并没有提升表达力。

## 小结

这一章先建立 result builder 的来源与机制，再把它应用到一个 mini HTML DSL：

- 普通闭包不会自动收集多条表达式
- `@resultBuilder` 标记的类型提供一组编译期转写入口
- 闭包参数上的 `@SomeBuilder` 决定闭包体要用哪套规则解释
- `buildExpression` 接住裸表达式，`buildBlock` 拼同层顺序，`buildOptional` 处理单边 `if`，`buildEither` 处理分支，`buildArray` 处理循环
- 具体到本章的 `HTMLBuilder`，内部组件是 `[HTMLNode]`，最终拼出的是一棵 HTML 节点树

读任何 result builder DSL 时，都按这条线看：

1. 找闭包参数上的 `@XxxBuilder`
2. 找 builder 类型里的 `build*` 方法
3. 判断每条语句是裸表达式、分支、循环还是嵌套闭包
4. 把它们还原成组件拼接

下一章会进入三个高频工程话题：KeyPath、`Identifiable` 与 `@MainActor`。

## 练习

动手写代码的 starter 工程在 `exercises/zh-CN/projects/56-result-builders-and-mini-dsl-starter`；写完想对答案，参考实现与逐题讲解在 `exercises/zh-CN/answers/56-result-builders-and-mini-dsl.md`。

### 任务 1：实现 `MenuBuilder`

从零做一个描述命令行菜单的 DSL，让下面这段代码能编译运行：

```swift
let m = menu(title: "主菜单") {
    item("新建文件")
    item("打开文件")
    if isPro {
        item("导出 PDF")
    } else {
        item("升级到 Pro")
    }
    for name in recentFiles {
        item("最近：\(name)")
    }
    submenu(title: "设置") {
        item("外观")
        item("快捷键")
    }
}

print(m.render())
```

你要交付四样东西：

1. 一个 `MenuNode` 类型，至少能表达 `item`（菜单项）与 `submenu`（子菜单）两类；
2. 一个 `@resultBuilder MenuBuilder`，支持顺序拼接、单边 `if`、`if-else`、`for-in`，也就是要实现 `buildExpression` / `buildBlock` / `buildOptional` / `buildEither(first:)` / `buildEither(second:)` / `buildArray`；
3. `menu(title:_:)` / `submenu(title:_:)` / `item(_:)` 三个函数，其中 `menu` 与 `submenu` 的闭包参数都要标 `@MenuBuilder`；
4. 一个 `render()` 方法，把菜单按层级缩进打印成文本。

提示：让 builder 全程在 `[MenuNode]` 上工作。`buildExpression` 接单节点和节点数组各写一个重载，其余 `build*` 方法就能类型统一地拼接；`menu` 和 `submenu` 可以共用同一个 `MenuNode.submenu` case，省一个类型。

### 任务 2：读一段 DSL，写出它的展开形态

下面这段代码用本章的 `HTMLBuilder` 写成，闭包体里同时出现了“顺序 + `if/else` + `for-in`”三种结构：

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

请完成两件事：

1. 手写出 `div { ... }` 这个闭包体被编译器改写成一连串 `build*` 方法调用后的大致形态（伪代码即可），并用一张表列出每个语法结构（裸表达式 / 顺序拼接 / `if-else` / `for-in`）各对应哪个 `build*` 方法；
2. 顺带想一个问题：一个 result builder 到底该不该实现 `buildArray`？实现了能让闭包体直接写 `for-in`，不实现又是出于什么考量？把结论写下来。

提示：抓住一条主线：本章的 `HTMLBuilder` 全程在同一种累加类型（`[HTMLNode]`）上工作。顺着“每个语法结构进来时，编译器需要调哪个方法把它并入这条累加流”去推，对照模块 5 的 `build*` 方法表逐个套即可。starter 工程里给的是一段等价的 `MenuBuilder` 版本（`makeMenu(isPro:recent:)`），结构完全一样，用哪个 builder 来分析都行。
