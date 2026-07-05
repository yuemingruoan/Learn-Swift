# 57. KeyPath、`Identifiable` 与 `@MainActor`：三个高频工程话题

## 阅读导航

- 前置章节：[13. 结构体与自定义类型](./13-structs-and-custom-types.md)、[14. 数组与字典](./14-arrays-and-dictionaries.md)、[21. 协议：灵活的抽象](./21-protocols-flexible-abstraction.md)、[26. 高阶集合操作](./26-higher-order-collection-operations.md)、[31. Actor 与状态隔离](./31-actor-state-isolation.md)
- 上一章：[56. Result Builder 与 DSL：从语法转写到 mini HTML builder](./56-result-builders-and-mini-dsl.md)
- 下一章：[58. Swift 宏入门：读懂展开、写一个最小 freestanding 宏](./58-swift-macros-from-zero.md)
- 适合谁读：已经熟悉协议、泛型、闭包、并发基础，但对 `\Person.name` 这种反斜杠语法、`Identifiable` 协议、`@MainActor` 的精确语义还没建立稳定心智模型的读者

## 本章目标

学完这一章后，你应该能够：

- 看懂 `\Type.property` 这种 KeyPath 字面量，并区分 `KeyPath`、`WritableKeyPath`、`ReferenceWritableKeyPath`
- 用 KeyPath 写出 `array.sorted(using: KeyPathComparator(\.name))` 这类调用
- 用 KeyPath 实现一个简易的"通用属性比较器"
- 解释 `Identifiable` 协议的最小要求与典型实现
- 说清为什么"按身份比对前后两批数据"的场景（diff、缓存、列表渲染）几乎总要求稳定的 `id`
- 区分"用 `id: \.id`" 与"用 `id: \.self`"的代价
- 解释 `@MainActor` 标在类型、方法、属性上的不同语义
- 理解 `@MainActor` 的语义：为什么标了 `@MainActor` 的类型的方法默认在主线程跑、`await` 之后控制权如何回到主线程
- 在写涉及并发的代码前主动判断：这一段需不需要 `@MainActor`、是否需要切线程

## 本章对应资源

- 文稿：`docs/zh-CN/chapters/57-keypath-identifiable-and-mainactor.md`
- 示例项目：`demos/projects/57-keypath-identifiable-and-mainactor`
- 练习答案：`exercises/zh-CN/answers/57-keypath-identifiable-and-mainactor.md`
- 练习 starter：`exercises/zh-CN/projects/57-keypath-identifiable-and-mainactor-starter`

## 本章怎么读

建议阅读顺序：

1. 先把 KeyPath 学清楚——它会在排序、分组、各种数据查询 API 里反复出现
2. 再看 `Identifiable`，把"一个集合中的每个元素必须有稳定标识"这件事固化下来
3. 最后讨论 `@MainActor`，对接第 31 章的 actor 知识

## 正文主体

### 模块 0：为什么把这三个话题放一章

这三个话题——KeyPath、`Identifiable`、`@MainActor`——单拎出来都不够撑满一章，但它们有一个共同点：**只要你写的程序里有数据模型、有集合操作、有并发**，就几乎一定会同时遇到它们。

- **KeyPath** 解决"如何把'某个属性'当成一个值来传递"：排序、分组、筛选、通用工具函数都靠它。
- **`Identifiable`** 解决"集合里的每个元素如何稳定地表示身份"：任何需要比对前后两批数据、做差量更新或缓存的逻辑都需要它。
- **`@MainActor`** 解决"某些代码必须在主线程跑"这件事：只要程序里有"必须串行、必须在某个固定执行流上"的约束（典型的就是更新界面），就会用到它。

把它们放在同一章，是因为在真实工程里它们经常一起出现：你定义一个 `Identifiable` 的数据模型，用 KeyPath 给它排序，再把这套状态交给一个 `@MainActor` 的对象统一管理。先把三件事各自讲透，等到真正写有数据、有并发的程序时，就不会三个概念一起砸过来。

