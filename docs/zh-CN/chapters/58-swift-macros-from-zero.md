# 58. Swift 宏入门：读懂展开、写一个最小 freestanding 宏

## 阅读导航

- 前置章节：[21. 协议：灵活的抽象](./21-protocols-flexible-abstraction.md)、[24. 泛型：可复用的抽象](./24-generics-reusable-abstractions.md)、[53. Swift Package Manager 工程化入门](./53-swift-package-manager-from-multi-file-to-multi-module.md)、[55. 属性包装器原理：从零实现一个 `@propertyWrapper`](./55-property-wrappers-from-zero.md)
- 上一章：[57. KeyPath、`Identifiable` 与 `@MainActor`：三个高频工程话题](./57-keypath-identifiable-and-mainactor.md)
- 下一章：进入 SwiftUI 主线（章号待定）
- 适合谁读：已经理解协议、泛型、属性包装器，看到 `@Observable`、`#Preview` 这些 `@` 或 `#` 开头的标记，知道"是某种生成代码的东西"，但还说不清它们和属性包装器、和编译期的关系的读者

## 本章目标

学完这一章后，你应该能够：

- 区分 Swift 宏与属性包装器、与运行时反射各自的边界
- 区分两类宏：以 `#` 开头的 freestanding macro 与以 `@` 开头的 attached macro
- 在 Xcode 中"看见"一个宏的展开结果（Editor → Expand Macro）
- 解释一个宏在编译期做了什么、不做什么（没有运行时代价）
- 读懂 `@Observable` 展开后大致生成了哪些代码
- 用 Swift Macro Package 模板，写出一个最小的 freestanding 宏：`#stringify(x)` 把表达式转成 `(value, "源代码")`
- 判断一段需求应该用宏、属性包装器，还是普通函数 / 协议扩展

## 本章对应资源

- 文稿：`docs/zh-CN/chapters/58-swift-macros-from-zero.md`
- 示例项目：`demos/projects/58-swift-macros-from-zero`
- 练习答案：`exercises/zh-CN/answers/58-swift-macros-from-zero.md`
- 练习 starter：`exercises/zh-CN/projects/58-swift-macros-from-zero-starter`

## 本章怎么读

建议阅读顺序：

1. 先把"宏是什么"和"宏不是什么"读完，避免一开始就钻语法
2. 再用 Xcode 把 `@Observable` 展开看一眼，建立"宏会真的生成 Swift 源码"的直觉
3. 然后跟着写一个 `#stringify`，体会 freestanding 宏的最小流程
4. 最后回看 `@Observable` 的生成结果，能逐行解释每一段代码是怎么来的

## 正文主体

### 模块 0：为什么值得专门学宏

你大概率已经在各种代码里见过一堆 `@` 和 `#` 开头的标记：`@Observable`、`#Preview`、`#warning(...)`、`#Predicate(...)` ……它们看起来像普通的属性或函数调用，但行为又很怪——贴上去之后，类型凭空多出了成员，或者一行调用在编译时就报了错。

这些标记里有相当一部分其实都是**宏**。`@Observable` 就是一个典型：它不是属性包装器，不是协议默认实现，也不是运行时魔法——它是一个**宏**。本章我们会把它当成"真实世界的宏长什么样"的核心范例反复剖析。

如果不先把"宏在做什么"讲清楚，会出现两种典型痛点：

- 看到 `@Observable class Counter { var value: Int }` 能跑通，但完全说不清它到底替你生成了什么、那些凭空冒出来的成员是从哪来的
- 一旦展开后报错（比如属性写成 `let` 或者 `static`），错误信息会指向你**没有写**的代码，调试时一头雾水

学完这一章，你会对 `@Observable` 之类的"魔法标签"建立一个稳定的工程心智：它就是个**编译期代码生成器**，输入是你的源码，输出还是 Swift 源码，没有运行时新东西。`@Observable` 也是你之后会高频遇到的一个宏，本章把它彻底看穿，以后再碰到就不慌了。

