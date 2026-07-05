# 54. 关联类型与不透明返回类型：`associatedtype` 与 `some`

## 阅读导航

- 前置章节：[21. 协议：灵活的抽象](./21-protocols-flexible-abstraction.md)、[24. 泛型：可复用的抽象](./24-generics-reusable-abstractions.md)、[27. 协议扩展与默认实现](./27-protocol-extensions-and-default-implementations.md)
- 上一章：[53. Swift Package Manager 工程化入门：从多文件到多模块、Package.swift、Target 与 Product](./53-swift-package-manager-from-multi-file-to-multi-module.md)
- 下一章：[55. 属性包装器原理：从零实现一个 `@propertyWrapper`](./55-property-wrappers-from-zero.md)
- 适合谁读：已经写过普通协议和泛型函数，但看到 `associatedtype`、`some`、`any` 这些写法还会犯迷糊，想把它们一次性讲清楚的读者

## 本章目标

学完这一章后，你应该能够：

- 区分"泛型参数 `<T>`"和"关联类型 `associatedtype`"各自适合什么场景
- 看懂一个带 `associatedtype` 的协议为什么不能直接当变量类型用
- 解释 `some P` 的含义：编译期固定、对调用者隐藏的具体类型
- 区分 `some P` 与 `any P`，并说出各自的代价
- 在脑子里把 `func makeUserSource() -> some PaginatedSource<User>` 翻译成"这个函数返回某个具体的 `PaginatedSource`，但我不告诉你是哪个"
- 用 `where` 子句、`primary associated type` 给关联类型加约束
- 判断一个 API 应该返回 `some P`、`any P`，还是干脆暴露具体类型

## 本章对应资源

- 文稿：`docs/zh-CN/chapters/54-associated-types-and-opaque-return-types.md`
- 示例项目：`demos/projects/54-associated-types-and-opaque-return-types`
- 练习答案：`exercises/zh-CN/answers/54-associated-types-and-opaque-return-types.md`
- 练习 starter：`exercises/zh-CN/projects/54-associated-types-and-opaque-return-types-starter`

## 本章怎么读

建议阅读顺序：

1. 先把[24.泛型：让同一套逻辑适配更多类型](./24-generics-reusable-abstractions.md)这一节读完，理解它和泛型参数的分工
2. 再看 `some` 在返回类型位置上解决了什么问题
3. 然后对比 `some` 与 `any`，建立"什么时候选哪个"的判断
4. 最后回到一个返回 `some P` 的工厂方法，验证自己能不能解释这一行里的每个关键字

## 正文主体

### 模块 0：为什么现在讲这两个关键字

到目前为止，你已经写过不少协议、不少泛型函数。但很可能没真正面对过下面这两类写法：

```swift
protocol Container {
    associatedtype Item
    var count: Int { get }
    subscript(index: Int) -> Item { get }
}

func makeBox() -> some Container {
    // ...
}
```

如果你绕过这两个关键字，下次在某个库的 API 里看到 `func makeBox() -> some Container`，或者在某个协议里看到 `associatedtype Item`，就只能"按住不放、机械抄写"，不知道编译器到底在帮你做什么。

这一章要把它们拆开讲清楚，目标只有一个：

- 让你看到任何一个返回 `some P` 的函数、任何一个带 `associatedtype` 的协议时，能解释清楚每一个关键字在做什么

我们会发现，这两个关键字之所以总是一起出现，是因为它们解决的是同一个问题的"两半"：

- `associatedtype` 是协议里的"洞"
- `some` 是把这个"洞"填上的一种方式

### 模块 1：从泛型函数回顾"类型参数"

先把熟悉的写法摆在桌面上：

```swift
func first<T>(of array: [T]) -> T? {
    array.first
}

let n = first(of: [1, 2, 3])           // Int?
let s = first(of: ["a", "b", "c"])     // String?
```

这是泛型参数。它有几个特征值得复述一遍：

- `T` 是占位符
- **谁在调用，谁决定 `T` 是什么**
- 编译器在每个调用点把 `T` 替换成具体类型

你可以把它写成一句口诀：

- 泛型参数 = 调用方填空

这条口诀很关键。下一节我们就会遇到一种"调用方填不上空"的场景，这时候才轮到关联类型出场。