### 模块 1：KeyPath 是什么

先看一段 Swift 写法：

```swift
struct Person {
    var name: String
    var age: Int
}

let p = Person(name: "Tim", age: 30)
let nameKP = \Person.name        // 这是一个 KeyPath
print(p[keyPath: nameKP])        // "Tim"
```

`\Person.name` 是一个**字面量**，类型是 `WritableKeyPath<Person, String>`。它的含义是：

- "从 `Person` 走到它的 `name` 属性的路径"
- 它本身**不是当前的值**，是描述"怎么去取这个值"

用法：

- 读：`p[keyPath: kp]`
- 写：`p[keyPath: kp] = "Cook"`（如果是可写路径且变量是 `var`）

#### KeyPath 的几个类型

KeyPath 的类型族按"读写权限"分了几档：

| 类型 | 含义 | 例子 |
| --- | --- | --- |
| `KeyPath<Root, Value>` | 只读路径 | `\Person.fullName`（如果是 computed 只读属性） |
| `WritableKeyPath<Root, Value>` | 可写路径，但写入要 `Root` 是 `var` | `\Person.name`（`Person` 是 struct） |
| `ReferenceWritableKeyPath<Root, Value>` | 引用类型上可写，即使 `Root` 是 `let` | `\PersonClass.name`（`PersonClass` 是 class） |
| `PartialKeyPath<Root>` | 不知道值类型 | 类型擦除使用 |
| `AnyKeyPath` | 不知道 Root 也不知道值 | 极少用 |

工程里 90% 的场景只用前三种。

#### KeyPath 不是闭包

很多人第一次见会想"这是不是 `{ $0.name }` 的语法糖"。不完全是。两者的关键差别：

- KeyPath 是**值**，可以放进字典、传参、序列化
- KeyPath 是**结构化的**：编译器知道它指向 `Person` 的 `name` 属性，不是任意 `String`
- 闭包是不透明的：`{ $0.name }` 类型是 `(Person) -> String`，外部看不到"它取的是哪个属性"

正是这种"结构化"让 KeyPath 能被各种排序、查询、序列化 API 用作"声明式描述"的基础——你交给它的不是一段不透明的代码，而是一个编译器能看懂、能检查类型的属性引用。

### 模块 2：KeyPath 的常见工程用法

#### 用 1：`map(\.property)` 提取属性

```swift
let people = [
    Person(name: "Tim", age: 30),
    Person(name: "Cook", age: 60),
]

let names = people.map(\.name)        // ["Tim", "Cook"]
```

`map(\.name)` 等价于 `map { $0.name }`，但更短、更清晰。Swift 5.2 起 `map`、`filter`、`reduce` 都接受 KeyPath。

#### 用 2：`sorted(using: KeyPathComparator(...))`

```swift
let sortedByAge = people.sorted(using: KeyPathComparator(\.age))
let sortedByName = people.sorted(using: KeyPathComparator(\.name, order: .reverse))
```

`KeyPathComparator` 是 Foundation 提供的一个工具，专门用于"按某个属性排序"。它要求那个属性的类型遵守 `Comparable`。

可以叠多个：

```swift
let multi = people.sorted(using: [
    KeyPathComparator(\.age, order: .forward),
    KeyPathComparator(\.name, order: .forward),
])
```

工程上这是替代手写排序闭包的首选。

#### 用 3：把 KeyPath 当作"参数"传

写一个通用查找函数：

```swift
func find<Root, Value: Equatable>(
    _ items: [Root],
    where keyPath: KeyPath<Root, Value>,
    equals value: Value
) -> Root? {
    items.first { $0[keyPath: keyPath] == value }
}

let timothy = find(people, where: \.name, equals: "Tim")
```

注意：

- `keyPath: KeyPath<Root, Value>` —— 任意"从 Root 取出 Value"的路径
- `Value: Equatable` —— 路径终点的值需要可比较
- 这种写法比用 `(Root) -> Value` 闭包更结构化，能配合 `Hashable` / `Equatable` / `KeyPathComparator` 一起用

