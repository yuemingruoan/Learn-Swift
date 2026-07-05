# 55. 属性包装器原理：从零实现一个 `@propertyWrapper`

## 阅读导航

- 前置章节：[13. 结构体与自定义类型](./13-structs-and-custom-types.md)、[16. 类与引用语义](./16-class-and-reference-semantics.md)、[21. 协议：灵活的抽象](./21-protocols-flexible-abstraction.md)、[24. 泛型：可复用的抽象](./24-generics-reusable-abstractions.md)
- 上一章：[54. 关联类型与不透明返回类型：`associatedtype` 与 `some`](./54-associated-types-and-opaque-return-types.md)
- 下一章：[56. Result Builder 与 DSL：从语法转写到 mini HTML builder](./56-result-builders-and-mini-dsl.md)
- 适合谁读：会写结构体和泛型，但每次看到各种 `@` 开头的标记（属性包装器）都只能照搬却说不清原理，想搞清楚它们到底是什么、`wrappedValue` 与 `$value` 怎么来的读者

## 本章目标

学完这一章后，你应该能够：

- 解释属性包装器到底是一个什么东西：本质上是一个带特定形状的类型
- 看懂 `wrappedValue` 与 `projectedValue` 各自负责什么
- 解释 `@MyWrapper var x` 在编译期会被展开成什么
- 解释 `$x` 这个写法（projectedValue）的来源与用途
- 自己实现一个 `@Clamped` 数值范围包装器（带初始化器 + projectedValue）
- 自己实现一个 `@UserDefault` 包装器，把读写穿透到 `UserDefaults`
- 理解属性包装器在结构体 vs 类、let vs var 上的微妙差别
- 判断一段业务代码是不是适合用属性包装器抽象

## 本章对应资源

- 文稿：`docs/zh-CN/chapters/55-property-wrappers-from-zero.md`
- 示例项目：`demos/projects/55-property-wrappers-from-zero`
- 练习答案：`exercises/zh-CN/answers/55-property-wrappers-from-zero.md`
- 练习 starter：`exercises/zh-CN/projects/55-property-wrappers-from-zero-starter`

## 本章怎么读

建议阅读顺序：

1. 先看"没有属性包装器时同一段逻辑要怎么写"，体会重复在哪里
2. 跟着实现一个最小的 `@Clamped`，理解 `wrappedValue` 的最小契约
3. 加上 `projectedValue`，把 `$value` 的语义站住
4. 实现 `@UserDefault` 体会"包装器与外部存储打通"的工程感
5. 最后再回头看 `projectedValue`/`wrappedValue` 的组合形状，会发现工程里各种属性包装器都是同一个模板

## 正文主体

### 模块 0：为什么需要属性包装器

写工程代码时，你会反复遇到这样的场景：**很多字段都要做同一种处理**。

- 几个数值字段都要"限制在某个范围内"（亮度 0~100、音量 0~100、进度 0~1）
- 几个字符串字段都要"写入前去掉首尾空白"（用户昵称、搜索关键词、表单输入）
- 几个配置字段都要"读写时自动同步到 `UserDefaults`"（主题、字号、是否首次启动）

这些处理的共同点是：它们**和具体业务无关**，纯粹是"值进出时的固定变换"。如果不抽象，你就得给每个属性都手写一遍 `get`/`set`，代码里到处是重复的样板，改一处约束要改好几个地方，还容易漏写。

属性包装器（property wrapper）就是为这种"横切关注点"准备的：你把"值进出时怎么处理"写进一个类型一次，然后在任何字段前加一个 `@` 标记，就把那套处理"贴"了上去。字段用起来还是普通属性的样子，处理逻辑被包装器吞在背后。

学完这一章，你会明白：

- 一个 `@` 开头的标记，本质就是一个标了 `@propertyWrapper` 的类型，加上几条编译期改写规则
- `$value` 这种"美元符号写法"是从哪来的、能拿到什么
- 为什么有的包装器能挂在 `let` 字段上、有的不能
- 在自己的业务代码里，什么时候该抽出一个包装器、什么时候不该