### 模块 2：协议里的"洞" —— `associatedtype`

考虑这个需求：

- 我想抽象出"一个容器"的概念
- 它有 `count`
- 它可以按下标取出元素
- 但不同的容器，元素类型不一样

如果你直接套泛型，会写成：

```swift
protocol Container<Item> {   // ← 后面会回来讲这个写法
    var count: Int { get }
    subscript(index: Int) -> Item { get }
}
```

但 Swift 协议早期版本不支持"协议尖括号参数"。即使你今天能写出这种写法，它在概念上还是会和泛型参数混淆。所以 Swift 给协议设计了另一个机制：

```swift
protocol Container {
    associatedtype Item
    var count: Int { get }
    subscript(index: Int) -> Item { get }
}
```

`associatedtype Item` 的含义是：

- 这个协议里有一个"洞"叫 `Item`
- 我现在不告诉你它是什么
- **遵守这个协议的具体类型，必须填上这个洞**

也就是说：

- 关联类型 = 实现方填空

请把这句话和[第24章]((./24-generics-reusable-abstractions.md))的"泛型参数 = 调用方填空"放在一起记。能让你更好地理解它们之间的差异

#### 实现方怎么填洞

```swift
struct IntStack: Container {
    var items: [Int] = []

    var count: Int { items.count }

    subscript(index: Int) -> Int {
        items[index]
    }
}
```

`IntStack` 在实现 `subscript(index:)` 时返回 `Int`，编译器据此推断：

- `IntStack` 的 `Item` 是 `Int`

也可以显式写出来：

```swift
struct IntStack: Container {
    typealias Item = Int
    // ...
}
```

绝大多数情况下不用显式写，编译器能从方法/属性签名里推出来。

#### 同一个协议可以被不同的"填法"实现

```swift
struct StringStack: Container {
    var items: [String] = []
    var count: Int { items.count }
    subscript(index: Int) -> String {
        items[index]
    }
}
```

这下我们有了两个 `Container`：

- `IntStack`：`Item == Int`
- `StringStack`：`Item == String`

它们都遵守 `Container`。但它们的 `Item` 类型不同。这就引出了下一节最关键的一个问题。

### 模块 3：为什么不能直接 `let c: Container = ...`

试着写这一行：

```swift
let c: Container = IntStack()   // ← 编译错误
```

在 Swift 5.6 之前，这行直接报错。从 Swift 5.7 起，你可以写：

```swift
let c: any Container = IntStack()   // ✅ 合法，但是有代价
```

为什么必须显式加 `any`？因为：

- 当你只说"`c` 是某个 `Container`"
- 你没说它的 `Item` 到底是什么
- 编译器无法知道 `c[0]` 应该返回 `Int` 还是 `String`
- 编译器也无法在调用点为你生成正确的代码

`any Container` 这种写法叫做**存在类型（existential type）**，它的本质是：

- 在运行时用一个"盒子"装下任何 `Container`
- 调用方法时通过运行时分派

存在类型有它的代价：

- 装箱开销
- 调用变成间接调用
- 关联类型在很多场景下无法对外暴露（你拿到 `c[0]` 时只能得到 `Any` 或带约束的擦除类型）

所以 Swift 给了你另一种"填洞方式"——`some`。这就是下一个关键字。

### 模块 4：`some` 出场 —— 不透明返回类型

先看一个例子：

```swift
func makeStack() -> some Container {
    IntStack()
}
```

这行的含义是：

- `makeStack` 返回某个具体的 `Container`
- **编译期能确定它的具体类型**（实际是 `IntStack`）
- 但是**对调用者隐藏**，调用者只知道"这是某个 `Container`"

注意"编译期能确定"和"对调用者隐藏"这两件事不矛盾：

- 编译器在编译 `makeStack` 这个函数体时，知道返回的是 `IntStack`
- 编译器在编译调用方时，只看到 `some Container`，把 `Item` 当成一个未知但确定的具体类型

这就是 `some` 的核心三性质：

1. **编译期固定**：函数体里返回的所有路径必须是同一个具体类型
2. **对外隐藏**：调用方不知道具体类型是什么
3. **没有装箱**：性能等价于直接用具体类型，因为编译器知道它是谁

#### 一个非常容易踩的坑

下面这段代码不能编译：