### 模块 1：宏是什么、不是什么

#### 是什么

- 编译期对源码进行变换的程序
- 输入是 Swift 语法树（AST），输出还是 Swift 源码（也是语法树）
- 完全发生在编译期，运行时不存在"宏"这个对象
- 用 Xcode → Editor → Expand Macro 可以**真的看见**展开后的代码

可以把它理解为："你写 1 行，编译器替你写 50 行，编译器最后编译的是这 50 行。"

#### 不是什么

宏经常被混淆成下面几样东西。要先把它们划清楚：

| 你以为它是 | 实际上它不是 |
| --- | --- |
| C / Objective-C 那种文本宏 `#define` | 不是。Swift 宏在 AST 层面工作，不是字符串拼接，有类型检查 |
| 属性包装器 `@propertyWrapper` | 不是。属性包装器在**运行时**用一个 wrapper 实例包住值；宏在**编译期**生成代码 |
| Mirror 反射 / KVC | 不是。反射读取运行时类型；宏什么时候都不运行 |
| 在运行时生成新类型的元编程 | 不是。Swift 宏不能在运行时凭空造类型 |

记一句话："**宏 = 自动写代码的小程序，跑在编译期**。"

#### 宏 vs 属性包装器：什么时候用哪个

第 55 章我们已经写过 `@Clamped`、`@Trimmed`。它们和 `@Observable` 看起来都是"在属性上贴个 `@xxx`"，但底层完全不同。

| 维度 | 属性包装器 | 宏 |
| --- | --- | --- |
| 出现时机 | 运行时 | 编译期 |
| 实现形态 | 一个 struct / class，有 `wrappedValue` | 一个独立的 macro target，操作语法树 |
| 能改变什么 | 单个属性的 get/set 行为 | 几乎一切：加属性、加方法、加协议遵从、加 extension |
| 是否有运行时代价 | 有（wrapper 实例存在） | 无（生成的是普通源代码） |
| 上手成本 | 低 | 中-高，需要 SwiftSyntax |

工程上的简单判断：

- 只想改一个属性的存取行为：用属性包装器
- 要给一个类型批量生成成员、遵从协议、配套 extension：用宏

### 模块 2：两类宏 —— `#` 与 `@`

宏按调用形式分两大类。

#### Freestanding macro：`#name(args)`

写法是 `#` 开头，作为一个表达式 / 声明 / 代码块出现。例子：

```swift
#warning("这里还没实现")        // 声明型 freestanding
let pair = #stringify(1 + 2)     // 表达式型 freestanding
```

它会**就地展开**成一段代码（`#warning(...)` 会在编译期就地产生一条警告，`#stringify(...)` 则就地变成一段表达式）。除了 `#warning`，你之后还会见到别的 `#` 宏，比如 `#Preview`，原理都一样——都是 `#` 打头、就地展开。

#### Attached macro：`@name`

写法是 `@` 开头，**贴在一个声明上**，可以扩展那个声明本身。例子：

```swift
@Observable
final class Counter {
    var value = 0
}
```

它**不会替换原声明**，而是给原声明追加内容：协议遵从、新的成员、改写后的属性、配套 extension。

#### 角色（role）

Swift 编译器需要知道"这个宏到底在做什么"，所以每个宏在声明时会绑定一个或多个 *role*：

- `@freestanding(expression)`：作为表达式出现，例如 `#stringify`
- `@freestanding(declaration)`：作为声明出现，例如 `#warning`
- `@attached(member)`：给目标类型加成员
- `@attached(accessor)`：给目标属性改 getter/setter
- `@attached(extension)`：给目标类型生成 extension
- `@attached(memberAttribute)`：给目标类型的成员加 attribute
- `@attached(peer)`：在目标声明旁边生成"同级"声明

`@Observable` 就是同时声明了 `member`、`memberAttribute`、`extension` 三个角色——所以它能既加成员，又改成员的 attribute，还生成 extension。