### 模块 1：从一段重复代码出发

考虑这个需求：用户的"考试成绩"必须是 0 到 100 的整数。直觉写法：

```swift
struct Player {
    private var rawScore: Int = 0
    var score: Int {
        get { rawScore }
        set { rawScore = min(100, max(0, newValue)) }
    }

    private var rawHealth: Int = 100
    var health: Int {
        get { rawHealth }
        set { rawHealth = min(100, max(0, newValue)) }
    }
}
```

毛病很明显：

- 每多一个属性就要重写一遍 getter/setter
- 容易写错（漏 max、漏 min 都不会立刻报错）
- 改约束时要改多处

这时你脑子里应当立刻会想到"抽出一个函数 `clamp(_:to:)`"。但即便抽了函数，`get`/`set` 这套样板代码还是要重复写。

我们想要的是这种写法：

```swift
struct Player {
    @Clamped(0...100) var score: Int = 0
    @Clamped(0...100) var health: Int = 100
}
```

这正是属性包装器要解决的问题。

### 模块 2：`@propertyWrapper` 的通用结构

在看任何具体例子之前，先把"一个属性包装器长什么样"这张骨架立起来。后面所有包装器，都只是往这张骨架里填东西。

```swift
@propertyWrapper
struct W<Value> {

    /// 必需。属性名（`x`）读写时实际走的值。
    /// 包装器的核心逻辑就写在它的 get/set 里——读时怎么给、写时怎么处理。
    var wrappedValue: Value {
        get { /* 返回当前值 */ }
        set { /* 对 newValue 做你的处理，再存起来 */ }
    }

    /// 可选。声明后才支持 `@W var x = 初值` 这种带初值的写法。
    init(wrappedValue: Value)

    /// 可选。声明后才支持 `@W(参数) var x` 这种带配置的写法。
    init(wrappedValue: Value, _ options: SomeOptions)

    /// 可选。`$x` 取到的东西，用来提供"关于这个值的额外能力"。
    var projectedValue: SomeProjection
}
```

具体到每个成员是这样的：

| 成员 | 必需？ | 加上它，解锁什么 | 名字能改吗 |
| --- | --- | --- | --- |
| `wrappedValue` | **必需** | 让属性能读写——`x` 取到的就是它 | 不能，编译器专认这个名 |
| `init(wrappedValue:)` | 可选 | `@W var x = 初值`（带初值） | 不能 |
| `init(wrappedValue:, …)` | 可选 | `@W(参数) var x`（带配置） | 第一参数名必须是 `wrappedValue`，其余随你 |
| `projectedValue` | 可选 | `$x`（额外能力，如原始值、句柄） | 不能 |

关于 `wrappedValue` 还要补一点：它写成**计算属性**（带 `get`/`set`）还是**存储属性**（光一行 `var wrappedValue: Value`），由你的需要决定。

**要在读写时做处理**（trim、clamp、读写外部存储……）——写成计算属性，把逻辑放进 `get`/`set`。这是最常见的形态，本章的例子都是这种，下一节的 `@Trimmed` 就是完整的一例。

**完全不需要拦截读写**——那 `wrappedValue` 干脆就是个普通存储属性。比如只想借包装器顺便提供一个 `$` 投影，包装器本身这样声明：

```swift
@propertyWrapper
struct Logged<Value> {
    var wrappedValue: Value                 // 存储属性，读写不做任何处理
    var projectedValue: String { "当前值：\(wrappedValue)" }
}
```

用起来：

```swift
struct Demo {
    @Logged var name: String = "swift"
}

var d = Demo()
print(d.name)     // swift（和普通属性没区别）
print(d.$name)    // 当前值：swift
```

`@Logged` 没有 `get`/`set`，因为它不改变读写行为；它的价值全在 `$name` 这个投影上。

上面骨架按最常见的计算属性形态画。下面的例子也都是这种。

除这张表里的固定名字外，其余全是你的自由：