```swift
func makeStack(useInt: Bool) -> some Container {
    if useInt {
        return IntStack()         // 类型 A
    } else {
        return StringStack()      // 类型 B
    }
}
```

报错的原因是：

- 不同分支返回了不同的具体类型
- 但 `some Container` 要求**所有分支返回同一种具体类型**

记住这一点你就理解了 `some` 与 `any` 的根本差别：

- `some P`：编译期就一种具体类型
- `any P`：运行期可以是任何遵守 `P` 的具体类型

### 模块 5：`some` 与 `any` 的对照表

| 维度 | `some P` | `any P` |
| --- | --- | --- |
| 谁决定具体类型 | 函数体（实现方） | 调用现场（运行时） |
| 什么时候决定 | 编译期 | 运行期 |
| 同一个 `some` 多次出现 | 必须是同一种类型 | 可以是不同类型 |
| 装箱 / 间接调用 | 无 | 有 |
| 可以放进 `Array` 装异构元素吗 | 不可以 | 可以 |
| 能直接通过它访问关联类型吗 | 可以（编译期固定） | 受限（关联类型被擦除） |
| 适合的场景 | 工厂方法、Builder、属性的 getter | 异构集合、运行期分派 |

最常见的两条选择标准：

- 如果你**只会返回一种具体类型**，但不想把这种类型作为 API 暴露 → `some P`
- 如果你**需要在同一变量里放不同具体类型**或者**装到数组里混着用** → `any P`

落到具体例子上：

- `func makeUserSource() -> some PaginatedSource<User>` —— 这个工厂函数体里其实只会返回一种类型（比如 `UserRemoteSource`），所以可以用 `some`，把具体实现藏起来
- `[any Container]` —— 想把 `IntStack`、`StringStack` 这些元素类型不同的容器混着放进一个数组，就必须用 `any`

#### 三个关键字的标准写法

上面那张表讲的是"语义差别"，这里给你一张"照着写就对"的速查模板。这三个关键字不是同一个类型上的几个成员，而是三种并列的语法形式，所以下面按"何时用、解锁什么"逐个标注：

```swift
// 1) 在协议里开关联类型：声明方留洞，实现方填洞
//    用在"实现方决定类型、协议自己定不出来"的场景。
protocol Container {

    /// 必需的"洞"。声明方只说"有这么个类型"，由每个实现方各自填上。
    /// 可加约束写成 `associatedtype Item: Equatable`，要求填进来的类型必须遵守某协议。
    associatedtype Item

    /// 用到这个洞的成员：返回值类型就是上面那个还没填的 Item。
    subscript(i: Int) -> Item { get }
}

// 1') 主关联类型（primary associated type）写法：把洞提到协议名后面的尖括号里，
//     这样外部写类型时能直接约束它，例如 `some Container<Int>` / `any Container<Int>`。
protocol PrimaryContainer<Item> {
    associatedtype Item
    subscript(i: Int) -> Item { get }
}

// 2) some P 作返回/参数类型：编译期确定的单一具体类型。
//    调用方拿到"某个确定的 P，但不知道是哪一个"；同一个 some 多次出现必须是同一种类型。
//    用在工厂方法、属性 getter——想暴露能力、藏住具体实现，且零装箱开销。
func makeContainer() -> some Container { IntStack() }

// 3) any P 作变量/数组元素类型：运行时可变的存在类型（带装箱）。
//    允许在同一个变量或数组里混装不同实现。
//    用在异构集合、运行期分派——需要"放进去的具体类型可以不一样"。
let mixed: [any Container] = [IntStack(), StringStack()]
```

对照本章已经写过的：

- 本章一开头声明的 `protocol Container { associatedtype Item ... }`（模块 2）就是第 1 种——声明方留洞，`IntStack` 把 `Item` 填成 `Int`、`StringStack` 填成 `String`。
- 模块 7 里的 `protocol Container<Item>` 是第 1' 种主关联类型写法，于是模块 7 才能写出 `some Container<Int>`。
- `func makeUserSource() -> some PaginatedSource<User>`（模块 4、9）用的是第 2 种——函数体只返回一种类型（`UserRemoteSource`），但对外只露 `some PaginatedSource<User>`。
- `[any Container]`（模块 5 上面那条）用的是第 3 种——把元素类型不同的容器混进同一个数组。