不需要现在记牢这张表。本章只动手写一个 `@freestanding(expression)` 的 `#stringify`，剩下的角色看到就知道"它能改什么"就够。

### 模块 3：用 Xcode 看一眼 `@Observable` 的展开

在写自己的宏之前，先做一件事：让宏从"听起来很玄"变成"我亲眼看过它生成的代码"。

#### 步骤

1. 在 Xcode 里新建一个 iOS / macOS 工程，目标 iOS 17+ / macOS 14+
2. 加一段：

```swift
import Observation

@Observable
final class Counter {
    var value: Int = 0
    var name: String = ""
}
```

3. 把光标放在 `@Observable` 这个标签上，**右键 → Expand Macro**（或 Editor → Expand Macro）

#### 你会看到类似这样的东西（节选 / 简化）

```swift
@Observable
final class Counter {
    @ObservationTracked
    var value: Int = 0
    @ObservationTracked
    var name: String = ""

    @ObservationIgnored private let _$observationRegistrar = ObservationRegistrar()

    internal nonisolated func access<Member>(
        keyPath: KeyPath<Counter, Member>
    ) { _$observationRegistrar.access(self, keyPath: keyPath) }

    internal nonisolated func withMutation<Member, MutationResult>(
        keyPath: KeyPath<Counter, Member>,
        _ mutation: () throws -> MutationResult
    ) rethrows -> MutationResult {
        try _$observationRegistrar.withMutation(of: self, keyPath: keyPath, mutation)
    }
}

extension Counter: Observable {}
```

而 `@ObservationTracked` 又是一个宏，继续展开 `value` 这个属性：

```swift
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
```

#### 你应该立刻意识到几件事

- `@Observable` **不是**给 `Counter` 加了一个隐形的"代理对象"，它就是**真的把 getter/setter 改写了**。生成的代码就在那里
- 每次读 `value`，都会调一次 `access(keyPath:)`，向 registrar 报告"有人读了这个属性"——任何观察这个对象的系统都能借此记录下"谁依赖了哪个属性"
- 每次写 `value`，都会通过 `withMutation(keyPath:)` 通知 registrar："这个属性被改了"，registrar 再去通知那些登记过依赖的观察者
- `_$observationRegistrar` 是真正干活的人。`@Observable` 只是把"接线工作"代劳了

这一段没有任何"魔法"。换你自己也能手写——只是没人愿意每个 class 都手写一遍。这就是宏存在的理由。

> 工程提示：当 `@Observable` 报错"only stored properties can be tracked"之类，意思是它在展开时遇到了它不能处理的成员形态（比如 `let`、`static`、computed property）。此时**右键 Expand Macro** 看一眼展开结果，比对着报错原文猜要快得多。

### 模块 4：宏所在的工程结构

宏不是普通源文件能直接写的。它需要单独的 target，依赖 `swift-syntax`。

一个最小可用的 macro package 由三个 target 组成：

```
SwiftMacrosFromZero/
├── Package.swift
└── Sources/
    ├── MacrosKitMacros/     ← target type: .macro
    │   ├── Plugin.swift
    │   └── StringifyMacro.swift
    ├── MacrosKit/           ← target type: .target（library）
    │   └── MacrosKit.swift  ← 对外声明 `#stringify` 这个宏名
    └── MacrosDemo/          ← target type: .executableTarget
        └── main.swift       ← 真正调用 #stringify
```

各 target 的职责：

- **`MacrosKitMacros`**：宏的**实现**。它依赖 SwiftSyntax，是个编译器插件（`.macro` target），编译产物是个**编译期可执行体**，不会进入 App 二进制
- **`MacrosKit`**：宏的**对外声明**。这里写一行 `@freestanding(expression) public macro stringify<T>(_ value: T) -> (T, String) = #externalMacro(module: "MacrosKitMacros", type: "StringifyMacro")`。这是给使用者用的"门面"
- **`MacrosDemo`**：使用者。`import MacrosKit` 之后就能用 `#stringify(1 + 2)`