工程项目里"按字段筛选 / 排序 / 比较"的通用逻辑，几乎都会沿着这个套路写。

#### 用 4：`Dictionary(grouping:by:)` 与 `sorted(by:)`

标准库里好几个集合 API 都天然吃 KeyPath，因为它们要的就是"从元素里取出某个字段"：

```swift
// 按首字母分组
let byInitial = Dictionary(grouping: people) { $0.name.first! }

// 用闭包配合 KeyPath 取值排序
let byAge = people.sorted { $0[keyPath: \.age] < $1[keyPath: \.age] }
```

如果你把"取哪个字段"做成参数，就能写出复用度很高的工具函数（本章练习里的 `groupBy` 就是这个套路）：

```swift
func groupBy<Element, Key: Hashable>(
    _ items: [Element],
    by keyPath: KeyPath<Element, Key>
) -> [Key: [Element]] {
    Dictionary(grouping: items) { $0[keyPath: keyPath] }
}

let grouped = groupBy(people, by: \.age)   // [Int: [Person]]
```

#### 用 5：`KeyPathComparator` / `SortDescriptor` 指定排序字段

很多数据查询和排序 API 都用 KeyPath 来指定"按哪个字段排"。Foundation 的 `SortDescriptor` 就是一个纯标准库的例子：

```swift
let descriptors = [
    SortDescriptor(\Person.age, order: .forward),
    SortDescriptor(\Person.name, order: .forward),
]
let sorted = people.sorted(using: descriptors)
```

`SortDescriptor(\.age)` 把"用 `age` 这个字段排序"打包成一个可存储、可传递的值。和前面的 `KeyPathComparator` 一样，这是 KeyPath"把字段当值传"能力的直接体现：你可以把一组排序规则放进数组、塞进配置、按运行时条件拼装，而不必写死一堆排序闭包。

### 模块 3：写一个用 KeyPath 的"通用属性变更器"

这是 demo 里会出现的工程小工具：

```swift
public func update<Root, Value>(
    _ object: inout Root,
    _ keyPath: WritableKeyPath<Root, Value>,
    to value: Value
) {
    object[keyPath: keyPath] = value
}

var p = Person(name: "Tim", age: 30)
update(&p, \.age, to: 31)
print(p.age)   // 31
```

或者更工程化一点，封装一个"批量变更"：

```swift
public struct Patch<Root> {
    public let apply: (inout Root) -> Void

    public static func set<Value>(
        _ keyPath: WritableKeyPath<Root, Value>,
        to value: Value
    ) -> Patch<Root> {
        Patch { obj in obj[keyPath: keyPath] = value }
    }
}

extension Patch {
    public static func combined(_ patches: [Patch<Root>]) -> Patch<Root> {
        Patch { obj in patches.forEach { $0.apply(&obj) } }
    }
}

var p2 = Person(name: "Tim", age: 30)
Patch.combined([
    .set(\.name, to: "Cook"),
    .set(\.age, to: 60),
]).apply(&p2)
```

读这一段时关注：

- `Patch<Root>` 是一个能"对 `Root` 做修改"的描述
- `Patch.set(\.name, to: ...)` 把"哪个属性 + 新值"打包成可传递的对象
- 这是工程里"声明式更新"的最小骨架

后面各种"把一组修改打包、延迟应用"的状态管理套路（比如 Redux 风格的 reducer）都会用到类似写法。

### 模块 4：`Identifiable` 协议

`Identifiable` 是标准库里一个只有单一要求的协议：提供一个稳定、可哈希的 `id`。下面把这个要求和工程里最常见的实现模板放在一处看。

#### 工程里典型实现

这是 `Identifiable` 的标准骨架——协议的唯一要求，加上一个最常见的实现模板：