### 模块 6：把一个"带 `associatedtype` 的属性"协议剖开看一眼

前面的 `Container` 把关联类型放在 `subscript` 的返回值里。还有一种很常见的形态：协议要求实现方提供一个**属性**，而这个属性的类型本身就是关联类型。很多"可组合"的协议都长这样。我们自己造一个最小例子：

```swift
protocol ContentProvider {
    associatedtype Content
    var content: Content { get }
}
```

逐行翻译：

- `associatedtype Content` —— 协议里有一个洞叫 `Content`，由实现方填上。
- `var content: Content { get }` —— 实现方必须提供一个属性 `content`，它的类型就是上面那个洞。

注意：和模块 3 一样，因为 `Content` 是个没填的洞，你**不能**直接写 `let p: ContentProvider = ...`，必须写 `any ContentProvider`，否则编译器不知道 `p.content` 到底是什么类型。

那"洞"怎么填？最顺手的方式就是这一章的主角 `some`：

```swift
struct EvenNumbers: ContentProvider {
    let upTo: Int
    var content: some Sequence<Int> {
        (0..<upTo).lazy.filter { $0 % 2 == 0 }
    }
}
```

这一段可以完整翻译成：

- `EvenNumbers` 遵守 `ContentProvider`
- 它必须提供 `content`
- `content` 的类型是某个具体的、元素是 `Int` 的序列
- 这个具体类型由编译器从函数体推出来（这里是 `LazyFilterSequence<Range<Int>>`）
- 编译器把这个类型藏起来，外部只知道它是 `some Sequence<Int>`，于是 `EvenNumbers.Content` 这个洞就被填成了那个被藏起来的具体类型

把它和模块 4 连起来看：`some` 在返回类型位置上的全部本事，就是"由实现方给出一个具体类型、对外隐藏、零装箱开销"。当一个协议要求你交出一个关联类型的值时，`some` 正好是最自然的填法。

现在你可以确定：再遇到"协议里有 `associatedtype Content`、实现里用 `var content: some ...` 把它填上"这种结构，你不需要"机械相信编译器"，而是能逐字解释每个关键字。

### 模块 7：给关联类型加约束 —— `where` 与 `primary associated type`

光有"洞"是不够的。在很多时候协议需要对”洞“做约束。

#### 用 `where` 子句约束关联类型

```swift
protocol Container {
    associatedtype Item
    var count: Int { get }
    subscript(index: Int) -> Item { get }
}

extension Container where Item: Equatable {
    func contains(_ value: Item) -> Bool {
        for i in 0..<count where self[i] == value {
            return true
        }
        return false
    }
}
```

读法：

- `where Item: Equatable` 给协议扩展加了一个约束
- 只有当一个 `Container` 的 `Item` 本身遵守 `Equatable` 时，`contains` 才可用
- `IntStack` 可以（`Int: Equatable`），自定义的 `RawDataStack`（如果 `Item` 是某种不 Equatable 的类型）就用不了

这种写法在标准库里非常常见。`Sequence`、`Collection` 上的大量扩展都使用 `where` 子句把"在某种关联类型下才有意义"的方法挂出来。

#### 主关联类型（primary associated type）

Swift 5.7 引入了一个语法糖：

```swift
protocol Container<Item> {
    var count: Int { get }
    subscript(index: Int) -> Item { get }
}
```

注意 `Container<Item>` 这种写法。它意味着：

- `Item` 是 `Container` 的**主关联类型**
- 在外面写类型时可以用 `Container<Int>`、`Container<String>` 直接约束

举个例子：

```swift
func sumAll(_ c: some Container<Int>) -> Int {
    var sum = 0
    for i in 0..<c.count {
        sum += c[i]
    }
    return sum
}
```

这一行 `some Container<Int>` 同时用上了三件事：

- `some` —— 编译期固定的不透明类型
- `Container` —— 协议
- `<Int>` —— 约束主关联类型

你可以读成："某个 Item 是 Int 的 Container"。

`Sequence<Element>`、`Collection<Element>`、`AsyncSequence<Element, Failure>` 都用了主关联类型语法。你接下来在工程里到处都会见到这个写法。

### 模块 8：什么时候用泛型，什么时候用关联类型