如果你看 Xcode 自带的 "Swift Macro" package 模板，结构和上面完全一致，只是名字不同。

### 模块 5：写一个最小的 freestanding 宏 —— `#stringify`

目标：

```swift
#stringify(1 + 2)
// 展开为 (1 + 2, "1 + 2")
```

也就是说，调用方写 `1 + 2`，宏在编译期既保留这个表达式的**计算结果**，又把它的**源码文本**当字符串带出来。

#### `Package.swift`

```swift
// swift-tools-version: 6.0
import PackageDescription
import CompilerPluginSupport

let package = Package(
    name: "SwiftMacrosFromZero",
    platforms: [.macOS(.v13)],
    products: [
        .library(name: "MacrosKit", targets: ["MacrosKit"]),
        .executable(name: "MacrosDemo", targets: ["MacrosDemo"]),
    ],
    dependencies: [
        .package(url: "https://github.com/swiftlang/swift-syntax.git", from: "600.0.0"),
    ],
    targets: [
        .macro(
            name: "MacrosKitMacros",
            dependencies: [
                .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
                .product(name: "SwiftCompilerPlugin", package: "swift-syntax"),
            ]
        ),
        .target(name: "MacrosKit", dependencies: ["MacrosKitMacros"]),
        .executableTarget(name: "MacrosDemo", dependencies: ["MacrosKit"]),
        .testTarget(
            name: "MacrosKitTests",
            dependencies: [
                "MacrosKitMacros",
                .product(name: "SwiftSyntaxMacrosTestSupport", package: "swift-syntax"),
            ]
        ),
    ]
)
```

注意：

- 必须 `import CompilerPluginSupport`，否则 `.macro(...)` 这个 target 类型不可用
- `swift-syntax` 是 Swift 官方的 AST 库，宏的实现完全建立在它之上
- `.macro` 的依赖里至少要有 `SwiftSyntaxMacros` 和 `SwiftCompilerPlugin`

#### 宏的对外声明 —— `MacrosKit.swift`

```swift
@freestanding(expression)
public macro stringify<T>(_ value: T) -> (T, String) =
    #externalMacro(module: "MacrosKitMacros", type: "StringifyMacro")
```

读这一行的姿势：

- `@freestanding(expression)`：这是一个 freestanding 宏，作为表达式出现
- `macro stringify<T>(_ value: T) -> (T, String)`：宏名、参数、返回类型——**就像声明一个泛型函数**
- `= #externalMacro(module: ..., type: ...)`：告诉编译器"真正的实现在哪个 module、哪个类型里"

这一行就是使用者唯一会接触的东西。它甚至连 `func` 都不是——`macro` 是个独立关键字。

#### 宏的实现 —— `StringifyMacro.swift`

```swift
import SwiftSyntax
import SwiftSyntaxMacros

public struct StringifyMacro: ExpressionMacro {
    public static func expansion(
        of node: some FreestandingMacroExpansionSyntax,
        in context: some MacroExpansionContext
    ) -> ExprSyntax {
        guard let argument = node.arguments.first?.expression else {
            fatalError("compiler bug: missing argument")
        }
        return "(\(argument), \(literal: argument.description))"
    }
}
```

逐行读：

- `ExpressionMacro` 协议：表达 freestanding-expression 宏必须遵从的协议，只有 `expansion(of:in:)` 一个方法
- `node` 是宏调用本身的语法树，例如 `#stringify(1 + 2)` 整体
- `node.arguments.first?.expression` 取第一个参数对应的语法节点（即 `1 + 2` 这个表达式）
- 返回类型 `ExprSyntax` 代表"展开后填入的表达式语法树"
- `"(\(argument), \(literal: argument.description))"` 这里用了 SwiftSyntax 的字符串插值：`\(argument)` 把语法节点原样塞进去，`\(literal: ...)` 把字符串作为字面量塞进去