```swift
/// 标准库协议。唯一要求：提供一个能在实例生命周期内稳定、可唯一标识实例的 `id`。
/// `<ID>` 是主关联类型（见第 54 章），因此可以写成 `Identifiable<UUID>` 这种带尖括号的约束。
public protocol Identifiable<ID> {
    /// `id` 的类型。约束就是 `Hashable`——差量算法要拿它进 `Set`/字典做快速查找。
    associatedtype ID: Hashable

    /// 唯一要求：一个稳定、可唯一标识实例的 id（只读）。
    var id: ID { get }
}

// 典型实现：用 `UUID` 自动生成一个稳定 id
struct TodoTask: Identifiable {
    /// 用 `let` 而不是 `var`：id 必须在实例生命周期内稳定，绝不随其它字段变化。
    let id: UUID
    var title: String
}
```

记三件事：

- **id 必须稳定**：用 `let` 声明，创建后不再变。一旦 id 变了，差量算法就会把同一个对象误判成"旧的没了、来了个新的"。
- **id 必须 `Hashable`**：这是 `ID` 的唯一约束，这样它能进 `Set`/字典被快速查找。
- **类型不限于 `UUID`**：任何 `Hashable` 类型都行——下面三种是工程里最常见的几种 id 来源。

```swift
struct User: Identifiable {
    let id: UUID
    let name: String
}

struct Order: Identifiable {
    let id: Int          // 数据库主键
    let title: String
}

struct Tag: Identifiable {
    let id: String       // "swift", "concurrency"
    let displayName: String
}
```

对照本章的 demo：`TaskKit` 里的 `TodoTask: Identifiable` 用的就是这套骨架（`let id` + 业务字段），`TaskListVM` 对它做增删改查时，正是靠这个稳定 `id` 来定位每一条记录。后面写任何"一组有身份的数据"时，都可以回到这张骨架。

#### `Identifiable` 与 `Hashable` 不一样

很多人会混。区分清楚：

| 协议 | 描述什么 | 用在什么场景 |
| --- | --- | --- |
| `Hashable` | "两个值是否相等" | 放进 `Set` / `Dictionary` 的 key |
| `Identifiable` | "两个对象是不是同一个东西" | 列表渲染、缓存、差量更新 |

举例说明：

```swift
struct User: Identifiable, Hashable {
    let id: UUID
    var name: String
}

let a = User(id: someUUID, name: "Tim")
var b = a
b.name = "Cook"

// a == b ? 不相等：name 不同（Hashable 角度）
// a 和 b 是同一个用户吗？是：id 相同（Identifiable 角度）
```

做差量更新的系统（比如列表 UI、diff 算法、缓存）看到 `id` 不变、`name` 变了，会认为"还是同一个对象，只是某个字段更新了"，于是只更新变化的部分——这正是 `Identifiable` 工作的根本意义。如果改用 `Hashable` 做差量比较，`a != b` 就会被当成另一个对象，整条记录被丢弃重建，与之关联的状态全丢。

### 模块 5：稳定 `id` 为什么重要——以"按身份比对两批数据"为例

很多场景都需要拿"前一批数据"和"后一批数据"做比对，找出"哪些是新增的、哪些被删了、哪些只是字段变了"。这类逻辑统称差量（diff）：列表渲染要靠它决定刷新哪几行，缓存要靠它决定哪些条目失效，同步逻辑要靠它决定推送哪些变更。

差量的前提是：**能稳定地判断"前后两批里的两个元素是不是同一个东西"**。这恰好就是 `Identifiable` 要解决的问题。判断"是不是同一个"有两种思路：

```swift
// 思路 A：用稳定 id 比对
old.first { $0.id == new.id }      // id 相同 → 同一个对象，只是字段可能变了

// 思路 B：用整个值比对（相当于 \.self）
old.contains(new)                  // 要求元素 Hashable / Equatable
```

#### 用整个值当身份（相当于 `\.self`）的隐患

"思路 B"听上去省事——不用单独维护 `id`，直接拿元素本身比。但它要求元素是 `Hashable`，而且有个大坑：