这是工程里最容易犯迷糊的地方。给你三条判断：

**如果"谁来决定类型"是调用方的事**

- 用泛型参数
- 比如 `func sort<T: Comparable>(_ array: [T])`，由调用方决定排什么

**如果"谁来决定类型"是实现方的事**

- 用关联类型
- 比如 `Sequence` 不该让外部决定它的 `Element`，应该让 `Array<Int>` 自己说"我的 Element 是 Int"

**如果两者都成立**

- 多数时候用关联类型 + 主关联类型语法（更灵活）
- 比如 `Container<Int>` 既能让实现方决定，又能让调用方约束

一个偏工程的反例可以帮你记牢这个判断：

```swift
// 不推荐：把"由实现方决定"的类型当成泛型参数
struct UserStack<T> {
    var items: [T] = []
}

// 这意味着每个使用 UserStack 的地方都得"自己挑 T"
// 但 UserStack 明明是面向 User 的，它的元素类型本来就应该是固定的
```

这种"过度泛型化"会让 API 变难用。把"用户决定不出来的类型"做成关联类型，才是工程上更稳的方式。

### 模块 9：常见的 `some` 用法目录

这一节给你一个工程参考表，这些形态在标准库和各类库的 API 里会反复出现。

#### `some` 作为返回类型

```swift
func makeFilteredView(items: [Int]) -> some Sequence<Int> {
    items.lazy.filter { $0 > 0 }
}
```

- 不暴露 `LazyFilterSequence<Array<Int>>` 这种实现细节
- 调用方拿到的是"某个序列，元素是 Int"

#### `some` 作为参数类型

Swift 5.7 起，`some` 也可以放在参数位置：

```swift
func printCount(of c: some Container) {
    print(c.count)
}
```

读法：

- 编译器在每个调用点把 `some Container` 推成具体类型
- 等价于早期写法 `func printCount<C: Container>(of c: C)`
- 现在这种写法更短，也更接近"普通函数签名"

这种"在参数位置的 `some`"叫做**轻量泛型语法**。

#### `some` 不能用在存储属性

```swift
struct Wrapper {
    let value: some Container = IntStack()  // ❌ 不行
}
```

`some` 只能用在函数返回类型、参数类型、`var` 计算属性的类型上。存储属性不能用 `some`。

记一条简短规则：

- `some` 描述"由实现给出的、对外不暴露的具体类型"
- 这种描述只在函数 / 计算属性这种"主动给出值"的位置有意义

### 模块 10：一段把所有概念串起来的工程片段

下面是这一章 demo 里会出现的一段简化代码。它把关联类型、`some`、主关联类型、`where` 子句都用上：

```swift
public protocol PaginatedSource<Element> {
    associatedtype Element
    var pageSize: Int { get }
    func fetch(page: Int) async throws -> [Element]
}

public struct UserRemoteSource: PaginatedSource {
    public let pageSize = 20
    public init() {}
    public func fetch(page: Int) async throws -> [User] {
        // 假装从网络拉数据
        return (0..<pageSize).map { i in
            User(id: page * pageSize + i, name: "User \(page)-\(i)")
        }
    }
}

public func makeUserSource() -> some PaginatedSource<User> {
    UserRemoteSource()
}
```

挨个点一下：

- `PaginatedSource` 有关联类型 `Element`，并把它声明为主关联类型
- `UserRemoteSource` 通过实现 `fetch(page:)` 隐式把 `Element` 填成 `User`
- `makeUserSource()` 用 `some PaginatedSource<User>` 暴露能力，但藏住"具体实现是 `UserRemoteSource`"

调用方看到的是：

```swift
let source = makeUserSource()
let firstPage = try await source.fetch(page: 0)  // [User]
```

它**完全不知道**背后是 `UserRemoteSource`、`UserLocalSource` 还是别的什么。下次你想换实现，只要返回类型仍然是 `some PaginatedSource<User>`，外部代码完全不用动。

这正是工程里 `some` 最值钱的地方：

- 解耦"对外能力"和"内部实现"
- 同时保留编译期类型安全和零开销

## 本章对应 demo

这一章的 demo 在 `demos/projects/54-associated-types-and-opaque-return-types`，是一个最小 Swift Package。它全程是可独立运行的纯 Swift，不依赖任何 UI 框架，你现在就能把这一章的概念跑起来。