- **类型名**：占位叫 `W`，你叫它什么，用的时候就写 `@什么`
- **怎么存值**：要不要单独的存储属性、叫什么名、什么类型，都由你
- **`get`/`set` 里的逻辑**：这才是包装器真正"做的事"，每个包装器的区别就在这

一句话：写属性包装器，你真正要操心的只有**起个名**和**在 `wrappedValue` 的 `get`/`set` 里写处理逻辑**；要不要带初值、带参数、带 `$`，按需从表里挑可选成员加上去。

#### 往骨架里填最简单的一个：`@Trimmed`

现在填一个只用到必需成员的最小例子——一个"写入字符串时自动去掉首尾空白"的包装器。它只需要 `wrappedValue`，连 `init` 和 `projectedValue` 都不要：

```swift
import Foundation   // trimmingCharacters(in:) 来自 Foundation

@propertyWrapper
struct Trimmed {
    private var storage: String = ""

    var wrappedValue: String {
        get { storage }
        set { storage = newValue.trimmingCharacters(in: .whitespacesAndNewlines) }
    }
}
```

对照骨架看：`@propertyWrapper` 和 `wrappedValue` 是照搬的固定部分；`Trimmed` 这个名、`storage` 这个存储、`set` 里那行 trim，是这个包装器自己的内容。

这里有两个第一次出现的写法，顺手说清：

- **`newValue`**：在任何属性的 `set { }` 里，Swift 都会自动提供一个名叫 `newValue` 的隐式参数，代表"别人正要赋给这个属性的值"。你不用声明它，直接用就行。这里 `name = "  abc  "` 时，`newValue` 就是 `"  abc  "`，我们把它 trim 后再存进 `storage`。
- **`trimmingCharacters(in:)`**：这是 Foundation 提供的字符串方法，按你给的字符集裁掉首尾字符。传 `.whitespacesAndNewlines` 就是"去掉首尾的空格、制表符、换行"。它来自 Foundation，所以文件顶部要 `import Foundation`。

使用：

```swift
struct Form {
    @Trimmed var name: String = "  hello  "
}

var f = Form()
print("[\(f.name)]")     // [hello]
f.name = "  world  "
print("[\(f.name)]")     // [world]
```

光看用法，仿佛 `name` 是个普通字符串。背后的"自动 trim"被包装器吞掉了。

#### 编译期到底做了什么

`@Trimmed var name: String = "  hello  "` 实际被编译器改写成（伪代码）：

```swift
private var _name: Trimmed = Trimmed(wrappedValue: "  hello  ")
var name: String {
    get { _name.wrappedValue }
    set { _name.wrappedValue = newValue }
}
```

这层改写是属性包装器的整个运作核心，在这里必须说清它**为什么存在**：

- `_name` 才是真正的存储，它是一个 `Trimmed` 实例，里面装着 `storage` 和那段 trim 逻辑
- `name` 不是存储，它是个**计算属性**，类型是你声明的 `String`，作用只是给你一个"看起来像普通字符串属性"的门面
- 这层 `get`/`set` 转发，就是把"普通属性语法"接到"包装器逻辑"上的那根线：读 `name` 经 `get` 转到 `_name.wrappedValue`、写 `name` 经 `set` 转到 `_name.wrappedValue` 的 setter，trim 就发生在那一步

换句话说，这段转发代码的价值不在于"你要写它"，恰恰在于"**你不用写它**"——你只在 `Trimmed` 里把 trim 逻辑写一次，`@Trimmed` 标多少个字段，编译器就替你生成多少份这样的转发壳。没有属性包装器时（Swift 5.1 之前），这套 `_name` + getter/setter 你只能在每个属性上手写一遍。

理解了这个改写，下面所有规则就都顺理成章了。

### 模块 3：让包装器接受参数 —— 实现 `@Clamped`

`@Trimmed` 只用了骨架里唯一的必需槽。现在填模块 2 预告过的两个可选 `init` 槽，做一个能带参数的包装器。`@Clamped(0...100)` 这种写法意味着：