- "用整个值当身份"意味着**两个内容完全相同的元素会被认为是同一个**
- 如果元素是带可变字段的 struct（比如下面的 `TodoTask`），改了任何一个字段，它的 `hashValue` 就变了
- 于是差量逻辑会把"改了字段的同一个对象"误判成"旧的没了、来了个新的"，导致整条记录被丢弃重建，关联状态全部丢失

```swift
struct TodoTask: Identifiable, Hashable {
    let id: UUID
    var title: String
    var isDone: Bool
}

var t = TodoTask(id: someUUID, title: "写章节", isDone: false)
let h1 = t.hashValue
t.isDone = true
let h2 = t.hashValue
// h1 != h2：字段一变，hashValue 就变了
// 但 t.id 始终没变——它还是同一件待办
```

#### 实践结论

- 元素本身**不可变 + 单纯**（`String`、`Int`、纯枚举）→ 用整个值当身份没问题
- 元素是带可变字段的复合类型 → 一定要让它实现 `Identifiable`，用稳定的 `id` 当身份

还有一个常被忽略的场景：**重复值**。假设你有一批字符串：

```swift
let messageTexts = ["hello", "hello", "world"]
```

如果用"整个值当身份"来比对，前两个 `"hello"` 会被当成同一个，差量结果就错了。只要数据有可能重复，就必须给每条记录一个独立稳定的 `id`，而不是拿内容本身充当身份。

工程上的稳妥做法是**永远给业务实体写 `Identifiable`**，只对临时拼接的简单值才考虑用整个值当身份。

### 模块 6：`@MainActor` 是什么

很多场景要求某些代码**必须在主线程跑**——最典型的就是更新界面，但也包括一些只允许在主线程访问的系统 API。Swift 并发用 `@MainActor` 来表达"这段代码必须在主线程上执行"这件事。这个"主线程"在 Swift 并发模型里叫 `MainActor`，是一个**全局 actor**。

```swift
@globalActor
public actor MainActor {
    public static let shared = MainActor()
}
```

`@MainActor` 的作用是把"必须在 MainActor 上运行"的约束加在某段代码上。

#### 三种标注位置

```swift
// 1. 标在类型上：所有成员默认在 MainActor 上
@MainActor
class ViewModel {
    var users: [User] = []
    func reload() async { /* 自动在主线程 */ }
}

// 2. 标在方法上：只对这个方法生效
class Service {
    @MainActor
    func updateUI() { ... }
}

// 3. 标在属性上：只对这个属性生效
class Mixed {
    @MainActor var snapshot: [Item] = []
    func compute() { /* 这里不在 MainActor */ }
}
```

#### 与第 31 章的普通 `actor` 的差别

普通 `actor`：

- 每实例化一个就有一个隔离域
- 多个实例互相独立

`MainActor`：

- 进程内**只有一个**
- 跨多个类型、跨多个文件，标了 `@MainActor` 的代码都在同一个串行执行流上
- 可以用 `MainActor.shared` 直接拿到（但很少这么写）

理解这个差别后，你可以记一句口诀：

- 普通 actor 是"一种隔离的形状"
- `MainActor` 是"那一个特殊的、和 UI 绑定的全局 actor"

### 模块 7：`@MainActor` 的默认约定

把 `@MainActor` 标在类型上时，有两条默认约定值得记牢，因为它们决定了你需不需要手动切线程。

**约定一：标在类型上 → 所有成员默认被隔离到 MainActor。**

```swift
@MainActor
final class ListVM {
    var items: [String] = []          // 受 MainActor 隔离
    func append(_ s: String) {        // 默认在 MainActor 上跑
        items.append(s)
    }
}
```

`ListVM` 的每个属性、每个方法默认都"住在" MainActor 上。从别的 actor 访问它们就必须 `await`，编译器会逼你显式跨越隔离边界——这正是它防止数据竞争的方式。

**约定二：在 `@MainActor` 方法里 `await` 之后，控制权会自动跳回 MainActor。**

