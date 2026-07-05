# 57. KeyPath / Identifiable / @MainActor 练习答案

对应章节：

- [57. KeyPath、Identifiable 与 @MainActor：三个高频工程话题](../../../docs/zh-CN/chapters/57-keypath-identifiable-and-mainactor.md)

如果你想一边看答案一边运行 starter project，可以打开：

- `exercises/zh-CN/projects/57-keypath-identifiable-and-mainactor-starter`

如果你想直接运行本章练习的参考工程，也可以打开：

- `exercises/zh-CN/answers/57-keypath-identifiable-and-mainactor`

说明：

- 每道题的**完整描述**在教程正文的「练习」一节：[57. KeyPath、Identifiable 与 @MainActor](../../../docs/zh-CN/chapters/57-keypath-identifiable-and-mainactor.md#练习)。这里只放参考实现与逐题讲解。
- 本章练习不长，但每一题都对应一个写真实 Swift 工程时高频出现的能力
- 如果你能不查文档把这四题都讲清楚，以后写有数据模型、有并发的代码时，基本不会遇到"为什么我的代码编不过 / 为什么数据没按预期更新"这两类莫名其妙的问题

## 任务 1：用 KeyPath 实现通用 `groupBy`

> 写一个泛型 `groupBy(_:by:)`，按 KeyPath 指定的属性把元素分组成 `[Key: [Element]]`。（完整描述见正文）

### 参考实现

```swift
public func groupBy<Element, Key: Hashable>(
    _ items: [Element],
    by keyPath: KeyPath<Element, Key>
) -> [Key: [Element]] {
    Dictionary(grouping: items) { $0[keyPath: keyPath] }
}
```

### 解题点评

- 关键是知道 Swift 标准库已经有 `Dictionary(grouping:by:)`，我们只是把传 `by:` 闭包的方式换成 KeyPath
- `$0[keyPath: keyPath]` 是 KeyPath 的"取值语法"，等价于 `$0.country`，但这个属性是参数指定的、可换的
- `Key: Hashable` 这个约束不能省——`Dictionary` 的键必须 Hashable
- 不要把 `Element` 加 `Hashable` 约束，那是常见的过度约束。`Element` 只是被分组的值，不需要本身可哈希

### 工程上的延伸

这个 `groupBy` 在真实代码里还会有几个常见的兄弟函数，都是同一个套路：

```swift
func sorted<Element, Key: Comparable>(
    _ items: [Element],
    by keyPath: KeyPath<Element, Key>
) -> [Element] {
    items.sorted { $0[keyPath: keyPath] < $1[keyPath: keyPath] }
}

func uniqued<Element, Key: Hashable>(
    _ items: [Element],
    by keyPath: KeyPath<Element, Key>
) -> [Element] {
    var seen = Set<Key>()
    return items.filter { seen.insert($0[keyPath: keyPath]).inserted }
}
```

这套 KeyPath 写法在数据处理、排序、筛选里几乎天天用到。

## 任务 2：为会重复的数据设计稳定 `id`

> 给内容可能重复的 `Message` 设计一个稳定且独立的 `id` 并实现 `Identifiable`，让同文消息也能被区分。（完整描述见正文）

### 参考实现

```swift
public struct Message: Identifiable, Equatable {
    public let id: UUID
    public let text: String
    public init(id: UUID = UUID(), text: String) {
        self.id = id
        self.text = text
    }
}

let messages = [
    Message(text: "hello"),
    Message(text: "hello"),
]
// 这两条 text 相同，但 id 不同，能被稳定区分
```

### 解题点评

- `id: UUID` 让两条 `text` 相同的消息也能被区分开，不会被当成同一个
- `init(id: UUID = UUID(), text: String)`：默认参数让平时构造不必传 `id`，但单元测试里需要"两条 id 不同的消息"时也能显式控制
- 实现 `Identifiable` 之后，任何按身份比对这批数据的逻辑（diff、缓存、列表渲染）都能直接用 `id`，不用再纠结"内容相同算不算同一个"

### 为什么不要拿"内容本身"当身份

拿整个值当身份（相当于 `\.self`）意味着：

- 类型必须 `Hashable`
- 两个"内容完全相同"的值会被认为是同一个
- 任何做差量更新的系统在比对时会把它们合并成一条、丢弃多出来的——结果就是同文消息只剩一条

只要数据有可能出现重复，就一定要给它一个稳定且独立的 `id`，不能拿内容充当身份。

### 一个隐藏陷阱：每次构造都生成新 UUID

注意我们 `init` 里写的是 `id: UUID = UUID()`，这意味着只要你重新构造 `Message`，`id` 就变了。

工程上的两种做法：

- **可变数据，从外部传入**：`Message(id: dto.id, text: dto.text)`，`id` 从后端 / 数据库带过来
- **本地数据**：`let m = Message(text: "hi")` 一次构造、长期持有，不要在每次刷新数据时都重新 `Message(text: ...)`，否则 id 永远在变，任何依赖"id 稳定"的差量逻辑都没法正常工作

这条在写涉及数据更新的代码时反复会踩，记住"id 必须在生命周期内稳定"这一句就够。

## 任务 3：给 `@MainActor` 类加 `nonisolated` 方法

> 给 `@MainActor` 的 `Counter` 加一个 `nonisolated` 的 `formatTimestamp(_:)`，并写测试从非 MainActor 上下文调用它。（完整描述见正文）

### 参考实现

```swift
@MainActor
public final class Counter {
    public private(set) var value: Int = 0
    public init() {}
    public func increment() { value += 1 }

    public nonisolated func formatTimestamp(_ d: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd HH:mm"
        return f.string(from: d)
    }
}
```

测试调用：

```swift
@Test("nonisolated 方法可以从非 MainActor 上下文直接调用")
func nonisolatedFromOutside() async {
    let counter = await Counter()
    let s = counter.formatTimestamp(Date(timeIntervalSince1970: 0))
    #expect(!s.isEmpty)
}
```

### 解题点评

- `@MainActor` 类的 `init` 默认也是 `@MainActor` 隔离的，所以从非 MainActor 测试函数里构造它要 `await Counter()`
- `nonisolated` 方法不能访问任何被隔离的可变状态。这里 `formatTimestamp` 不读写 `value`，所以编译通过
- 如果在 `formatTimestamp` 里加一句 `_ = self.value`，编译器会立刻报错：`main actor-isolated property 'value' can not be referenced from a non-isolated context`——这正是 `nonisolated` 想要的安全保证

### 为什么这条很重要

在很多工程里，管理 UI 状态或共享状态的对象常被标 `@MainActor`。而它身上常常有一些"纯函数"性质的工具方法：

- 格式化时间、金额
- 把 `enum` 翻成展示文字
- 校验输入合法性

这些方法既然不依赖 ViewModel 的状态，就该标 `nonisolated`，让它们能在任意上下文里被调用——尤其是后台任务、Sequence map、单元测试。这能避免把"调一个 format 函数也得 await 一下"的别扭代码扩散到整个项目。

### 还有一类常被忽略的场景：`Equatable` / `Hashable`

如果你给 `@MainActor` 的类实现 `Equatable`：

```swift
@MainActor
final class VM: Equatable {
    static func == (lhs: VM, rhs: VM) -> Bool {  // ⚠️
        lhs === rhs
    }
}
```

这个 `==` 会变成 MainActor 隔离，意味着任何 `[VM]` 类型的 `contains` / `firstIndex` 等都得 `await`，痛苦且毫无收益。正确做法：

```swift
nonisolated static func == (lhs: VM, rhs: VM) -> Bool {
    lhs === rhs
}
```

记住一句：不依赖隔离状态的成员，就标 `nonisolated`。

## 任务 4（思考题）：`Task.detached` vs 独立 actor

> 何时用 `Task.detached` 扔重活、何时让独立 actor 跑重活，两者对内存与并发安全模型有何区别？（完整描述见正文）

### 参考答案

#### 1. 它们的本质区别

| 维度 | `Task.detached` | 独立 actor |
| --- | --- | --- |
| 形态 | "派一次活"，临时的 | "派一个工人"，长期存在 |
| 隔离 | 默认 nonisolated，不继承调用方 actor | actor 内部串行执行所有方法 |
| 状态 | 不持有可变状态 | 可以持有自己的可变状态 |
| 生命周期 | 任务结束就消失 | 引用计数管理，可能长期存活 |
| 取消传播 | 不继承父任务的取消 | 与 actor 无关，看 Task 自己 |

#### 2. 各自的最佳使用场景

**`Task.detached` 适合：**

- 跑一个一次性的纯计算（解析一段 JSON、压缩一张图片、计算一组哈希）
- 调用一个本就线程安全的同步 API（例如 `Data(contentsOf:)`、`CryptoKit`），但你不想让它阻塞当前 actor
- 不希望继承当前的优先级或 task-local 值

```swift
let result = await Task.detached(priority: .background) {
    heavyImageProcessing(data)
}.value
```

**独立 actor 适合：**

- 多个调用方需要安全地共享某段可变状态（计数器、缓存、连接池）
- 状态本身有"必须串行"的语义（写入一个本地数据库、维护一个上传队列）
- 你想给这块逻辑一个明确的所有权边界，让别处只能通过 await 与之交互

```swift
actor ImageCache {
    private var store: [URL: Data] = [:]
    func image(for url: URL) -> Data? { store[url] }
    func put(_ data: Data, for url: URL) { store[url] = data }
}
```

#### 3. 内存与生命周期的差异

- **`Task.detached`**：任务里捕获的对象走闭包捕获语义。任务运行结束、`.value` / 取消之后，捕获被释放。短任务内存压力小
- **独立 actor**：本身是一个引用类型，常常以 singleton 或被 ViewModel/Service 持有的形式存在。它内部的 `store` 直到 actor 自己被释放都不会清。如果它持有大对象（图片缓存、文件句柄），需要主动设计淘汰策略

#### 4. 并发安全模型的差异

- **`Task.detached`**：不解决"多人同时改一份数据"的问题。如果你只是把多个 detached Task 同时写一份共享变量，并发问题原封不动还在
- **独立 actor**：天然解决"同一份状态串行访问"的问题。actor 的方法被天然序列化，不可能两个调用方同时跑到同一个 mutating 上

#### 5. 工程上常见的搭配

把两者一起用是最常见的写法：

```swift
actor DownloadManager {
    private var inFlight: [URL: Task<Data, Error>] = [:]

    func data(for url: URL) async throws -> Data {
        if let task = inFlight[url] { return try await task.value }
        let task = Task.detached {  // 真正的下载工作 detach 出去
            try await URLSession.shared.data(from: url).0
        }
        inFlight[url] = task
        defer { inFlight[url] = nil }
        return try await task.value
    }
}
```

- `actor` 守护 `inFlight` 这块共享状态
- `Task.detached` 把真正的网络下载从这条 actor 串行队列里搬走，避免"一个慢的下载阻塞所有别的请求查表"

### 一个简短的判断口诀

- **要存东西**：用 actor
- **只算一次**：用 Task.detached
- **既要存又要算**：actor 守门 + 内部 `Task.detached` 干重活

## 自检清单

完成本章练习后，你应当能脱口回答：

- `KeyPath<Root, Value>` 跟传函数 `(Root) -> Value` 比有什么优势？
- `Identifiable` 的 `id` 必须满足什么条件？为什么 `\.self` 在工程上是反例？
- `@MainActor` 类上加 `nonisolated` 方法的典型场景是什么？什么时候不能加？
- `Task.detached` 跟 actor 的边界划分？

如果这四条里有任意一条卡壳，回到正文相应模块再读一遍。下一章我们会进入 Swift Macros：很多 `@` 和 `#` 开头的标记背后，都是宏在编译期帮你生成代码。