- 包装器有一个**额外参数**：那个范围
- 这个参数要和 `wrappedValue` 一起传给初始化器

```swift
@propertyWrapper
struct Clamped<Value: Comparable> {
    private var value: Value
    let range: ClosedRange<Value>

    init(wrappedValue: Value, _ range: ClosedRange<Value>) {
        self.range = range
        self.value = Self.clamp(wrappedValue, to: range)
    }

    var wrappedValue: Value {
        get { value }
        set { value = Self.clamp(newValue, to: range) }
    }

    private static func clamp(_ v: Value, to range: ClosedRange<Value>) -> Value {
        min(max(v, range.lowerBound), range.upperBound)
    }
}
```

用：

```swift
struct Player {
    @Clamped(0...100) var score: Int = 0
    @Clamped(0...100) var health: Int = 100
}

var p = Player()
p.score = 250
print(p.score)           // 100
p.health = -10
print(p.health)          // 0
```

#### 关键魔法：`init(wrappedValue:...)`

和模块 2 的 `_name` 同理，编译器会合成一个隐藏存储 `_score`，把 `score` 变成转发到 `_score.wrappedValue` 的门面。这个模块新增的，是**带参数的初始化器怎么被喂参数**：

```swift
private var _score = Clamped<Int>(wrappedValue: 0, 0...100)
var score: Int {
    get { _score.wrappedValue }
    set { _score.wrappedValue = newValue }
}
```

注意第一个参数名必须是 `wrappedValue`。Swift 编译器专认这个名字——它把右侧的 `= 0` 自动塞进 `wrappedValue:` 参数里，再把括号里的 `0...100` 接在后面。

这个机制不仅适用于 `@Clamped`，所有"接受参数 + 初值"的属性包装器都靠它。

### 模块 4：`projectedValue` 与 `$value` 的来源

到目前为止 `@Clamped` 只是个 getter/setter 改写器。但工程里你经常会看到 `$score` 这种"美元符号 + 属性名"的写法。它不是另一个变量，也不是某种语法糖魔法——它就是骨架里最后那个还没填的槽：`projectedValue`。

规则只有一条：**如果你在包装器类型上声明一个名为 `projectedValue` 的成员，那么 `$属性名` 就取这个成员。**

`projectedValue` 和 `wrappedValue` 是平行的两个成员，分工清晰：

- `wrappedValue` —— 普通属性名（`score`）读写到的值。**必需**。
- `projectedValue` —— `$属性名`（`$score`）取到的东西，用来提供"关于这个值的额外能力"。**可选**，不声明就不能用 `$`。

下面我们给 `Clamped` 加上 `projectedValue`，让它暴露原始未裁剪值——这样除了拿到"裁剪后的当前值"，还能顺手知道"用户原本想设成多少"：

```swift
@propertyWrapper
struct Clamped<Value: Comparable> {
    private var value: Value
    private(set) var rawValue: Value
    let range: ClosedRange<Value>

    init(wrappedValue: Value, _ range: ClosedRange<Value>) {
        self.range = range
        self.rawValue = wrappedValue
        self.value = Self.clamp(wrappedValue, to: range)
    }

    var wrappedValue: Value {
        get { value }
        set {
            rawValue = newValue
            value = Self.clamp(newValue, to: range)
        }
    }

    var projectedValue: Value {
        rawValue
    }

    private static func clamp(_ v: Value, to range: ClosedRange<Value>) -> Value {
        min(max(v, range.lowerBound), range.upperBound)
    }
}
```

用：

```swift
struct Player {
    @Clamped(0...100) var score: Int = 0
}

var p = Player()
p.score = 250
print(p.score)        // 100      ← wrappedValue
print(p.$score)       // 250      ← projectedValue
```

可以看到 `p.score` 走 `wrappedValue`（裁剪后的 100），`p.$score` 走 `projectedValue`（原始的 250）。你声明的 `projectedValue` 返回什么，`$score` 就拿到什么。