```swift
@MainActor
final class ListVM {
    var items: [String] = []

    func reload() async {
        let fetched = await fetchData()   // await 期间可能切到别的执行器
        items = fetched                   // 回到这一行时，已经被切回 MainActor
    }
}

func fetchData() async -> [String] { /* ... */ [] }
```

逐句看：

- `reload()` 因为类标了 `@MainActor`，所以它从一开始就在 MainActor 上执行
- `await fetchData()` 这一步，控制权可能被让出、跳到别的执行器去等结果
- 但 `await` 返回后，编译器保证把控制权**切回 MainActor**
- 因此 `items = fetched` 这一句安全地写回了受隔离的状态，你**不需要手动 `DispatchQueue.main.async`**

这条机制让"先异步取数据、再回主线程更新状态"的代码写起来非常顺：跨线程的切换由编译器和运行时替你完成，你只管按顺序写逻辑。本章后面的 `TaskListVM`（标了 `@MainActor`）就是这个约定的完整示范。

#### `@MainActor` 的三种标准写法

模块 6 已经讲过三种标注位置的效果，这里把它们收成一张速查骨架——同一个 `@MainActor`，标在哪里，就把"必须在主线程访问"的边界画在哪里：

```swift
/// 标在类型上：作用域最大。所有存储属性、所有方法默认都被隔离到 MainActor。
/// 跨 actor 访问其任何成员都要 `await`。最常用，适合整块都是 UI/主线程状态的 ViewModel。
@MainActor
final class ListVM { /* 每个成员默认在主线程 */ }

/// 标在单个方法上：只有这一个方法被隔离到 MainActor，所在类型的其余成员不受影响。
/// 适合"绝大多数逻辑不限线程，只有这一处必须回主线程"的类型。
@MainActor func reload() async { /* 只有这里被隔离 */ }

/// 标在单个属性上：只有这一个属性的读写被隔离到 MainActor，同类型的其它成员不受影响。
/// 适合"只有这一份状态要主线程保护，其余计算可以在任意线程"的类型。
@MainActor var items: [Item] = []
```

对照本章已实现的例子：模块 10 的 `TaskListVM` 用的是**标在类型上**这种写法（`@MainActor final class`），所以 `tasks`、`add`、`sort`、`toggle` 默认全在主线程；而它的 `format(_:)` 用 `nonisolated` 单独从这层隔离里"逃"了出来（见模块 9）——一个标在类型上、再用 `nonisolated` 开个口子的典型组合。

### 模块 8：什么时候应该刻意离开 MainActor

虽然 MainActor 默认很方便，但有些事**绝对不能在主线程做**：

- 大量计算（CPU 密集型）
- 阻塞 I/O
- 大文件读写
- 解析超大 JSON

这些操作如果在 MainActor 上跑，会冻结 UI，掉帧、卡顿。

工程上常用的两个模式：

#### 模式 1：把重活交给一个非 main actor

```swift
actor Parser {
    func parse(_ data: Data) -> [Item] { /* CPU 重活 */ }
}

@MainActor
class ListVM {
    let parser = Parser()
    var items: [Item] = []

    func load() async {
        let data = try! await fetchRawData()
        let parsed = await parser.parse(data)   // 重活在 Parser actor 上跑
        items = parsed                           // 回到 MainActor
    }
}
```

#### 模式 2：用 `Task.detached`

```swift
@MainActor
func load() async {
    let parsed = await Task.detached(priority: .userInitiated) {
        heavyParse()
    }.value
    items = parsed
}
```

`Task.detached` 启动的任务**不继承当前 actor**，所以默认不在 MainActor 上跑。重活做完后，`await` 让我们回到 MainActor。

### 模块 9：`nonisolated` —— 让某个成员"逃出 MainActor"

有时候你的类整体标了 `@MainActor`，但某个方法不依赖任何主线程状态，希望任何线程都能调用：

```swift
@MainActor
class ListVM {
    var items: [Item] = []

    nonisolated func formatTimestamp(_ d: Date) -> String {
        let f = DateFormatter()
        f.dateStyle = .short
        return f.string(from: d)
    }
}
```