#### 注册插件 —— `Plugin.swift`

```swift
import SwiftCompilerPlugin
import SwiftSyntaxMacros

@main
struct MacrosKitPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        StringifyMacro.self,
    ]
}
```

这告诉编译器"这个 plugin 提供了哪些宏类型"。每加一个新宏，就把它的类型追加到 `providingMacros` 里。

#### 使用 —— `MacrosDemo/main.swift`

```swift
import MacrosKit

let (value, source) = #stringify(1 + 2 * 3)
print(value)   // 7
print(source)  // 1 + 2 * 3
```

跑起来你应该看到：

```
7
1 + 2 * 3
```

如果右键 `#stringify(...)` → Expand Macro，会看到它就地变成了：

```swift
let (value, source) = (1 + 2 * 3, "1 + 2 * 3")
```

完了——这就是宏的全部。**它就是个"把表达式 A 替换成代码 B"的小程序**。

#### 调试小贴士

- 宏报错很怪，因为错误指向的是"你没写的代码"。Xcode 里**多用 Expand Macro 看一眼展开形态**
- 宏的实现里能用 `print` 调试。这些 `print` 会在编译期、由 macro plugin 进程输出到编译日志
- 第一次构建宏 target 会拉 swift-syntax 并编译，**慢得不寻常**（首次可能 1~3 分钟）。后续会缓存

### 模块 6：宏的边界与工程上的坑

#### 边界

宏能做什么：

- 给类型加属性、方法、协议遵从
- 改写属性的 getter/setter
- 在编译期生成同名对等声明、生成 extension

宏**不能**做什么：

- 在**运行时**生成类型（这是反射 / 元类型的活）
- 看到当前工程其它文件的内容（宏的输入只是它被调用时的那段语法树）
- 替代普通函数。能用函数表达的逻辑，**别**用宏

#### 坑

- **不要给"普通能用函数表达"的事用宏**。宏的成本是高的：拖编译时间、增加排查难度、不能 step into 调试。除非你真的需要"在编译期写代码"
- **不要为了少写几行而引入第三方宏库**。每多一个宏 target，编译都要慢一截
- **宏报错信息看上去吓人**。常见做法是：先 Expand Macro 看展开后的代码，对着展开结果重新解读报错
- **宏不能跨模块"看到"调用方的别处代码**。所以宏不适合做"按工程内某些约定动态生成"的逻辑

### 模块 7：回看 `@Observable`——把所有点连起来

回到模块 3 的展开结果。现在你应该能解释每一段代码是怎么来的：

```swift
@Observable
final class Counter {
    var value: Int = 0
}
```

`@Observable` 是一个 attached macro，它在 `Counter` 上同时使用了几个角色：

| 角色 | 它生成了什么 |
| --- | --- |
| `@attached(member)` | 加了 `_$observationRegistrar`、`access(keyPath:)`、`withMutation(keyPath:_:)` 等成员 |
| `@attached(memberAttribute)` | 给每个被追踪的属性加 `@ObservationTracked` 这个标记 |
| `@attached(extension)` | 生成 `extension Counter: Observable {}` |

而 `@ObservationTracked` 本身也是一个宏（`@attached(accessor)` 角色），它把属性的 getter/setter 改写成调用 `access` / `withMutation`。

整个链条：

```
@Observable
  │
  ├─[member]──→ 加 ObservationRegistrar / access / withMutation
  ├─[memberAttribute]──→ 给 var 加 @ObservationTracked
  │                           │
  │                           └─[accessor]──→ 改写 getter/setter
  └─[extension]──→ extension Counter: Observable {}
```

这套机制的意义在于：它让任何外部观察者都能在编译期生成的 `access` / `withMutation` 钩子上追踪到"哪个属性被读、哪个属性被改"。但你**不需要**记住生成的每一行代码——你只要记住"这是编译期被生成出来的、跟我自己手写的没有任何区别"就够。