> 如果你好奇 `$` 在底层怎么落地：模块 3 讲过编译器会合成一个隐藏存储 `_score`，机械地说 `$score` 就等于 `_score.projectedValue`。但理解 `projectedValue` 时不用绕这个名字——只要记住"它是包装器上和 `wrappedValue` 平行的一个成员，`$` 去取它"就够了。

#### `projectedValue` 不一定是个值，它可以是任何类型

工程里 `projectedValue` 经常返回更复杂的东西，而不只是一个值。常见的几种设计：

- 返回**原始值 / 元数据**：像上面的 `@Clamped`，让你拿到裁剪前的输入
- 返回**包装器自身**：让你能调用它的方法（下一节 `@UserDefault` 就这么做，`s.$theme.reset()` 靠的就是它）
- 返回**一个能回写或订阅的代理对象**：让外部既能读、又能把改动写回来

最后这种最有意思：`projectedValue` 返回的不是值本身，而是"一个指向这个值的可读可写句柄"。这样别人拿着 `$value`，既能读当前值，又能把新值写回去，却不必持有整个对象。很多声明式 / 数据绑定框架就是用这个模式把 UI 控件和状态连起来的。

记住这条工程口诀：

- `wrappedValue` —— 当前的值
- `projectedValue` —— 关于这个值的额外能力

#### 回到模块 2 的骨架

到这里，模块 2 开头那张骨架的四个插槽就全部见过实物了。回头对照我们写过的三个包装器，各填了哪几个：

- `@Trimmed`（模块 2）—— 只实现 `wrappedValue`，最小形态
- `@Clamped`（模块 3、4）—— 加了带参数的 `init` 和 `projectedValue`，所以能写 `@Clamped(0...100)`、能用 `$score`
- `@UserDefault`（下一模块）—— 会让 `projectedValue` 返回包装器自身，这样 `$theme` 能调方法

后面每实现一个新包装器，都可以回到那张骨架，问自己"这次需要哪几个插槽"。

### 模块 5：实现 `@UserDefault` —— 把包装器接到外部存储

到这里你已经能写"内存里的小工具包装器"了。让我们把它落到一个真正工程级的场景：把属性自动同步到 `UserDefaults`。

需求：

```swift
struct Settings {
    @UserDefault("user.theme", default: "light") var theme: String
    @UserDefault("user.fontSize", default: 14) var fontSize: Int
}

var s = Settings()
s.theme = "dark"
// 退出 App 再进来，s.theme 还是 "dark"
```

实现：

```swift
import Foundation

@propertyWrapper
public struct UserDefault<Value> {
    public let key: String
    public let defaultValue: Value
    public let store: UserDefaults

    public init(
        wrappedValue: Value,
        _ key: String,
        store: UserDefaults = .standard
    ) {
        self.key = key
        self.defaultValue = wrappedValue
        self.store = store
    }

    public init(
        _ key: String,
        default defaultValue: Value,
        store: UserDefaults = .standard
    ) {
        self.key = key
        self.defaultValue = defaultValue
        self.store = store
    }

    public var wrappedValue: Value {
        get {
            store.object(forKey: key) as? Value ?? defaultValue
        }
        nonmutating set {
            store.set(newValue, forKey: key)
        }
    }

    public var projectedValue: UserDefault<Value> { self }

    public func reset() {
        store.removeObject(forKey: key)
    }
}
```

用：

```swift
struct Settings {
    @UserDefault("user.theme", default: "light") var theme: String
    @UserDefault("user.fontSize", default: 14) var fontSize: Int
}

var s = Settings()
s.theme = "dark"          // 写入 UserDefaults
print(s.theme)            // "dark"

s.$theme.reset()          // 清掉这个 key
print(s.theme)            // "light"（回到默认值）
```

注意几个工程细节：

#### `nonmutating set`