`nonisolated` 让 `formatTimestamp` 不再受 MainActor 隔离。它的代价是：**这个方法不能访问任何受隔离的属性**，否则编译错。这正是 Swift 并发安全机制在保护你。

### 模块 10：把三者串起来 —— 一个完整的小例子

下面是 demo 里会出现的一段代码（仅用控制台输出），它把 KeyPath、`Identifiable`、`@MainActor` 三件事串在了一起：

```swift
struct TodoTask: Identifiable, Sendable {
    let id: UUID
    var title: String
    var priority: Int
    var isDone: Bool
}

@MainActor
final class TaskListVM {
    private(set) var tasks: [TodoTask] = []

    func add(_ t: TodoTask) { tasks.append(t) }

    func sort(using comparator: KeyPathComparator<TodoTask>) {
        tasks.sort(using: comparator)
    }

    func toggle(id: UUID) {
        guard let i = tasks.firstIndex(where: { $0.id == id }) else { return }
        tasks[i].isDone.toggle()
    }

    nonisolated func format(_ task: TodoTask) -> String {
        "\(task.isDone ? "[x]" : "[ ]") \(task.title) (P\(task.priority))"
    }
}
```

读这一段时关注：

- `TodoTask: Identifiable` —— 用 `id` 在列表里稳定追踪（之所以叫 `TodoTask` 而不是 `Task`，是为了避开标准库并发里的 `Task` 同名类型）
- `KeyPathComparator<TodoTask>` —— 用 KeyPath 描述排序方式
- `@MainActor` —— 整个 VM 默认在主线程
- `nonisolated func format(...)` —— 纯函数式辅助方法逃出 MainActor

这就是一个把"有身份的数据 + KeyPath 排序 + 主线程隔离的状态管理"凑齐的最小骨架。任何需要统一管理一组数据、又要保证状态访问安全的场景，都能从这个形态出发往外扩。

## 本章对应 demo

demo 在 `demos/projects/57-keypath-identifiable-and-mainactor`。它是一个 Swift Package，包含一个命令行 Demo + 一组测试。

```text
57-keypath-identifiable-and-mainactor/
├─ Package.swift
├─ Sources/
│  ├─ TaskKit/
│  │  ├─ Task.swift
│  │  ├─ Patch.swift
│  │  └─ TaskListVM.swift
│  └─ TaskDemo/
│     └─ main.swift
└─ Tests/
   └─ TaskKitTests/
      └─ TaskKitTests.swift
```

### `Task.swift`

```swift
import Foundation

public struct TodoTask: Identifiable, Sendable, Equatable {
    public let id: UUID
    public var title: String
    public var priority: Int
    public var isDone: Bool

    public init(id: UUID = UUID(), title: String, priority: Int, isDone: Bool = false) {
        self.id = id
        self.title = title
        self.priority = priority
        self.isDone = isDone
    }
}
```

### `Patch.swift`

`Patch<Root>` 把 KeyPath 包装成可组合的"对象修改器"。

### `TaskListVM.swift`

`@MainActor` 修饰的视图模型，演示三件事的合作。

### `main.swift`

完整跑一遍：

```bash
cd demos/projects/57-keypath-identifiable-and-mainactor
swift run TaskDemo
```

### `TaskKitTests.swift`

测试覆盖：

- `Identifiable` 用 `id` 区分两条 task
- `KeyPathComparator` 排序生效
- `Patch` 通过 KeyPath 修改字段
- `TaskListVM.toggle(id:)` 修改正确的元素

完整代码见 demo 目录。

## 小结

这一章我们补齐了写任何有数据模型、有并发的 Swift 程序都会高频用到的三块基础：

- **KeyPath** —— 结构化的"属性路径"，是排序、分组、筛选和各种通用工具的语言
- **Identifiable** —— 集合元素的稳定身份证，让差量更新、缓存比对成为可能
- **`@MainActor`** —— "必须在主线程跑"的隔离域，理解它就能解释"为什么 `await` 之后不需要手动切回主线程"