```text
54-associated-types-and-opaque-return-types/
├─ Package.swift
├─ Sources/
│  ├─ ContainerKit/
│  │  ├─ Container.swift
│  │  ├─ Stacks.swift
│  │  └─ Sources.swift
│  └─ ContainerDemo/
│     └─ main.swift
└─ Tests/
   └─ ContainerKitTests/
      └─ ContainerKitTests.swift
```

重点位于以下四个文件中：

### `Container.swift`：关联类型与主关联类型

```swift
public protocol Container<Item> {
    associatedtype Item
    var count: Int { get }
    subscript(index: Int) -> Item { get }
}

public extension Container where Item: Equatable {
    func contains(_ value: Item) -> Bool {
        for i in 0..<count where self[i] == value {
            return true
        }
        return false
    }
}
```

主关联类型用 `<Item>` 暴露，让外部可以写 `Container<Int>`、`Container<String>`。

### `Stacks.swift`：两种填洞方式

```swift
public struct IntStack: Container {
    public private(set) var items: [Int]
    public init(items: [Int] = []) { self.items = items }
    public var count: Int { items.count }
    public subscript(index: Int) -> Int { items[index] }
}

public struct StringStack: Container {
    public private(set) var items: [String]
    public init(items: [String] = []) { self.items = items }
    public var count: Int { items.count }
    public subscript(index: Int) -> String { items[index] }
}
```

`IntStack` 的 `Item == Int`、`StringStack` 的 `Item == String`。在调用 `contains` 时分别走 `Int: Equatable` 与 `String: Equatable` 的扩展。

### `Sources.swift`：`some` 与异步关联类型

```swift
public protocol PaginatedSource<Element> {
    associatedtype Element
    var pageSize: Int { get }
    func fetch(page: Int) async throws -> [Element]
}

public struct UserRemoteSource: PaginatedSource {
    public let pageSize = 20
    public init() {}
    public func fetch(page: Int) async throws -> [User] {
        (0..<pageSize).map { i in
            User(id: page * pageSize + i, name: "User \(page)-\(i)")
        }
    }
}

public struct User: Equatable, Sendable {
    public let id: Int
    public let name: String
    public init(id: Int, name: String) {
        self.id = id
        self.name = name
    }
}

public func makeUserSource() -> some PaginatedSource<User> {
    UserRemoteSource()
}
```

读这一段时关注：

- `makeUserSource()` 的签名暴露能力，不暴露实现
- 调用方拿到的是 `some PaginatedSource<User>`
- 如果有一天你把 `UserRemoteSource` 换成 `UserMockSource`，外部代码完全不动

### `main.swift`：跑一遍

```swift
import ContainerKit

let intStack = IntStack(items: [1, 2, 3, 4])
print("count = \(intStack.count)")
print("contains 3? \(intStack.contains(3))")

let source = makeUserSource()
let firstPage = try await source.fetch(page: 0)
print("first page count = \(firstPage.count)")
print("first user = \(firstPage.first!.name)")
```

运行命令：

```bash
cd demos/projects/54-associated-types-and-opaque-return-types
swift run ContainerDemo
```

如果一切就绪，你会看到类似输出：

```text
count = 4
contains 3? true
first page count = 20
first user = User 0-0
```

### `ContainerKitTests.swift`：把关键性质沉淀成测试

```swift
import Testing
@testable import ContainerKit

@Test("IntStack.contains 在元素存在时返回 true")
func intStackContainsExisting() {
    let stack = IntStack(items: [1, 2, 3])
    #expect(stack.contains(2))
}

@Test("makeUserSource 返回的 source 能拉到第一页")
func makeUserSourceReturnsFirstPage() async throws {
    let source = makeUserSource()
    let page = try await source.fetch(page: 0)
    #expect(page.count == 20)
    #expect(page.first == User(id: 0, name: "User 0-0"))
}
```

注意第二条测试的形态：

- 我们在测试里不用关心 `source` 到底是 `UserRemoteSource` 还是 `UserMockSource`
- 这正是 `some` 的设计意图

## 小结

这一章我们把协议层最常见的两个关键字拆开讲透了：