`UserDefault` 是个值类型（`struct`），它的 `wrappedValue` 写入路径调用的是 `store.set(...)` —— `store` 是 `UserDefaults` 这种引用类型。我们没有修改 `self` 的任何字段，所以加 `nonmutating set` 让外部用不可变引用也能写。

如果不加 `nonmutating`，下面这种用法会报错：

```swift
struct ImmutableConfig {
    @UserDefault("config.flag", default: false) var flag: Bool
}

let config = ImmutableConfig()  // ← let
config.flag = true              // 没有 nonmutating 就会编译失败
```

正因为 `@UserDefault` 的 setter 是 `nonmutating`，它才能挂在 `let` 字段上——上面 `ImmutableConfig` 里 `config` 是 `let`，依然能写 `config.flag = true`。凡是"把状态放在外部引用存储 + `nonmutating set`"的包装器，都有这个能力。

#### 两个 init 重载

注意我们写了两个初始化器：

```swift
init(wrappedValue: Value, _ key: String, store: UserDefaults = .standard)
init(_ key: String, default defaultValue: Value, store: UserDefaults = .standard)
```

第一个支持：

```swift
@UserDefault("user.theme") var theme: String = "light"
```

第二个支持：

```swift
@UserDefault("user.theme", default: "light") var theme: String
```

工程里两种写法都常见，给两个 init 是为了让用户两种风格都能写。

#### `projectedValue: UserDefault<Value>`

我们让 `$theme` 直接返回包装器自身，这样外部能调用 `s.$theme.reset()`、`s.$theme.key` 等成员方法。这是工程里非常常见的"把额外操作挂在 projection 上"的做法。

### 模块 6：在 class 上使用属性包装器

之前的例子都用在 struct 上。class 上也能用，但有一处微妙：

```swift
final class Profile {
    @Clamped(0...100) var score: Int = 0
}

let p = Profile()
p.score = 200      // ✅ 即使 p 是 let，也能写
print(p.score)     // 100
```

这是因为：

- `Profile` 是 class，存储在引用类型实例里
- `_score` 这个 `Clamped<Int>` 实例是 class 的一个字段
- 改 `_score.value` 不需要 `mutating`

所以在 class 里使用属性包装器更"无感"，但代价是失去 struct 的值语义。反过来，如果你想在值类型（`struct`）里也用一个"看似在原地修改"的包装器，就需要 struct + 内部引用存储 + `nonmutating set` 这套组合——把真正的可变状态藏在一个引用类型里，外层 struct 本身不需要 `mutating` 就能写。`@UserDefault` 走的就是这条路。

### 模块 7：把我们做过的包装器排成一张对照表

标准库里"纯语言级"的属性包装器其实非常少——属性包装器主要是给库作者和应用开发者用来抽象自己业务里的横切关注点的。所以与其去背一堆别人的包装器，不如把本章亲手实现的几个排成一张表，对照它们各自的 `wrappedValue` / `projectedValue` 形状：

| 包装器 | `wrappedValue` 类型 | `projectedValue` 类型 | 主要作用 |
| --- | --- | --- | --- |
| `@Clamped<V>` | `V` | `V`（裁剪前的原始值） | 把数值限制在闭区间内 |
| `@Trimmed` | `String` | （没暴露） | 写入时去掉首尾空白 |
| `@Capitalized` | `String` | （没暴露） | 写入时把首字母大写 |
| `@UserDefault<V>` | `V` | `UserDefault<V>`（自身，便于调用 `reset()`） | 读写穿透到 `UserDefaults` |
| `@UserDefaultCodable<V>` | `V` | `UserDefaultCodable<V>`（自身） | 把 Codable 类型 JSON 化后持久化 |

读这张表你会发现一个非常清晰的工程模式：

- **`wrappedValue` 总是"当前值"**——`@Clamped` 是裁剪后的值、`@Trimmed` 是去空白后的字符串、`@UserDefault` 是存储里读出来的值
- **`projectedValue` 要么不暴露、要么暴露"额外能力"**——原始值、或包装器自身这种"能调方法的句柄"
- 需要参数的包装器（`@Clamped(0...100)`、`@UserDefault("key", default:)`）都配套了"工厂式 init"