需要排错时，回到这里来 Expand Macro 看一眼。

## 小结

- **宏是什么**：编译期对源码做语法变换的程序。输入是 AST，输出是 AST，编译完成后运行时不存在
- **两类宏**：以 `#` 开头的 freestanding（作为表达式 / 声明），以 `@` 开头的 attached（贴在声明上扩展它）
- **工程结构**：`.macro` target（实现，依赖 swift-syntax）+ `.target`（对外声明）+ 使用者
- **最小例子**：`#stringify(x)` 在编译期就地变成 `(x, "x")`
- **`@Observable`**：本质就是一个 attached 宏，把"接通 ObservationRegistrar"的样板代码自动生成
- **何时不要用宏**：能用函数 / 协议扩展 / 属性包装器表达的事，都别用宏；宏只在"真的需要在编译期生成代码"的场合才划算
- **调试姿势**：右键 → **Expand Macro**，永远先看一眼展开后的代码

## 练习

动手写代码的 starter 工程在 `exercises/zh-CN/projects/58-swift-macros-from-zero-starter`；写完想对答案，参考实现与逐题讲解在 `exercises/zh-CN/answers/58-swift-macros-from-zero.md`。

### 任务 1：阅读 `@Observable` 的展开（开放题）

在 Xcode 里写一段最小的 `@Observable` 代码（比如一个带一两个 `var` 属性的 `final class`），右键 → Expand Macro 看展开结果。从生成的代码里**挑两个成员**（例如被改写的某个属性、或 `_$observationRegistrar`），**逐行写注释**：解释这一行为什么会被生成、它对应原属性的哪种行为变化、运行时会发生什么。

交付物：一段带逐行注释的展开代码 + 几句你的观察（比如"原来的 `var value` 是怎么一分为二的""观察者为什么不需要额外监听"）。

提示：先把光标放在 `@Observable` 上展开一层，再把光标放在生成的 `@ObservationTracked` 上展开第二层，能看到属性 getter/setter 被改写成 `access` / `withMutation` 调用的细节。

### 任务 2：写一个 `#URL` 宏

在 starter 工程基础上，写一个 freestanding 宏 `#URL`，在**编译期**校验 URL 字符串：

- 合法：`#URL("https://example.com")` 展开为 `URL(string: "https://example.com")!`
- 参数不是字符串字面量（比如传了变量 `#URL(someVar)`）：报编译错误
- 字符串不能构造出合法 URL（比如 `#URL(" ")`）：报编译错误

starter 里已经把三个 target（`URLKit` 对外声明 / `URLKitMacros` 实现 / `URLDemo` 使用）和测试文件的骨架搭好，你需要补全宏声明、`URLMacro: ExpressionMacro` 的实现、把宏注册进 plugin，并写三个测试（合法 / 参数非字面量 / 参数不合法）。写完跑 `swift test` 和 `swift run URLDemo` 验证。

提示：参数取到后用 `.as(StringLiteralExprSyntax.self)` 判断是不是字符串字面量；还要确认它只有一段且是 `.stringSegment`（拒绝带插值的写法）；最后返回时走 `\(literal: text)`，别手写引号拼接。

### 任务 3（思考题）：函数 / 协议扩展 / 属性包装器 / 宏，分别用在哪？

下面三个需求，分别该用「普通函数 / 协议扩展 / 属性包装器 / 宏」中的哪一个？为什么？把判断和理由写下来（也可以写进答案 markdown 里对照）：

- "我希望所有 `Double` 属性自动限制在 0~100"
- "我希望某个 class 自动遵从 `Equatable`，比较所有存储属性"
- "我希望写一个工具，把 `Date` 格式化成 `yyyy-MM-dd`"

提示：先问自己每个需求"想做的事是什么形状"——是纯输入输出、是给类型加方法、是干预单个属性存取、还是要批量生成成员/协议遵从。形状对上了，工具自然就定了。