- **关联类型 `associatedtype`** —— 协议里的"洞"，由实现方填上
- **`some P`** —— 编译期固定的、对外隐藏的具体类型
- **`any P`** —— 运行期装箱的存在类型，可以装异构元素

判断口诀：

- 调用方填空 → 泛型参数 `<T>`
- 实现方填空 → 关联类型 `associatedtype`
- 返回单一具体类型但想隐藏它 → `some P`
- 真的要装异构集合或运行期分派 → `any P`

至此你可以解释任何一个返回 `some P` 的函数里的每一个关键字。下一章我们会再补一块拼图——属性包装器，让你看懂 `@` 开头那一类标记背后的原理。

## 练习

动手写代码的 starter 工程在 `exercises/zh-CN/projects/54-associated-types-and-opaque-return-types-starter`；写完想对答案，参考实现与逐题讲解在 `exercises/zh-CN/answers/54-associated-types-and-opaque-return-types.md`。

### 任务 1：让两个具体类型遵守 `ReadOnlyStorage` 并加上 `contains`

starter 里有一个描述"只读存储"的协议，它带一个由实现方填的关联类型：

```swift
public protocol ReadOnlyStorage<Element> {
    associatedtype Element
    var count: Int { get }
    func element(at index: Int) -> Element
}
```

旁边还有两个目前**没有**遵守这个协议的空壳类型：`InMemoryNumberStorage`（内部持有 `[Int]`）和 `InMemoryNameStorage`（内部持有 `[String]`）。你要做三件事：

1. 让 `InMemoryNumberStorage` 遵守 `ReadOnlyStorage`，使它的 `Element` 是 `Int`。
2. 让 `InMemoryNameStorage` 遵守 `ReadOnlyStorage`，使它的 `Element` 是 `String`。
3. 给 `ReadOnlyStorage` 加一个 `where Element: Equatable` 的协议扩展，实现 `contains(_:)`。

交付物：两个类型都能编译通过，并且 `numbers.contains(2)`、`names.contains("B")` 这类调用都能正常工作。

提示：两个类型都不用写 `typealias Element = ...`，编译器能从 `element(at:)` 的返回类型推出来；`contains(_:)` 借助 `where Element: Equatable` 的扩展挂一份就够，别在每个类型里各抄一遍。

### 任务 2：把 `any Sequence<Int>` 改造为 `some Sequence<Int>`

starter 里有这样一个工厂函数，它的返回类型是 `any Sequence<Int>`，调用方因此承担了装箱开销：

```swift
public func evenNumbers(upTo n: Int) -> any Sequence<Int> {
    (0..<n).filter { $0 % 2 == 0 }
}
```

请把返回类型改造成 `some Sequence<Int>`，让它通过编译；然后用一段文字说明：从 `any` 换成 `some` 之后，哪些调用方写法会从"原本能编译"变成"不能编译"，哪些写法完全不受影响。

交付物：改造后的函数 + 一段对受影响调用场景的说明。

提示：分别想一想这几种调用方写法在 `some` 下还成不成立——把同一个变量重新赋成另一个不同实现的序列、把多个返回值塞进同一个数组、只用 `for n in ...` 迭代一次。

### 任务 3（思考题）：分析 `makeUserSource` 与 `PaginatedSource`

回到本章模块 10 的这段代码：

```swift
public protocol PaginatedSource<Element> {
    associatedtype Element
    var pageSize: Int { get }
    func fetch(page: Int) async throws -> [Element]
}

public struct UserRemoteSource: PaginatedSource {
    public let pageSize = 20
    public init() {}
    public func fetch(page: Int) async throws -> [User] {
        (0..<pageSize).map { i in
            User(id: page * pageSize + i, name: "User \(page)-\(i)")
        }
    }
}

public func makeUserSource() -> some PaginatedSource<User> {
    UserRemoteSource()
}
```

请回答三个问题：

- **问 1**：`makeUserSource()` 为什么返回 `some` 而不是 `any`？
- **问 2**：`PaginatedSource` 里哪一个声明用到了 `associatedtype`？哪一行依赖 `some`？
- **问 3**：把返回类型从 `some` 改成 `any`，会失去什么？

提示：从三个角度想——函数体是不是只会返回一种具体类型、`any` 带来的装箱与运行时分派开销、关联类型在 `any` 下被擦除后会有什么限制。