理解这一点之后，将来新见到一个属性包装器（不管是别的库给的，还是同事写的）你都不用慌，只要先问两个问题：

- 它的 `wrappedValue` 是什么？
- 它的 `projectedValue` 是什么？

回答这两个问题，包装器的全部行为就清楚了。

### 模块 8：属性包装器的边界与坑

下面是工程上最常踩的几个坑。

#### 坑 1：不能用在计算属性上

```swift
struct A {
    @Clamped(0...10) var value: Int { 5 }   // ❌ 编译错
}
```

属性包装器需要存储——它要把那个隐藏的 `_value` 实例放在某处。计算属性没存储，所以挂不上。

#### 坑 2：不能在 `let` 上使用（除非包装器内部是 nonmutating set）

```swift
struct A {
    @Clamped(0...10) let value: Int = 5    // ❌ 编译错
}
```

`@Clamped` 的 setter 是 `mutating` 的（因为它写 `self.value`）。`let` 表示对象不可变，但包装器需要变。

要让包装器能挂在 `let` 上，必须像 `@UserDefault` 那样把状态放在外部存储 + `nonmutating set`。

#### 坑 3：与协议的字段要求不兼容

```swift
protocol P {
    var name: String { get set }
}

struct S: P {
    @Trimmed var name: String = ""   // ✅ 没问题
}
```

这里看似没事——但你不能要求协议本身写 `@Trimmed`。包装器是实现细节，不能写进协议要求。

#### 坑 4：`init(wrappedValue:)` 的隐式调用

下面两种写法虽然长得不一样，含义是一样的：

```swift
@Clamped(0...100) var score: Int = 50
// 编译器实际生成：
// _score = Clamped<Int>(wrappedValue: 50, 0...100)
```

如果你的包装器没有 `init(wrappedValue:)`，那 `var score: Int = 50` 这种"带初值"的写法就会报错。比如一个只提供 `init(_ key:, default:)` 的包装器：必须写成 `@UserDefault("key", default: 50)`，不能用"= 50"——因为编译器找不到可以接收那个初值的 `wrappedValue:` 参数。

#### 坑 5：嵌套包装器（很少用，但偶尔会见到）

```swift
@MyOuter @MyInner var x: Int = 0
```

Swift 支持但可读性极差。工程里几乎从不这么用，知道有这种语法就行。

### 模块 9：什么时候不该用属性包装器

不是所有"自动化"都该做成包装器。下面三种情况不要用：

- **逻辑只在一个地方出现**：抽出来反而增加阅读成本，留 `didSet` 即可
- **行为依赖外部状态机**：比如要根据另一个属性的值决定怎么处理 → 用普通方法或委托
- **字段的存储已经被别的框架接管**：有些框架（比如某些 ORM / 持久化框架）要求字段用它自己的存储机制，这时候再叠一个自定义包装器会和框架的存储发生冲突

真正适合属性包装器的，是那些"和具体业务无关、纯粹是值变换或外部存储"的横切关注点。

### 模块 10：把所有概念串起来

下面是 demo 里会出现的一段代码，把本章所有要点都用上：

```swift
public struct AppSettings {
    @Clamped(0...100) public var brightness: Int = 80
    @Trimmed public var nickname: String = ""
    @UserDefault("settings.theme", default: "light") public var theme: String
    @UserDefault("settings.fontSize", default: 14) public var fontSize: Int
}
```

读这一段时关注：

- `brightness` 的 `wrappedValue` 永远在 `0...100`
- `nickname` 的 `wrappedValue` 永远没有首尾空白
- `theme` 和 `fontSize` 自动持久化到 `UserDefaults`
- 这些保证全部由"在字段前加一个 @ 标记"完成，业务代码不需要任何分支判断