判断口诀：

- 看到 `\Type.field` —— 想"这是一个 KeyPath，不是值，不是闭包"
- 看到要按身份比对一批数据 —— 想"我的元素 `Identifiable` 了吗？`id` 稳定吗？"
- 看到 `@MainActor` —— 想"这段代码默认在主线程；重活要不要 detach？"

下一章我们补最后一块拼图：Swift 宏。很多 `@` 和 `#` 开头的标记背后，都是宏在编译期帮你生成代码。

## 练习

动手写代码的 starter 工程在 `exercises/zh-CN/projects/57-keypath-identifiable-and-mainactor-starter`；写完想对答案，参考实现与逐题讲解在 `exercises/zh-CN/answers/57-keypath-identifiable-and-mainactor.md`。

### 任务 1：用 KeyPath 实现通用 `groupBy`

写一个泛型函数 `groupBy`，把一组元素按"某个属性"分组成字典。它的签名要长这样：

```swift
func groupBy<Element, Key: Hashable>(
    _ items: [Element],
    by keyPath: KeyPath<Element, Key>
) -> [Key: [Element]]
```

调用方传入一个 KeyPath 来指定按哪个字段分组，例如：

```swift
let g = groupBy(users, by: \.country)
g["CN"]   // 所有 country == "CN" 的 user
```

交付物就是这个 `groupBy` 函数。关键是想清楚两个泛型参数各自的约束：哪个需要 `Hashable`、哪个不需要。

提示：标准库里已经有按闭包分组成字典的现成工具，你只需要把"分组依据"从闭包换成"用 KeyPath 取值"。难点不在分组本身，而在想清楚两个泛型参数里哪个必须 `Hashable`、哪个不必。

### 任务 2：为会重复的数据设计稳定 `id`

有一批消息，内容可能重复（比如两条都是 `"hello"`）。如果拿"内容本身"当身份，这两条会被当成同一个，做差量比对、缓存或列表渲染时就会出错。

请设计一个 `Message` 类型，让它遵守 `Identifiable`，用一个**稳定且独立**的 `id`（而不是内容本身）作为身份，使内容相同的两条消息也能被区分开。

交付物是这个 `Message` 类型，外加在答案里用一两句话说清：为什么不能拿"内容本身"当身份。构造时最好让 `id` 有默认值（平时不用手动传），但单元测试里又能显式指定两个不同的 `id`。

提示：用 `UUID` 当独立 `id` 是最省事的稳定身份。想想 `init` 怎么设计——给 `id` 一个默认值，就能同时满足"平时构造不用手动传 id"和"测试时显式指定两个不同 id"两种需求。

### 任务 3：给 `@MainActor` 类加 `nonisolated` 方法

starter 里的 `Counter` 已经标了 `@MainActor`。请给它补一个 `nonisolated` 的方法 `formatTimestamp(_:)`：

- 接受一个 `Date`
- 返回一段简短的字符串
- 不依赖 `Counter` 的任何受隔离状态（不能读写 `value`）

然后写一个**不在 MainActor 上**的测试函数来调用它，验证 `nonisolated` 方法确实能从非 MainActor 的上下文里直接调用。

交付物是这个 `nonisolated` 方法 + 对应的测试。注意：因为 `Counter` 整体被隔离，从非 MainActor 的测试里构造它需要 `await`。

提示：把 `formatTimestamp` 标成 `nonisolated` 后，试着在里面加一句 `_ = self.value`，看看编译器报什么错——这正是 `nonisolated` 在替你把关。

### 任务 4（思考题）：`Task.detached` vs 独立 actor

在答案文档里用文字回答下面三问，不必写可运行代码：

- 什么时候应该用 `Task.detached` 把重活扔出去？
- 什么时候应该让某个独立的 actor 来跑这些重活？
- 这两者对内存、对并发安全模型的影响有什么区别？

提示：从"一次性计算 vs 长期持有的共享状态"这条线去想，再各自推它们对生命周期和数据竞争的影响。
