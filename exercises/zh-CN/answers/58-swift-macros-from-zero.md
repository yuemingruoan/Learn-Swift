# 58. Swift 宏入门 练习答案

对应章节：

- [58. Swift 宏入门：读懂展开、写一个最小 freestanding 宏](../../../docs/zh-CN/chapters/58-swift-macros-from-zero.md)

如果你想一边看答案一边运行 starter project，可以打开：

- `exercises/zh-CN/projects/58-swift-macros-from-zero-starter`

如果你想直接运行本章练习的参考工程，也可以打开：

- `exercises/zh-CN/answers/58-swift-macros-from-zero`

说明：

- 每道题的**完整描述**在教程正文的「练习」一节：[58. Swift 宏入门](../../../docs/zh-CN/chapters/58-swift-macros-from-zero.md#练习)。这里只放参考实现与逐题讲解。
- 本章练习包含一道阅读题（读 `@Observable` 的展开）、一道动手题（写一个 `#URL` 宏）和一道判断题
- 动手题难度比前几章大一截：你得同时熟悉 SwiftSyntax 的 API、宏的工程结构、宏的报错方式
- 第一次跑会拉 swift-syntax 并整体编译，**慢得不寻常**（首次可能 1~3 分钟），但只是首次

## 任务 1：阅读 `@Observable` 的展开（开放题）

> 把一段 `@Observable` 代码 Expand Macro 展开，挑两个生成的成员逐行注释。（完整描述见正文）

### 一个参考样本

原代码：

```swift
import Observation

@Observable
final class Counter {
    var value: Int = 0
}
```

Xcode → Expand Macro 后（节选）：

```swift
@Observable
final class Counter {
    @ObservationTracked
    var value: Int {
        get {
            access(keyPath: \.value)
            return _value
        }
        set {
            withMutation(keyPath: \.value) {
                _value = newValue
            }
        }
    }

    @ObservationIgnored private var _value: Int = 0
    @ObservationIgnored private let _$observationRegistrar = ObservationRegistrar()

    internal nonisolated func access<Member>(
        keyPath: KeyPath<Counter, Member>
    ) {
        _$observationRegistrar.access(self, keyPath: keyPath)
    }

    internal nonisolated func withMutation<Member, MutationResult>(
        keyPath: KeyPath<Counter, Member>,
        _ mutation: () throws -> MutationResult
    ) rethrows -> MutationResult {
        try _$observationRegistrar.withMutation(of: self, keyPath: keyPath, mutation)
    }
}

extension Counter: Observable {}
```

### 选两段逐行注释的样例

**样本 1：被改写的 `value` 属性**

```swift
@ObservationTracked
var value: Int {
    get {
        // 1. 通知 registrar："有人正在读 value"
        //    观察者在读取属性的过程里会途经 access 这一步，
        //    registrar 拿到这个调用就能记下"当前观察者依赖 value"
        access(keyPath: \.value)

        // 2. 真正的取值——读底层存储 _value
        return _value
    }
    set {
        // 1. 进入"我要写 value 了"的事务
        //    registrar 会在闭包结束时通知所有"依赖 value 的观察者"
        withMutation(keyPath: \.value) {
            // 2. 写入底层存储 _value
            _value = newValue
        }
    }
}
```

读后写出来的洞察：

- 原来你写的 `var value: Int = 0` 被一分为二——对外的 `value` 变成计算属性，真正的存储变成隐藏的 `_value`
- 观察者不需要"额外监听"——它在读取 `value` 的过程里就被 `access(keyPath:)` 顺手记录了依赖
- 一切是显式的 Swift 代码，没有 KVO、没有 runtime swizzling

**样本 2：`_$observationRegistrar`**

```swift
@ObservationIgnored
private let _$observationRegistrar = ObservationRegistrar()
```

- `@ObservationIgnored`：告诉 `@Observable` 宏在展开时**别**把这个成员当作被追踪的属性，否则会陷入"追踪自己追踪自己"的递归
- `private`：完全是这个对象内部细节，外部不应该看到
- `_$` 前缀：Swift 标准库 / 框架代码里用来约定"框架生成的、用户不要碰"的成员名。这是个约定，不是语言规则
- `ObservationRegistrar`：来自 `Observation` 框架，是真正负责"谁依赖谁、谁该被通知"的中枢

### 你应当能回答的问题

- 为什么 `@Observable` 不能加在 struct 上？（生成的 `withMutation` 闭包需要捕获 `self` 并修改，struct 的 `self` 默认不可变；`@Observable` 的实现是按 class 设计的）
- 为什么 `let` 属性不能被 `@Observable` 追踪？（生成的代码要改写 setter，`let` 没有 setter）
- 改写后，观察者怎么知道自己依赖某个属性？（读取属性时调到 `access(keyPath:)`，registrar 把"当前观察者"和"keyPath"建立映射，之后该属性一变就能反过来通知到它）

## 任务 2：写一个 `#URL` 宏

> 写一个 freestanding 宏 `#URL`，编译期校验 URL：合法展开为 `URL(string:)!`，非字面量 / 不合法则报编译错误。（完整描述见正文）

### 完整参考实现

**`Sources/URLKit/URLKit.swift`** —— 对外声明：

```swift
import Foundation

@freestanding(expression)
public macro URL(_ string: String) -> URL =
    #externalMacro(module: "URLKitMacros", type: "URLMacro")
```

**`Sources/URLKitMacros/URLMacro.swift`** —— 实现：

```swift
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
```

**`Sources/URLKitMacros/Plugin.swift`** —— 注册：

```swift
import SwiftCompilerPlugin
import SwiftSyntaxMacros

@main
struct URLKitPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        URLMacro.self,
    ]
}
```

### 解题点评

#### `StringLiteralExprSyntax.segments` 为什么不能直接当字符串

字符串字面量在 SwiftSyntax 里被切成片段（segments）：

- 普通文本片段：`.stringSegment(...)`
- 插值片段：`.expressionSegment(...)`，对应 `"hello \(name)"` 里的 `\(name)`

我们这里要求"必须是字面量"，所以应当拒绝带插值的写法（`#URL("https://\(host)")`）。判断方式：

- `literal.segments.count == 1`：只有一段
- `case let .stringSegment(segment) = literal.segments.first`：而且这一段必须是纯文本

这两条同时满足，才取 `segment.content.text` 拿到字符串内容。

#### 为什么是 `throw` 而不是返回错误

`ExpressionMacro.expansion` 标了 `throws`。在宏里抛错的语义是：**给编译器报告一个 diagnostic，并且不生成任何代码**。结果就是调用方编译失败、错误信息带着我们 `URLMacroError.description` 那段中文。这正是我们想要的。

> 进阶做法：用 `DiagnosticsError` + `MacroExpansionDiagnosticMessage` 可以同时附带位置、fix-it。这里为了简洁，直接 throw 自定义 error 就够用。

#### `\(literal: text)` 这个写法

SwiftSyntax 重载了字符串插值，让你能直接在字符串里塞语法树。`\(literal:)` 这个 spelling 表示"把 Swift 的 String 值变成字符串字面量节点"。也就是说：

```swift
let text = "https://example.com"
let expr: ExprSyntax = "URL(string: \(literal: text))!"
// expr ≡ URL(string: "https://example.com")!
```

`literal:` 会替你处理转义。如果你写成 `"URL(string: \"\(text)\")!"`，遇到 text 里本身带引号就崩。**永远走 `\(literal:)`**。

### 测试样例

完整 `URLMacroTests.swift`：

```swift
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest
@testable import URLKitMacros

final class URLMacroTests: XCTestCase {
    private let macros: [String: Macro.Type] = [
        "URL": URLMacro.self,
    ]

    func test_合法_URL_字面量展开为_URL_string_unwrap() {
        assertMacroExpansion(
            #"""
            let u = #URL("https://example.com")
            """#,
            expandedSource: #"""
            let u = URL(string: "https://example.com")!
            """#,
            macros: macros
        )
    }

    func test_非字符串字面量参数应当报错() {
        assertMacroExpansion(
            #"""
            let s = "https://example.com"
            let u = #URL(s)
            """#,
            expandedSource: #"""
            let s = "https://example.com"
            let u = #URL(s)
            """#,
            diagnostics: [
                DiagnosticSpec(message: "#URL 的参数必须是字符串字面量", line: 2, column: 9),
            ],
            macros: macros
        )
    }

    func test_不合法_URL_应当报错() {
        assertMacroExpansion(
            #"""
            let u = #URL(" ")
            """#,
            expandedSource: #"""
            let u = #URL(" ")
            """#,
            diagnostics: [
                DiagnosticSpec(message: "不是合法的 URL： ", line: 1, column: 9),
            ],
            macros: macros
        )
    }
}
```

要点：

- `assertMacroExpansion` 同时支持验证 `expandedSource`（成功时）和 `diagnostics`（失败时）
- diagnostic 测试里 `expandedSource` 写成"和原始代码一致"——因为宏抛错时不生成新代码
- `line/column` 是 1-based，指向 `#URL` 这一段开始的位置

### 工程上的真实价值

`#URL` 看起来很玩具，但它代表一类**"用编译期校验代替运行时崩溃"**的实用模式：

- 你的代码库里有多少处 `URL(string: "...")!`？每一处都是个运行时炸弹
- 改成 `#URL("...")` 后，链接拼错的那一刻**编译器就报错**，比 QA 在运行时发现要省事得多
- 类似的还有：`#Predicate`（编译期校验 NSPredicate 字符串）、`#Selector`（编译期匹配 OC selector）

记一句："**能在编译期发现的错误，绝不留到运行时**。"宏的工程价值就在这一条上。

## 任务 3（思考题）：函数 / 协议扩展 / 属性包装器 / 宏，分别用在哪？

> 三个需求各该用「函数 / 协议扩展 / 属性包装器 / 宏」中的哪个？为什么？（完整描述见正文）

### 参考答案

#### 需求 1：限制 Double 在 0~100 → **属性包装器**

- 这是"对单个属性的存取行为做包装"，正是 property wrapper 的本职工作
- 第 55 章我们已经实现过 `@Clamped`。直接用 `@Clamped(0...100) var score: Double`
- 不需要宏：宏的优势是"批量生成成员"，这里只针对一个属性
- 不需要函数 / 扩展：函数没法干预存取；扩展不能加存储属性

#### 需求 2：自动 `Equatable`，比较所有存储属性 → **宏**

- Swift 已经替 struct 做了"自动 `Equatable`"的合成，但对 class **不会**自动合成
- 想给 class 做这件事，需要遍历所有存储属性、生成 `static func == (lhs, rhs) -> Bool { lhs.a == rhs.a && lhs.b == rhs.b && ... }`
- 这正好是宏擅长的：**attached macro**，role 用 `@attached(extension, conformances: Equatable, names: named(==))`，在编译期生成 `extension Foo: Equatable { static func == ... }`
- 不能用属性包装器：包装器是属性级别的，没办法"看到所有属性"
- 不能用协议扩展：协议扩展给不出对所有存储属性的逐项比较；它没法访问"未知类型的存储属性列表"
- 不能只靠函数：调用方需要的是 `Equatable` 协议遵从，而不是一个 `equalsBy(...)` 函数

#### 需求 3：把 Date 格式化成 `yyyy-MM-dd` → **普通函数 / 协议扩展**

- 这就是一个纯函数：输入 Date，输出 String，没有任何"修改成员、改写存取、生成代码"的需求
- 写成普通 `func formatDate(_ d: Date) -> String` 或 `extension Date { var yyyyMMdd: String { ... } }` 都很自然
- **不要为这种事用宏**。宏会让编译变慢、调试变难，零收益

### 一个判断口诀

按"想做的事"的形状选：

| 想做的事 | 工具 |
| --- | --- |
| 一个输入 → 一个输出，没有状态变化 | 普通函数 |
| 给类型加方法、加默认实现 | 协议扩展 |
| 给单个属性的存取加规则 | 属性包装器 |
| 给类型批量生成成员、协议遵从、配套 extension | 宏 |

**永远先考虑前三个，最后才轮到宏**。宏的开发成本和编译成本都不低，没必要时不要上。

## 自检清单

完成本章练习后，你应当能脱口回答：

- 宏和属性包装器分别在哪个时机做事？输出形态分别是什么？
- freestanding macro 和 attached macro 在写法上、能改的东西上分别有什么区别？
- `@Observable` 大致生成了哪些代码？为什么观察者不需要"额外监听"就能知道自己依赖哪个属性？
- 用宏抛编译错误的写法是什么？为什么 `\(literal:)` 比手写字符串拼接安全？
- 什么时候该用宏，什么时候不要？

如果其中任意一条不能立刻回答出来，建议回到正文相应模块再读一遍。

## 后记：这几章串起来看

到这里，Swift 语言里几个偏进阶、偏框架底层的特性就都讲完了。回头看，这几章其实是一条线：

- 第 54 章：`some` / `associatedtype` —— 不暴露具体类型，又能保留类型信息地"返回一个满足某协议的东西"
- 第 55 章：属性包装器 —— 把"对某个属性存取行为的规则"封装成可复用的 `@xxx`
- 第 56 章：result builder —— 把一段普通写法的代码块，在编译期翻译成一串 `buildBlock` / `buildEither` 调用，做出声明式的 mini-DSL
- 第 57 章：KeyPath / `Identifiable` / `@MainActor` —— 把"指向某个属性的路径"当值传递、给元素稳定身份、把代码钉在主线程
- 本章：宏 —— 在编译期直接生成源码，`@Observable` 就是个活生生的例子

这些特性单看都偏底层，但它们正是很多声明式框架和库赖以运转的地基。打好这层底子，之后再去读那些"看起来很魔法"的 API，你都能把它拆回到这几章讲过的机制上。