同一个模板可以无限复用：值变换（`@Clamped`、`@Trimmed`）、外部存储（`@UserDefault`）、还有你将来会在各种库里见到的包装器，骨架都是这套 `wrappedValue` + `projectedValue` + `init(wrappedValue:)`。把这一章的形状记牢，以后再遇到任何 `@` 标记都能照着拆。

## 本章对应 demo

这一章 demo 在 `demos/projects/55-property-wrappers-from-zero`，是一个最小 Swift Package。

```text
55-property-wrappers-from-zero/
├─ Package.swift
├─ Sources/
│  ├─ WrapperKit/
│  │  ├─ Clamped.swift
│  │  ├─ Trimmed.swift
│  │  ├─ UserDefault.swift
│  │  └─ AppSettings.swift
│  └─ WrapperDemo/
│     └─ main.swift
└─ Tests/
   └─ WrapperKitTests/
      └─ WrapperKitTests.swift
```

## 小结

这一章我们把属性包装器的机制从头讲透了：

- 属性包装器是一个**带 `wrappedValue` 的类型 + `@propertyWrapper` 标记**
- 编译器把 `@MyWrapper var x: Int = 0` 改写成"隐藏存储 _x + 通过 wrappedValue 转发的 get/set"
- `projectedValue` 暴露在 `$x` 上，是包装器对外提供的"额外能力"
- `init(wrappedValue:)` 是连接"字段初值"和包装器构造的桥梁
- `nonmutating set` 让包装器可以挂在 class 字段、或值类型的 `let` 字段上

判断口诀：

- 看到 `@X` —— 想"它的 `wrappedValue` 是什么类型？"
- 看到 `$x` —— 想"它的 `projectedValue` 是什么类型？"

下一章我们会再补一块拼图：result builder。它负责解释为什么某些库能让你在一个闭包里直接堆叠多条语句，最后自动拼成一个结果对象。

## 练习

动手写代码的 starter 工程在 `exercises/zh-CN/projects/55-property-wrappers-from-zero-starter`；写完想对答案，参考实现与逐题讲解在 `exercises/zh-CN/answers/55-property-wrappers-from-zero.md`。

### 任务 1：实现 `@Trimmed`

写一个字符串包装器，**写入时**自动去掉首尾空白与换行；**初始化时**也要去（即 `@Trimmed var name = "  hi "` 进来就该是 `"hi"`）。

提示：除了 `wrappedValue` 的 `set`，还要实现 `init(wrappedValue:)` 并在里面也 trim 一次。

### 任务 2：实现 `@Capitalized`

写一个字符串包装器，写入时把**首字母**大写、其余字符保持原样（注意不是每个单词首字母都大写）。空串不能崩。

提示：`s.capitalized` 是"每个单词首字母大写"，不符合要求；自己取 `s.first` 大写后拼上 `s.dropFirst()`，并处理空串。

### 任务 3：实现支持半开区间的 `@ClampedHalfOpen`

仿照 `@Clamped`，但接受 `Range`（半开区间）而非 `ClosedRange`：上界不包含。例如 `@ClampedHalfOpen(0..<100)` 的最大允许值是 99。

提示：上界不包含，所以"最大允许值"要从 `upperBound` 往回推一格。想想这会对 `Value` 的类型约束提出什么要求，以及为什么 `@Clamped` 当初选了 `ClosedRange`。

### 任务 4：实现 `@UserDefaultCodable<T: Codable>`

扩展 `@UserDefault` 的思路：让它能存**任意 `Codable` 类型**。写入时把值 JSON 编码成 `Data` 存进 `UserDefaults`，读出时再反序列化回来。

提示：用 `JSONEncoder` / `JSONDecoder`；读出时若 key 不存在或解码失败，回退到默认值。

### 任务 5（思考题）：`@Clamped` 能用在 `let` 字段上吗

`@Clamped` 能不能挂在 `let` 字段上？为什么？要怎么改才能让它行？把结论和理由写下来。

提示：回顾模块 5 的 `nonmutating set`，对比 `@Clamped` 的 `set` 和 `@UserDefault` 的 `set` 有什么本质区别。
