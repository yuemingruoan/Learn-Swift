# 51. Swift Testing 组织与复用：Suite、参数化测试、Tag 与 Trait

## 阅读导航

- 前置章节：[50. Swift Testing 入门：从 XCTest 到 @Test、#expect 与第一批单元测试](./50-swift-testing-basics-from-xctest-to-test-expect-and-require.md)
- 上一章：[50. Swift Testing 入门：从 XCTest 到 @Test、#expect 与第一批单元测试](./50-swift-testing-basics-from-xctest-to-test-expect-and-require.md)
- 下一章：[52. Swift Testing 工程实践：异步测试、依赖替身与从 XCTest 渐进迁移](./52-swift-testing-async-doubles-and-gradual-migration.md)
- 适合谁读：已经完整读过上一章，至少知道“单元测试是什么”“断言是什么”“`@Test`、`#expect`、`#require` 各自负责什么”的读者

## 本章目标

学完这一章后，你应该能够：

- 用 `@Suite` 或测试类型把相关测试组织起来
- 用参数化测试覆盖同一条规则的多组输入
- 区分单参数参数化和多参数参数化
- 看懂参数化测试里 `@Test` 的基本语法与参数传递方式
- 用 `Tag` 给测试打上可筛选的语义标签
- 理解常见 trait 的使用场景：
  - 条件启用 / 禁用
  - `timeLimit`
  - `serialized`

## 本章对应资源

- 文稿：`docs/zh-CN/chapters/51-swift-testing-organization-parameterized-tags-and-traits.md`
- 示例项目：`demos/projects/51-swift-testing-organization-parameterized-tags-and-traits`

## 本章怎么读

第 50 章解决的是：

- “一条测试最小怎么写”

第 51 章解决的是：

- “当测试开始变多时，如何让它们仍然清楚、可维护、少重复”

## 正文主体

### 模块 0：为什么本章要从“组织”开始

很多人第一次写单元测试时，都会有一个阶段：

- 前几条测试写得很顺
- 第十条开始还能忍
- 到第二十条时，开始觉得文件越来越乱
- 到第三十条时，重复代码越来越多

这时问题通常不是：

- 断言不会写

而是：

- 组织方式开始失控

这种失控通常有几种表现：

#### 表现 1：同一条规则被复制成很多个测试函数

例如你想验证不同输入映射到不同输出，结果写成：

```swift
@Test func bucketForMinusOne() { ... }
@Test func bucketForZero() { ... }
@Test func bucketForThree() { ... }
@Test func bucketForEight() { ... }
```

显然这段代码可以运行~~(毕竟编译器才不会管你的代码是不是屎山)~~，但是：

- 重复太多
- 维护成本高

#### 表现 2：所有测试都堆在一个文件里

一开始你觉得：

- 反正都在测同一个模块，堆一起也没关系

但很快你会发现：

- 过滤规则
- 排序规则
- 状态映射
- trait 示例

它们的关注点并不相同。

#### 表现 3：测试报告里找不到语义分组

如果你后面只看到一长串测试名，而没有分组、标签、case 结构，你会越来越难快速定位：

- 哪些是过滤逻辑
- 哪些是排序逻辑
- 哪些是特定环境才运行的测试

这就是这一章要解决的问题：

- **把测试从“能跑”推进到“能组织、能复用、能筛选”。**

### 模块 1：本章 demo 解决的业务问题

这一章仍旧先不涉及异步，而是继续使用纯逻辑领域对象。

原因是：

- 当前想学的是“测试组织能力”
- 不是“副作用替身”

本章 demo 的业务对象如下：

```swift
import Foundation

struct StudyTask: Equatable, Sendable {
    let title: String
    let chapter: Int
    let estimatedMinutes: Int
    let isCompleted: Bool
    let isBookmarked: Bool
}

enum SortStrategy: String, CaseIterable, Sendable {
    case recommended
    case shortestFirst
    case chapterOrder
}

enum ReviewBucket: String, Equatable, Sendable {
    case today = "today"
    case thisWeek = "thisWeek"
    case later = "later"
}
```

再往下是核心规则：

```swift
enum StudyPlanOrganizer {
    static func filter(_ tasks: [StudyTask], searchText: String, onlyIncomplete: Bool) -> [StudyTask] {
        let normalizedSearchText = searchText
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()

        return tasks.filter { task in
            let matchesCompletion = !onlyIncomplete || !task.isCompleted

            guard !normalizedSearchText.isEmpty else {
                return matchesCompletion
            }

            let matchesQuery = task.title.lowercased().contains(normalizedSearchText)
                || String(task.chapter).contains(normalizedSearchText)

            return matchesCompletion && matchesQuery
        }
    }

    static func sorted(_ tasks: [StudyTask], strategy: SortStrategy) -> [StudyTask] {
        switch strategy {
        case .recommended:
            return tasks.sorted { lhs, rhs in
                if lhs.isCompleted != rhs.isCompleted {
                    return !lhs.isCompleted && rhs.isCompleted
                }

                if lhs.isBookmarked != rhs.isBookmarked {
                    return lhs.isBookmarked && !rhs.isBookmarked
                }

                if lhs.chapter != rhs.chapter {
                    return lhs.chapter < rhs.chapter
                }

                return lhs.title < rhs.title
            }

        case .shortestFirst:
            return tasks.sorted { lhs, rhs in
                if lhs.estimatedMinutes != rhs.estimatedMinutes {
                    return lhs.estimatedMinutes < rhs.estimatedMinutes
                }

                return lhs.title < rhs.title
            }

        case .chapterOrder:
            return tasks.sorted { lhs, rhs in
                if lhs.chapter != rhs.chapter {
                    return lhs.chapter < rhs.chapter
                }

                return lhs.title < rhs.title
            }
        }
    }

    static func reviewBucket(for daysUntilReview: Int) -> ReviewBucket {
        if daysUntilReview <= 0 {
            return .today
        }

        if daysUntilReview <= 7 {
            return .thisWeek
        }

        return .later
    }
}
```

你应该能感觉到，这套业务代码和第 50 章最大的不同不仅是复杂度暴涨，还有：

- **它天然适合“一条规则，多组输入”**

例如：

- `reviewBucket(for:)` 就是典型映射规则
- `sorted(_:strategy:)` 就是同一输入、不同策略
- `filter(_:searchText:onlyIncomplete:)` 就是同一函数、多组搜索场景

### 模块 2：`@Suite` 解决什么问题

先看本章测试文件开头：

```swift
@Suite("Filtering and sorting", .tags(.organization))
struct StudyPlanOrganizerTests {
    private let tasks = DemoFixtures.tasks
    ...
}
```

第 50 章你已经见过：

- 不一定非要写 `@Suite`
- 一个测试类型里直接放 `@Test` 也可以

那为什么第 51 章开始要显式写 `@Suite`？

因为本章关注点已经从：

- “能不能写出测试”

升级成：

- “这些测试怎么形成一个有边界的组”

#### 先记一句话

- `@Suite` 不是为了让测试“更高级”
- 而是为了对测试**进行分组**

#### 用它来表达“这组测试都在测什么”

例如：

```swift
@Suite("Filtering and sorting", .tags(.organization))
struct StudyPlanOrganizerTests { ... }
```

这表示这组测试都在处理：

- 过滤
- 排序
- 学习计划组织逻辑

而不是：

- trait 运行约束
- 异步副作用
- 外部依赖替身

等等等等

#### `@Suite` 是可选的，但“分组意识”是必须的

这一点很重要。

哪怕你不写 `@Suite`，你也迟早会面对这些问题：

- 哪些测试是一组
- 哪些测试共享同一份 fixture
- 哪些测试应该在测试报告里一起出现

所以不要把 `@Suite` 理解成“只是语法装饰”。

它表达的是：

- 这组测试在语义上属于同一个块

### 模块 3：参数化测试，为什么它比复制测试函数更好

这一章最关键的能力是：

- 参数化测试

它解决的是一个非常高频的重复问题：

- 同一条规则，需要验证很多组输入

#### 先看最容易写出来但最容易变乱的版本

假设你要测 `reviewBucket(for:)`。

如果不用参数化，很容易写成：

```swift
@Test func minusOneMapsToToday() {
    #expect(StudyPlanOrganizer.reviewBucket(for: -1) == .today)
}

@Test func zeroMapsToToday() {
    #expect(StudyPlanOrganizer.reviewBucket(for: 0) == .today)
}

@Test func threeMapsToThisWeek() {
    #expect(StudyPlanOrganizer.reviewBucket(for: 3) == .thisWeek)
}

@Test func eightMapsToLater() {
    #expect(StudyPlanOrganizer.reviewBucket(for: 8) == .later)
}
```

这些测试并不“错”，但它们有一个明显问题：

- 它们本质上都在测同一张映射表

参数化测试更适合这种场景。

### 模块 3A：先把参数化测试里的 `@Test` 语法读清楚

很多读者第一次看到参数化测试时，最容易卡住的不是测试思路，而是这句：

```swift
@Test("...", .tags(.filtering), arguments: ...)
```

所以在看具体例子前，先把这个外壳拆开。

#### 先记住最常见的三种写法

单参数参数化：

```swift
@Test("显示名", .tags(.filtering), arguments: someCollection)
func example(value: Value) {
    ...
}
```

两个参数，覆盖两组输入的所有组合：

```swift
@Test("显示名", .tags(.filtering), arguments: firstCollection, secondCollection)
func example(first: First, second: Second) {
    ...
}
```

两个参数，按顺序一一配对：

```swift
@Test("显示名", .tags(.filtering), arguments: zip(firstCollection, secondCollection))
func example(first: First, second: Second) {
    ...
}
```

按照 Apple 文档，参数化测试的 `@Test` 常见重载就是这三类：

- 一个集合
- 两个集合
- 一个 `zip(...)` 后的配对序列

你现在不用把“重载”这个词想得太复杂，先把它理解成：

- `@Test` 会根据你提供的 `arguments:` 形状，决定这条测试怎样生成多个 case

#### `@Test` 里你最需要关心的几个位置

对教学和日常工程来说，参数化测试里的 `@Test` 最常写成：

```swift
@Test("显示名", trait1, trait2, arguments: someArguments)
```

这里可以先把它拆成三部分：

##### 第 1 部分：显示名

例如：

```swift
"reviewBucket 把不同的天数映射到固定分桶"
```

它的作用是：

- 给 Xcode 测试列表和测试报告看
- 让人一眼知道这条测试在验证什么

这部分通常是可选的，但在教学文稿和业务项目里，通常值得保留。

##### 第 2 部分：trait

例如：

```swift
.tags(.filtering)
.timeLimit(.minutes(1))
```

它们的作用是：

- 给测试附加标签
- 增加运行约束或行为说明

这部分也是可选的，而且可以写 0 个、1 个或多个。

你可以先把它理解成：

- “这条测试除了本身逻辑之外，还有哪些附加说明”

##### 第 3 部分：`arguments:`

这是参数化测试最关键的部分。

例如：

```swift
arguments: SortStrategy.allCases
```

或者：

```swift
arguments: zip(reviewDays, reviewBuckets)
```

它的作用是：

- 提供这条测试要重复运行的输入数据
- 让测试框架自动把一条测试拆成多个 case

也就是说，参数化测试和普通测试最本质的区别就在这里：

- 普通测试只有一组输入
- 参数化测试由 `arguments:` 提供很多组输入

#### 写完 `arguments:` 之后，函数签名要怎么接

最实用的规则只有一条：

- `arguments:` 提供几份位置参数，测试函数就接几份位置参数

例如单参数时：

```swift
@Test(arguments: SortStrategy.allCases)
func sortStrategies(strategy: SortStrategy) {
    ...
}
```

这里 `SortStrategy.allCases` 的每个元素，都会在某一次运行里传进：

- `strategy`

再看“一个场景对象”的写法：

```swift
@Test(arguments: [FilterScenario(...)])
func filterScenarios(scenario: FilterScenario) {
    ...
}
```

这里每个 `FilterScenario`，都会在某一次运行里传进：

- `scenario`

如果是两个参数：

```swift
@Test(arguments: zip(reviewDays, reviewBuckets))
func reviewBucketMapping(daysUntilReview: Int, expectedBucket: ReviewBucket) {
    ...
}
```

这里当前 case 的两个值，会分别传进：

- `daysUntilReview`
- `expectedBucket`

顺序必须和 `arguments:` 产生值的顺序一致。

#### 进入函数体以后，这些参数怎么用

进入测试函数体后，这些参数就只是普通函数参数。

你不需要再去做这些事：

- 手动写 `for` 循环
- 自己从数组里按下标取值
- 再从 `arguments:` 里二次解析

你只需要像使用普通局部值一样使用它们：

- 单参数对象场景下，用 `scenario.query`、`scenario.expectedTitles`
- 多参数场景下，直接用 `daysUntilReview`、`expectedBucket`
- 然后把它们传给被测函数，或者拿来写 `#expect`

例如：

```swift
let result = StudyPlanOrganizer.filter(
    tasks,
    searchText: scenario.query,
    onlyIncomplete: scenario.onlyIncomplete
)

#expect(result.map(\.title) == scenario.expectedTitles)
```

或者：

```swift
#expect(StudyPlanOrganizer.reviewBucket(for: daysUntilReview) == expectedBucket)
```

你可以把整件事概括成一句话：

- `arguments:` 负责“把 case 数据送进来”
- 测试函数参数负责“把当前 case 接住”
- 函数体负责“使用当前 case 做断言”

### 模块 4：单参数参数化测试，先看一组最小真实场景

本章 `filterScenarios` 就是单参数参数化测试：

```swift
struct FilterScenario: Sendable {
    let query: String
    let onlyIncomplete: Bool
    let expectedTitles: [String]
}

@Test("filter 可以复用同一套断言覆盖多组输入", .tags(.filtering), arguments: [
    FilterScenario(query: "Swift", onlyIncomplete: false, expectedTitles: ["Swift Testing 基础"]),
    FilterScenario(query: "52", onlyIncomplete: false, expectedTitles: ["XCTest 迁移清单", "整理异步测试笔记"]),
    FilterScenario(query: "", onlyIncomplete: true, expectedTitles: ["Swift Testing 基础", "参数化测试设计", "整理异步测试笔记"]),
])
func filterScenarios(scenario: FilterScenario) {
    let result = StudyPlanOrganizer.filter(
        tasks,
        searchText: scenario.query,
        onlyIncomplete: scenario.onlyIncomplete
    )

    #expect(result.map(\.title) == scenario.expectedTitles)
}
```

这里的结构非常值得你模仿。

#### 为什么先定义 `FilterScenario`

因为当一组输入本身就代表一个“场景”时，用独立类型会比散落的元组更清楚。

这个类型本质上在说：

- 一个过滤场景 = 查询词 + 是否只看未完成 + 期望结果

这比直接写很多组匿名元组更容易读，也更容易继续扩展。

#### 什么叫“单参数参数化”

不是说你场景里只能有一个字段。

而是说：

- 测试函数只接收一个参数对象

例如这里：

```swift
func filterScenarios(scenario: FilterScenario)
```

这个参数对象内部当然可以带多个字段。

#### 什么时候更适合这种写法

当以下情况成立时，优先考虑“单参数 + 场景类型”：

- 一组输入本来就组成一个完整场景
- 你希望场景语义比较强
- 后续可能继续给这个场景加字段

### 模块 5：多参数参数化测试，重点不是“会写”，而是知道它为什么更自然

除了把一组输入封成一个对象，你也会遇到另外一种情况：

- 两列数据天然是一一对应的

例如：

- `daysUntilReview`
- `expectedBucket`

这时本章用的是：

```swift
private let reviewDays = [-2, 0, 3, 8]
private let reviewBuckets: [ReviewBucket] = [.today, .today, .thisWeek, .later]

@Test("reviewBucket 把不同的天数映射到固定分桶", .tags(.filtering), arguments: zip(reviewDays, reviewBuckets))
func reviewBucketMapping(daysUntilReview: Int, expectedBucket: ReviewBucket) {
    #expect(StudyPlanOrganizer.reviewBucket(for: daysUntilReview) == expectedBucket)
}
```

这就是本章的“多参数参数化”例子。

#### 为什么这里用 `zip(...)`

因为这里的关系不是：

- 每个天数都要和所有 bucket 任意组合

而是：

- 第 1 个天数对应第 1 个 bucket
- 第 2 个天数对应第 2 个 bucket

如果你没有先把这个数据关系想清楚，就很容易把参数化测试写成错误的组合方式。

所以你应该先问自己：

- 我想要的是“逐项配对”
- 还是“所有组合”

这里答案显然是前者，所以用 `zip(...)`。

#### 这类写法适合什么场景

当你面对的是一张很明确的“输入 -> 输出”映射表时，这种写法非常自然：

- 状态映射
- 分桶映射
- 文案映射
- 错误码映射

### 模块 6：参数化测试不是为了炫技，而是为了减少错误重复

很多人知道参数化测试后，会把它理解成：

- 一种高级技巧

其实它更像一种“止损工具”。

它主要帮你避免三类问题：

#### 问题 1：复制粘贴之后只改了一半

如果你手写 8 个近似测试，很容易出现：

- 改了函数名
- 没改输入
- 或者改了输入但忘记改期望值

参数化测试把重复结构压回一份：

- 测试逻辑写一次
- 数据表写多行

这样更不容易出现半修改状态。

#### 问题 2：增加一个 case 的成本太高

如果每多一个 case 都要复制一个测试函数，你就会越来越懒得补测试。

而参数化测试通常只需要：

- 多追加一条场景数据

这会显著降低你补测试的心理成本。

~~骗你的，懒得写测试的该不写还是不写~~

#### 问题 3：测试列表不再表达“它们属于同一条规则”

如果你写很多重复测试函数，测试报告看起来会像一堆分散点。

而参数化测试会更明确地表达：

- 这些 case 属于同一个测试规则

### 模块 7：`Tag` 不是注释，而是“可筛选的语义”

本章测试文件一开始定义了：

```swift
extension Tag {
    @Tag static var organization: Self
    @Tag static var filtering: Self
    @Tag static var sorting: Self
    @Tag static var traits: Self
}
```

很多人第一次看到会想：

- 这不就是几个常量名字吗

但它的真正意义是：

- 这些名字不是普通注释，而是测试系统可识别的标签语义

#### 为什么不直接写普通字符串

因为 `Tag` 的意义不在“看起来像标签”，而在于：

- 它会进入测试元数据
- 可以参与测试筛选、组织和报告表达

#### 本章怎么用它

例如：

```swift
@Suite("Filtering and sorting", .tags(.organization))
struct StudyPlanOrganizerTests { ... }
```

以及：

```swift
@Test("不同排序策略产生不同顺序", .tags(.sorting), .timeLimit(.minutes(1)), arguments: SortStrategy.allCases)
```

这表示：

- 这一组测试属于 `organization`
- 这一条测试属于 `sorting`

这些标签不是给人肉阅读装饰，而是给测试组织增加另一条维度。

#### 为什么这很重要

因为文件夹结构和 suite 结构只能表达一部分关系。

例如：

- 一条测试既属于“排序”
- 也属于“trait 示例”

如果只有目录结构，你很难同时表达多维归类。

Tag 的意义就在这里：

- 它让测试拥有“横向标签”

### 模块 8：Trait 是“测试运行约束”，不是“断言语法”

这一章第一次系统讲 trait。

先把定义压成一句：

- trait 是附加在 test 或 suite 上的运行行为说明

它不是：

- 业务断言
- 结果判断

所以你不能把 trait 和 `#expect` 混成一类概念。

`#expect` 解决的是：

- 结果是否符合预期

trait 解决的是：

- 这条测试在什么条件下运行
- 运行时受什么约束
- 是否需要串行执行
- 是否有限时

### 模块 9：条件 trait，先学最常见的启用 / 禁用

本章的条件 trait 示例有两种：

#### 例子 1：`.enabled(if:)`

```swift
enum TraitExamples {
    static var sortingExamplesEnabled: Bool {
        ProcessInfo.processInfo.environment["DISABLE_SORTING_TRAIT_EXAMPLES"] == nil
    }
}

@Test("enabled trait 可以在需要时关闭整组示例", .tags(.traits), .enabled(if: TraitExamples.sortingExamplesEnabled))
func enabledTraitExample() {
    let bookmarkedIncomplete = StudyPlanOrganizer
        .sorted(tasks.filter { !$0.isCompleted && $0.isBookmarked }, strategy: .chapterOrder)
        .map(\.title)

    #expect(bookmarkedIncomplete == ["Swift Testing 基础", "整理异步测试笔记"])
}
```

这表示：

- 默认允许执行
- 如果环境变量让条件变成 `false`，那这条测试就不运行

#### 例子 2：`.disabled(if:)`

```swift
enum TraitExamples {
    static var optionalTraitExamplesEnabled: Bool {
        ProcessInfo.processInfo.environment["RUN_OPTIONAL_TRAIT_EXAMPLES"] == "1"
    }
}

@Test("disabled trait 适合默认跳过的演示", .tags(.traits), .disabled(if: !TraitExamples.optionalTraitExamplesEnabled, "默认关闭，仅在显式设置环境变量时启用"))
func disabledTraitExample() {
    let swiftOnly = StudyPlanOrganizer.filter(tasks, searchText: "Swift", onlyIncomplete: true)
    #expect(swiftOnly.map(\.title) == ["Swift Testing 基础"])
}
```

这里的含义是：

- 这条测试默认跳过
- 只有在显式打开环境变量时才执行

#### 什么时候该用条件 trait

你应该优先把它看成“运行环境边界”的表达，而不是随便加的开关。

例如：

- 某些测试只在特定平台跑
- 某些测试默认关闭，只有显式开启才跑
- 某些测试依赖可选资源

### 模块 10：`timeLimit`，它解决的不是“快慢”，而是“失控”

本章的 `timeLimit` 示例：

```swift
@Test("不同排序策略产生不同顺序", .tags(.sorting), .timeLimit(.minutes(1)), arguments: SortStrategy.allCases)
func sortStrategies(strategy: SortStrategy) {
    let result = StudyPlanOrganizer.sorted(tasks, strategy: strategy).map(\.title)
    ...
}
```

这里先说明一个现实问题：

- 本例本身不需要 1 分钟

那为什么还要写 `timeLimit(.minutes(1))`？

因为这一章在教学：

- `timeLimit` 是什么
- 它应该加在什么位置

#### `timeLimit` 真正解决的问题

不是：

- “这条测试快不快”

而是：

- “如果测试因为某种原因卡住，它有没有上限”

在真实工程里，时间限制更常用于：

- 依赖外部资源的测试
- 容易卡死的异步流程
- 有可能因为死循环或等待条件错误而长时间不结束的逻辑

这一章先只建立概念，不在本章故意制造慢测试。

### 模块 11：`.serialized`，禁止并行测试

本章还有一个 suite：

```swift
@Suite("Serialized suite demo", .serialized, .tags(.traits))
struct SerializedTraitExamples {
    @Test("serialized suite 里的测试仍然是普通测试函数")
    func serializedSuiteStillUsesOrdinaryAssertions() {
        let orderedChapters = StudyPlanOrganizer
            .sorted(DemoFixtures.tasks, strategy: .chapterOrder)
            .map(\.chapter)

        #expect(orderedChapters == [50, 51, 52, 52])
    }
}
```

这里要先讲清楚一件事：

- `serialized` 不是说“测试内容必须很特殊”

它表达的是：

- 这组测试不应该并行执行

#### 为什么会有这个需求

因为 Swift Testing 默认可以并行跑很多测试。

但真实项目中，总会遇到一些共享资源：

- 共享数据库文件
- 共享临时目录
- 共享端口
- 共享 singleton 状态

这时如果多个测试同时跑，很可能互相干扰。

`serialized` 的价值就在这里：

- 它给你一个明确的运行约束表达

#### 为什么本章没有用更复杂的共享资源 demo

因为本章的目标不是制造“并发测试事故”。

本章只需要你先明确知道：

- 有些测试组需要串行
- `serialized` 就是表达这件事的稳定入口

后面真正碰到异步副作用和共享依赖时，你会更容易理解它的工程价值。

### 模块 12：Xcode 里参数化测试显示出来会是什么样

这一节不展开 UI 操作细节，但你要知道一件很实用的事：

- 参数化测试不会只显示成一条笼统结果

而是会按 case 展开。

这对排查问题很重要。

因为如果某组参数失败，你真正想知道的是：

- 失败的是哪一组输入

而不是：

- 这整个测试“某处失败了”

这也正是参数化测试优于“手工 for 循环 + 一条测试”的关键之一。

如果你把多组场景塞进同一个测试函数里自己循环，那么一旦失败：

- 可读性通常会变差
- case 边界也不清楚

参数化测试把这种 case 边界交还给测试框架本身。

### 模块 13：什么时候该用 `@Suite`，什么时候只用普通测试类型就够

不要把这件事理解成“必须全都写 `@Suite`”。

更好的判断标准是：

- 这组测试是否已经形成稳定边界

例如本章里：

- `StudyPlanOrganizerTests` 负责主业务规则
- `SerializedTraitExamples` 负责 trait 示例

这种时候显式写 `@Suite` 很合理，因为分组边界很明确。

但如果你只是只有两三条非常简单的测试，还没有稳定分组需求，那么：

- 不一定非要为了“形式完整”加 `@Suite`

也就是说：

- `@Suite` 不是强制规定
- 它是一种组织意图表达

### 模块 14：什么时候该用 Tag，什么时候只靠文件结构就够

同样，Tag 也不是越多越好。

如果你给每条测试都打一堆标签，最后很可能产生反效果：

- 标签名太多
- 语义重叠
- 团队成员记不住

比较稳妥的原则是：

- 只给“后续真的可能拿来筛选或归类”的语义打标签

就像本章的这几个标签：

- `organization`
- `filtering`
- `sorting`
- `traits`

它们都不是一时兴起，而是很明确地对应：

- 测试主题
- 规则类别
- 运行机制示例

### 模块 15：再次细读参数化测试

第 51 章最容易被误学成“我会写一个 `arguments:` 语法了”，但这远远不够。

你真正要学会的是：

- 我到底在复用什么

先看单参数版本：

```swift
@Test(
    "reviewBucket 把不同的天数映射到固定分桶",
    .tags(.filtering),
    arguments: zip(reviewDays, reviewBuckets)
)
func reviewBucketMapping(daysUntilReview: Int, expectedBucket: ReviewBucket) {
    #expect(StudyPlanOrganizer.reviewBucket(for: daysUntilReview) == expectedBucket)
}
```

这里复用的不是“断言长得像”这么简单，而是：

- 同一条映射规则
- 在多组输入上重复验证

固定不变的部分是：

- 被测函数：`reviewBucket(for:)`
- 测试意图：输入天数后，应该落到固定桶

变化的部分才是：

- `daysUntilReview`
- `expectedBucket`

这就是参数化测试最标准的适用条件：

- 规则不变
- 输入集变化
- 断言骨架稳定

再看另一条测试：

```swift
@Test(
    "filter 可以复用同一套断言覆盖多组输入",
    .tags(.filtering),
    arguments: [
        FilterScenario(query: "Swift", onlyIncomplete: false, expectedTitles: ["Swift Testing 基础"]),
        FilterScenario(query: "52", onlyIncomplete: false, expectedTitles: ["XCTest 迁移清单", "整理异步测试笔记"]),
        FilterScenario(query: "", onlyIncomplete: true, expectedTitles: ["Swift Testing 基础", "参数化测试设计", "整理异步测试笔记"]),
    ]
)
func filterScenarios(scenario: FilterScenario) {
    let result = StudyPlanOrganizer.filter(
        tasks,
        searchText: scenario.query,
        onlyIncomplete: scenario.onlyIncomplete
    )

    #expect(result.map(\.title) == scenario.expectedTitles)
}
```

这里的复用单位已经不再是两个散参数，而是一整个场景对象：

- 查询词
- 是否只看未完成
- 预期标题列表

这说明参数化测试不是只有一种形状。

你完全可以按规则复杂度决定：

- 用单个参数
- 用多个位置参数
- 用一个场景结构体

关键不是“哪种更高级”，而是：

- 哪种最能让同一条规则保持可读

### 模块 16：什么时候该继续参数化，什么时候反而应该拆成独立测试

参数化测试很好用，但它不是越多越好。

如果下面三个条件同时成立，参数化通常值得优先考虑：

1. 被测规则是同一条
2. 测试步骤几乎完全一致
3. 差异主要集中在输入和期望结果

但如果你出现下面这些情况，就该考虑拆开：

#### 情况 1：不同 case 的准备步骤差很多

例如：

- A case 只需要一个数组
- B case 需要额外构造权限状态
- C case 还要模拟缓存命中

这时硬塞进一个参数化测试，会让测试体里充满分支。

测试体一旦写成：

```swift
if scenario.requiresCache { ... }
if scenario.requiresPermission { ... }
switch scenario.mode { ... }
```

通常就说明：

- 你复用过头了

#### 情况 2：失败时你需要非常具体的语义定位

参数化测试会把很多 case 放进同一测试骨架里，这通常很好。

但如果某条规则对每个 case 的失败解释都非常不同，那么拆成独立测试可能更清楚。

#### 情况 3：不同 case 其实不是一条规则

这一点特别容易误判。

看上去都是“排序结果测试”，但可能其实包含了：

- 默认推荐排序
- 章节号排序
- 收藏优先排序
- 权限过滤后的排序

如果这些规则本质不同，就不应该因为“都和排序有关”而强行塞进一个参数化测试。

所以更稳妥的判断方式是：

- 参数化复用的是同一条规则
- 不是同一个领域名词

### 模块 17：给 `Suite`、`Tag`、`Trait` 各自一个最小决策问题

学到这里，你可能还是会在写测试时犹豫：

- 到底该先想 `Suite`，还是先想 `Tag`，还是先加 `Trait`

可以问自己三个问题来进行决策。

#### 问题 1：这批测试是不是同一主题？

如果答案是“是”，先想：

- 要不要用 `@Suite`

因为 `Suite` 解决的是：

- 测试分组
- 主题归拢

它回答的问题是：

- “这些测试彼此为什么应该放在一起？”

#### 问题 2：这条测试以后会不会需要被筛选？

如果答案是“会”，再想：

- 要不要加 `Tag`

它回答的问题是：

- “这条测试属于什么语义类别？”

#### 问题 3：这条测试在运行时有没有额外约束？

如果答案是“有”，再想：

- 要不要加 `Trait`

它回答的问题是：

- “这条测试应该在什么条件下跑，或者怎么跑？”

这样你就不会把三者混成一个概念：

- `Suite` 管组织
- `Tag` 管分类
- `Trait` 管运行约束

### 模块 18：实际编码场景中的建议

如果你学完这一章后打算给自己的项目补更多 Swift Testing 测试，可以按这个顺序来：

1. 先把重复最严重的测试找出来
2. 判断它们是不是“同一条规则重复验证”
3. 如果是，先尝试改成参数化测试
4. 当某一类测试明显形成主题，再补 `@Suite`
5. 当你真的需要筛选某类测试时，再引入 `Tag`
6. 当你真的遇到运行条件问题时，再引入 `Trait`

之所以强调这个顺序，是因为很多人喜欢过来做：

- 先设计很多 suite
- 先起很多标签名
- 先给测试挂很多 trait
- 最后才发现最核心的重复根本没消掉

而本章的重心恰恰却是：

- **减少重复**

组织语义和运行约束都是重要的，但它们应该建立在测试主体已经够清楚的前提上。

## 本章小结

经过本章的学习，你应当已经对如何设计测试有了清晰的认知：

- `@Suite` 用来表达分组
- 参数化测试用来减少重复
- `Tag` 用来表达可筛选语义
- `Trait` 用来表达运行约束

而且应当对这些知识足够了解：

- `#expect` 是断言
- `Tag` 是标签
- `Trait` 是运行行为说明
- 参数化测试是复用测试逻辑的方式

更重要的是，你已经看到：

- 同一条规则可以不必复制成很多个测试函数

这会直接改善后续测试数量变多时的维护体验。

## 下一步建议

读完本章后，最自然的问题已经不是“怎么组织测试”，而是：

- 当业务逻辑开始带有异步调用、依赖注入、缓存回退时，这些测试该怎么写

这正是下一章的主题：

- `async throws` 测试
- fake / stub / spy
- 如何把前面讲过的“可测试设计”正式落成 Swift Testing 代码
