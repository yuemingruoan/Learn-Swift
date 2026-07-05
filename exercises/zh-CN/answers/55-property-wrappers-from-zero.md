# 55. 属性包装器原理 练习答案

对应章节：

- [55. 属性包装器原理：从零实现一个 `@propertyWrapper`](../../../docs/zh-CN/chapters/55-property-wrappers-from-zero.md)

如果你想一边看答案一边运行 starter project，可以打开：

- `exercises/zh-CN/projects/55-property-wrappers-from-zero-starter`

如果你想直接运行本章练习的参考工程，也可以打开：

- `exercises/zh-CN/answers/55-property-wrappers-from-zero`

说明：

- 每道题的**完整描述**在教程正文的「练习」一节：[55. 属性包装器原理](../../../docs/zh-CN/chapters/55-property-wrappers-from-zero.md#练习)。这里只放参考实现与逐题讲解。
- 本章练习围绕"自己实现常用属性包装器"展开，重点是把 `wrappedValue`、`projectedValue`、`init(wrappedValue:)`、`nonmutating set` 这几件事都亲手过一遍。

## 任务 1：实现 `@Trimmed`

> 写入与初始化时都自动去掉字符串首尾空白。（完整描述见正文）

### 参考实现

```swift
@propertyWrapper
public struct Trimmed {
    private var storage: String

    public init(wrappedValue: String) {
        self.storage = wrappedValue.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    public var wrappedValue: String {
        get { storage }
        set { storage = newValue.trimmingCharacters(in: .whitespacesAndNewlines) }
    }
}
```

### 解题点评

- `init(wrappedValue:)` 是连接"= 默认值"和构造器的桥梁，不能省
- `init` 里也要 trim 一次，否则 `var name = "  hi "` 进来就是带空格的
- 如果你只在 `set` 里 trim，第一次访问 `wrappedValue` 时会拿到没 trim 的初值

## 任务 2：实现 `@Capitalized`

> 写入时把字符串首字母大写、其余不变。（完整描述见正文）

### 参考实现

```swift
@propertyWrapper
public struct Capitalized {
    private var storage: String

    public init(wrappedValue: String) {
        self.storage = Self.capitalize(wrappedValue)
    }

    public var wrappedValue: String {
        get { storage }
        set { storage = Self.capitalize(newValue) }
    }

    private static func capitalize(_ s: String) -> String {
        guard let first = s.first else { return s }
        return first.uppercased() + s.dropFirst()
    }
}
```

### 解题点评

- 有人会写 `s.capitalized`，但这是把每个单词首字母大写，不符合需求
- `s.first?.uppercased()` 返回 `String?`，不是 `Character`，要 `+` 上 `s.dropFirst()` 才能拼出完整字符串
- 空串要单独处理（`first` 是 `nil`），否则会 crash

## 任务 3：支持 `Range`（半开区间）的 `ClampedHalfOpen`

> 仿 `@Clamped`，但用 `Range`，上界不包含（`0..<100` 最大值是 99）。（完整描述见正文）

### 参考实现

```swift
@propertyWrapper
public struct ClampedHalfOpen<Value: Comparable & Strideable> where Value.Stride: SignedInteger {
    private var value: Value
    public let range: Range<Value>

    public init(wrappedValue: Value, _ range: Range<Value>) {
        self.range = range
        self.value = Self.clamp(wrappedValue, to: range)
    }

    public var wrappedValue: Value {
        get { value }
        set { value = Self.clamp(newValue, to: range) }
    }

    private static func clamp(_ v: Value, to range: Range<Value>) -> Value {
        let upperInclusive = range.upperBound.advanced(by: -1)
        if v < range.lowerBound { return range.lowerBound }
        if v > upperInclusive { return upperInclusive }
        return v
    }
}
```

### 解题点评

- `Range<Value>` 上界不包含，所以"最大允许值"必须靠 `advanced(by: -1)` 推回去
- 因此 `Value` 必须 `Strideable`，且 `Stride` 是 `SignedInteger`
- 这条约束意味着你的包装器只能挂在 `Int`、`Int64` 这种整数类型上，不能挂在 `Double` 上
- 想支持 `Double`？那就用 `ClosedRange` 而不是 `Range`，让上界包含。这是为什么 `@Clamped` 用 `ClosedRange` 的工程理由

## 任务 4：实现 `@UserDefaultCodable<T: Codable>`

> 把任意 `Codable` 类型 JSON 编码后存入 `UserDefaults`，读出时反序列化。（完整描述见正文）

### 参考实现

```swift
@propertyWrapper
public struct UserDefaultCodable<Value: Codable> {
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
            guard let data = store.data(forKey: key),
                  let decoded = try? JSONDecoder().decode(Value.self, from: data) else {
                return defaultValue
            }
            return decoded
        }
        nonmutating set {
            guard let data = try? JSONEncoder().encode(newValue) else { return }
            store.set(data, forKey: key)
        }
    }

    public var projectedValue: UserDefaultCodable<Value> { self }

    public func reset() {
        store.removeObject(forKey: key)
    }
}
```

### 解题点评

- `UserDefaults` 不能直接存 `Codable` 类型，必须先转成 `Data`
- 失败时（解码错误 / key 不存在）用默认值兜底是工程上更稳的选择
- `nonmutating set` 让它能挂在 `let` 字段上（和 `@UserDefault` 同理）
- 把 `projectedValue` 设为 `self`，外部就能用 `s.$address.reset()` 访问 `reset` 方法

## 任务 5（思考题）：`@Clamped` 能用在 `let` 字段上吗

> `@Clamped` 能否挂在 `let` 上？为什么？怎么改？（完整描述见正文）

### 参考回答

不能。原因：

```swift
struct A {
    @Clamped(0...10) let v: Int = 5  // ❌
}
```

`Clamped<Int>` 的 setter 是 `mutating`（要写 `self.value`）。`let` 表示这个属性永远不能写，但属性包装器的展开形式实际上需要 `setter`，因此 Swift 编译器拒绝。

要让它能挂在 `let` 上有两条路：

1. **包装器内部状态都是不可变的，且永远不需要写** —— 但这样 `Clamped` 就没意义了，因为它本质就是要在写入时裁剪
2. **把状态外置到引用类型 + `nonmutating set`** —— 这就是 `@UserDefault` 的做法

具体改造：

```swift
@propertyWrapper
public struct ClampedRef<Value: Comparable> {
    private final class Box {
        var value: Value
        init(_ v: Value) { value = v }
    }
    private let box: Box
    public let range: ClosedRange<Value>

    public init(wrappedValue: Value, _ range: ClosedRange<Value>) {
        self.range = range
        let clamped = min(max(wrappedValue, range.lowerBound), range.upperBound)
        self.box = Box(clamped)
    }

    public var wrappedValue: Value {
        get { box.value }
        nonmutating set {
            box.value = min(max(newValue, range.lowerBound), range.upperBound)
        }
    }
}
```

代价：

- 引入了引用类型（一个内部 `class Box`）
- 失去了 struct 的纯值语义（多个变量共享同一个包装器实例时会互相影响）

工程上一般不这么做，除非你确实需要把它挂在 `let` 字段上。

## 自检清单

完成本章练习后，你应当能脱口回答：

- 编译器看到 `@MyWrapper var x: Int = 5` 时会展开成什么？
- `wrappedValue` 和 `projectedValue` 各自的角色是什么？
- 为什么 `@UserDefault` 能挂在 `let` 字段上？
- 为什么 `@Clamped` 默认不能？
- `init(wrappedValue:)` 在编译期被怎么调用？

如果其中任意一条不能立刻回答出来，建议回到正文相应模块再读一遍。
