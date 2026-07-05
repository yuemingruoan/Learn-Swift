# 54. 关联类型与不透明返回类型 练习答案

对应章节：

- [54. 关联类型与不透明返回类型：`associatedtype` 与 `some`](../../../docs/zh-CN/chapters/54-associated-types-and-opaque-return-types.md)

如果你想一边看答案一边运行 starter project，可以打开：

- `exercises/zh-CN/projects/54-associated-types-and-opaque-return-types-starter`

如果你想直接运行本章练习的参考工程，也可以打开：

- `exercises/zh-CN/answers/54-associated-types-and-opaque-return-types`

说明：

- 每道题的**完整描述**在教程正文的「练习」一节：[54. 关联类型与不透明返回类型](../../../docs/zh-CN/chapters/54-associated-types-and-opaque-return-types.md#练习)。这里只放参考实现与逐题讲解。
- 本章练习围绕一个 `ReadOnlyStorage` 协议展开，让你亲手区分"调用方填空"和"实现方填空"
- 然后让你把一个 `any Sequence<Int>` 的 API 改造成 `some Sequence<Int>`，体会两种返回类型的差别
- 最后用本章的 `makeUserSource` / `PaginatedSource` 做一道思考题

## 任务 1：让两个具体类型遵守 `ReadOnlyStorage` 并加上 `contains`

> 让 `InMemoryNumberStorage`（`Element` 为 `Int`）、`InMemoryNameStorage`（`Element` 为 `String`）遵守 `ReadOnlyStorage`，再用 `where Element: Equatable` 的扩展实现 `contains(_:)`。（完整描述见正文）

### 参考实现

```swift
public extension ReadOnlyStorage where Element: Equatable {
    func contains(_ value: Element) -> Bool {
        for i in 0..<count where element(at: i) == value {
            return true
        }
        return false
    }
}

public struct InMemoryNumberStorage: ReadOnlyStorage {
    public let items: [Int]
    public init(items: [Int]) { self.items = items }
    public var count: Int { items.count }
    public func element(at index: Int) -> Int { items[index] }
}

public struct InMemoryNameStorage: ReadOnlyStorage {
    public let items: [String]
    public init(items: [String]) { self.items = items }
    public var count: Int { items.count }
    public func element(at index: Int) -> String { items[index] }
}
```

### 解题点评

- `InMemoryNumberStorage` 和 `InMemoryNameStorage` 都没有写 `typealias Element = ...`，是因为编译器从 `element(at:) -> Int` 这个签名就推出来了
- `contains(_:)` 没必要重复写两遍，借助"`where Element: Equatable`"的协议扩展直接挂上去
- 这正是 `Sequence`、`Collection` 标准库的设计套路：协议留洞，实现方填洞，扩展按"洞被填成什么"再分别给默认实现

## 任务 2：把 `any Sequence<Int>` 改造为 `some Sequence<Int>`

> 把 `evenNumbers(upTo:)` 的返回类型从 `any Sequence<Int>` 改成 `some Sequence<Int>`，并说明哪些调用方代码受影响。（完整描述见正文）

### 参考实现

```swift
public func evenNumbers(upTo n: Int) -> some Sequence<Int> {
    (0..<n).lazy.filter { $0 % 2 == 0 }
}
```

注意我们顺便把 `filter` 换成了 `lazy.filter`。这是因为：

- `(0..<n).filter` 直接返回 `[Int]`，这是个具体类型
- `(0..<n).lazy.filter { ... }` 返回 `LazyFilterSequence<Range<Int>>`，调用方完全不需要知道这个类型

两种写法都能让 `some Sequence<Int>` 编译通过。`lazy` 版本演示了"工程上 some 最值钱的场景"——藏起复杂的具体类型。

### 调用方会受什么影响

把 `any` 改成 `some` 后：

- 同一个变量不能再装异构序列，比如下面这种写法不再合法：

  ```swift
  var seq = evenNumbers(upTo: 10)
  seq = oddNumbers(upTo: 10)   // ❌ 两边的具体类型不同
  ```

- 把多个 `evenNumbers(upTo:)` 的返回值放进数组也不行：

  ```swift
  let arr = [evenNumbers(upTo: 1), evenNumbers(upTo: 2)]
  // 看上去像 [some Sequence<Int>]，但 some 不能这么用
  ```

  这种场景必须显式声明为 `[any Sequence<Int>]`。

- 但所有"只是迭代它一次"的代码不受影响：

  ```swift
  for n in evenNumbers(upTo: 10) {
      print(n)
  }
  ```

工程经验：

- 单一返回、调用方"只迭代不复用类型"，几乎总是 `some` 更划算
- 真的要把多个不同实现塞进一个集合，才用 `any`

## 任务 3（思考题）：分析 `makeUserSource` 与 `PaginatedSource`

> 回答：`makeUserSource()` 为什么返回 `some` 而非 `any`、哪一行依赖 `associatedtype` 哪一行依赖 `some`、改成 `any` 会失去什么。（完整描述见正文）

回到本章正文里这段代码：

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

### 问 1：`makeUserSource()` 为什么返回 `some` 而不是 `any`？

参考回答：

- 这个函数体里只会返回一种具体类型（`UserRemoteSource`），完全符合 `some` 的要求："所有返回路径都是同一个具体类型"
- 用 `some` 时编译器知道背后是谁，调用方拿到的值没有装箱开销、方法调用是直接调用
- 用 `any PaginatedSource<User>` 会引入装箱和运行时分派，平白多一层间接；而这里根本不需要"运行期才决定是哪种实现"的能力
- 工程意图也很清楚：对外只想暴露"这是某个能分页拉 `User` 的源"，不想把 `UserRemoteSource` 这个具体类型写进 API。`some` 恰好做到"隐藏实现 + 零开销"两件事

### 问 2：`PaginatedSource` 里哪一个声明用到了 `associatedtype`？

参考回答：

- `associatedtype Element` 就是那个洞，由实现方填上
- `UserRemoteSource` 通过 `fetch(page:) -> [User]` 这个签名，把 `Element` 隐式填成 `User`（不用写 `typealias Element = User`，编译器能推出来）
- 协议头上的 `PaginatedSource<Element>` 是把 `Element` 声明为**主关联类型**，这样外面才能写 `some PaginatedSource<User>` 这种带约束的写法
- 一句话：`fetch` 的返回值类型 `[Element]` 依赖 `associatedtype`，`makeUserSource()` 的返回类型 `some PaginatedSource<User>` 依赖 `some`

### 问 3：把返回类型从 `some` 改成 `any` 会失去什么？

参考回答：

- 失去"编译期固定的具体类型"：`any PaginatedSource<User>` 把实现类型擦除成一个运行时盒子
- 失去零开销：每次调用 `fetch` 都要走运行时分派，还有装箱成本
- 关联类型的可用性受限：通过 `some` 拿到的值，编译器把 `Element` 当成"未知但确定"的具体类型，类型推断更顺；`any` 下关联类型被擦除，很多需要精确类型的上下文会更难写
- 唯一适合改成 `any` 的场景是：你确实要把"不同实现"装进同一个变量或数组里（比如 `[any PaginatedSource<User>]`，同时放远程源和本地源）。本例没有这个需求，所以 `some` 更划算

## 自检清单

完成本章练习后，请确认你能脱口回答以下问题：

- 泛型参数和关联类型，谁是"调用方决定"，谁是"实现方决定"？
- `some Sequence<Int>` 与 `any Sequence<Int>` 的根本区别是什么？
- 主关联类型 `Container<Item>` 是用来做什么的？
- 为什么工厂方法 `makeUserSource()` 适合返回 `some` 而不是 `any`？

如果其中任意一条不能立刻回答出来，建议回到正文相应模块再读一遍。
