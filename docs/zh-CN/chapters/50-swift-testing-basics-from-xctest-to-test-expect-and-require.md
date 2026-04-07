# 50. Swift Testing 入门：从 XCTest 到 @Test、#expect 与第一批单元测试

## 阅读导航

- 前置章节：[03. Xcode 基础使用](./03-xcode-basics.md)、[46. 语言进阶：协议抽象、依赖注入与可测试设计](./46-protocol-abstraction-dependency-injection-and-testability.md)
- 上一章：[49. SwiftData 同步工程：增量更新、冲突处理与离线一致性](./49-swiftdata-sync-engineering-incremental-update-conflict-resolution-and-offline-consistency.md)
- 下一章：[51. Swift Testing 组织与复用：Suite、参数化测试、Tag 与 Trait](./51-swift-testing-organization-parameterized-tags-and-traits.md)
- 适合谁读：即使你还没有写过任何测试、也没真正接触过 `XCTest` 或 `Swift Testing`，只要已经能看懂函数、结构体和 Xcode 工程结构，就可以从这一章开始

## 本章目标

学完这一章后，你应该能够：

- 说清什么叫“单元测试”、什么叫“断言”
- 理解 `Swift Testing` 和 `XCTest` 在今天的角色差异
- 用最小例子写出 `@Test`
- 初步理解 `@Suite` 在测试分组里的作用
- 用 `#expect` 表达真假判断与值比较
- 用 `#require` 处理可选值或前置条件
- 判断一个测试应该测什么、不该塞什么
- 在同一个项目中理解 `Swift Testing` 与 `XCTest` 并存的边界

## 本章对应资源

- 文稿：`docs/zh-CN/chapters/50-swift-testing-basics-from-xctest-to-test-expect-and-require.md`
- 示例项目：`demos/projects/50-swift-testing-basics-from-xctest-to-test-expect-and-require`
- Apple Developer 官方页面：
  - [Swift Testing 概览](https://developer.apple.com/cn/xcode/swift-testing/)
  - [Testing 框架文档](https://developer.apple.com/documentation/testing)
  - [XCTest 框架文档](https://developer.apple.com/documentation/xctest/)
  - [在 Xcode 中测试你的 App](https://developer.apple.com/cn/documentation/xcode/testing_your_apps_in_xcode/)
  - [Swift 文档注释与 Quick Help 标记格式](https://developer.apple.com/library/archive/documentation/Xcode/Reference/xcode_markup_formatting_ref/SymbolDocumentation.html)

## 本章怎么读

建议阅读顺序：

1. 先读前两节，把“测试到底是什么”“`XCTest` 和 `Swift Testing` 到底是什么关系”看清，不要一上来就背语法。
2. 再跟着 demo 看 `@Test`、`@Suite`、`#expect`、`#require` 这些最常接触到的入口。
3. 最后回到“怎么命名测试、怎么切测试粒度、什么时候还会看到 XCTest”这些工程判断。

## 正文主体

### 模块 0：为什么第 50 章才正式展开测试写法

如果你回看前面的章节，会发现我们其实并不是现在才第一次碰到“测试”这个词。

第 3 章在创建项目时已经提过：

- Xcode 里会让你选择 `Testing System`
- 新版模板里可以选择传统的 `XCTest`
- 也可以选择更新的 `Swift Testing`

但当时为什么没有直接教你写测试？

因为在入门阶段，更重要的是先知道：

- 测试 target 是什么
- 它和业务 target 的关系是什么
- Xcode 为什么会帮你生成这些文件

到了第 46 章，我们又讲了“可测试设计”。但当时仍然没有正式展开测试框架本身，而是强调另一件更底层的事：

- 如果你的依赖边界混乱，测试会非常难写

显然前面两次出现“测试”时，关注点都不是“测试语法”：

- 第 3 章关注的是项目结构认知
- 第 46 章关注的是代码边界与可替换依赖

而直到这一章，我们所学的知识终于足够支撑学习`Swift Testing`。

现在你已经知道：

- 什么是 Xcode 工程
- 什么是 target
- 什么是类型、函数、结构体、协议

也正因为这样，我们现在可以把注意力收束到真正的问题上：

- `Swift Testing` 到底怎么写
- 它和 `XCTest` 到底是什么关系
- 今天开始写单元测试时，默认应该怎么选

#### 如果你从没接触过任何测试，先把四个基本概念讲明白

后面所有内容，都会围绕下面四个词展开。

##### 单元测试

你可以先把“单元测试”理解成给一小段业务逻辑写自动检查代码，确认输入和输出是否符合预期。本章里的“单元”主要就是函数和纯逻辑规则。

##### 测试函数

测试函数本质上也是函数，只是职责不同：

- 业务函数负责“做事”
- 测试函数负责“检查做得对不对”

##### 断言

断言是测试里最核心的动作，也就是明确写下“我期望这里应该成立什么条件”。例如：

```swift
#expect(summary.completedCount == 2)
```

这句话的意思就是：我期望 `summary.completedCount` 等于 `2`。如果不成立，测试就失败。

##### test target

在 Xcode 工程里，可以先把它简单理解成：

- app target 放业务代码
- test target 放测试代码

测试代码之所以放在独立 target 里，是因为它不是给用户直接运行的功能，而是给开发者验证代码正确性用的。

### 模块 0A：先不要上来就测复杂业务，先测一个最小的 `add(_:_:)`

如果你是第一次写测试，最好的第一步通常不是直接去测业务服务、缓存、网络，而是：

- 先写一个极小函数
- 再给它写一条极小测试
- 然后观察“测试通过”和“测试失败”分别是什么感觉

先看这个函数：

```swift
func add(_ lhs: Int, _ rhs: Int) -> Int {
    lhs + rhs
}
```

测试本质上就是围绕这四件事展开：

- 传什么输入
- 执行什么函数
- 应该得到什么返回值
- 行为是否符合预期

因此这个简单的函数非常适合拿来观察和理解测试。

你甚至可以用一个符号来概括它的行为：

- `+`

### 模块 0B：基本的函数文档注释

如果你希望自己的函数在 Xcode 里有更清楚的 Quick Help 说明，可以在函数上方写文档注释。

例如：

```swift
/// 计算两个整数的和。
///
/// - Parameters:
///   - lhs: 第一个加数。
///   - rhs: 第二个加数。
/// - Returns: 两个整数相加后的结果。
func add(_ lhs: Int, _ rhs: Int) -> Int {
    lhs + rhs
}
```

这一段注释说明了三件事：

- 作用
- 参数
- 返回值

但第一次看到的读者肯定和当年路易十六面对大革命一样摸不着头脑

#### 固定格式部分

下面这些写法，是文档注释的固定格式：

```swift
///
/// - Parameters:
/// - Returns:
```

它们各自的作用是：

- `///`
  - 表示这一行是文档注释
  - 通常连续写在函数上方
- `- Parameters:`
  - 表示下面要开始说明参数
- `- Returns:`
  - 表示下面要说明返回值

这些标记是固定语法，不能改成别的词，否则会导致`Xcode`的`Quick Help`展示失效。

#### 需要你自己填写的部分

真正需要你根据函数内容来写的，是这些说明文字：

```swift
/// 计算两个整数的和。
///   - lhs: 第一个加数。
///   - rhs: 第二个加数。
/// - Returns: 两个整数相加后的结果。
```

这里需要你自己写清楚的是：

- 这一整个函数是干什么的
- 每个参数分别代表什么
- 返回值表达的业务含义是什么

也就是说：

- `Parameters` 和 `Returns` 这些词更像是栏目名
- 后面的中文解释才是你真正填写的内容

#### 参数说明里，哪些部分不能写错

参数说明最容易出错的地方，是这一段：

```swift
/// - Parameters:
///   - lhs: 第一个加数。
///   - rhs: 第二个加数。
```

这里有两层信息：

- `lhs`、`rhs`
  - 必须和函数参数名一致
- 冒号后面的中文句子
  - 是你对这个参数含义的解释

例如函数是：

```swift
func add(_ lhs: Int, _ rhs: Int) -> Int
```

那注释里就应该写：

- `lhs`
- `rhs`

而不应该随手写成：

- `left`
- `right`

因为这样会让文档说明和函数真实参数对不上。

#### 你可以先套一个最小模板，再往里填内容

对零基础读者来说，直接记忆模板反倒是最省事的方式：

```swift
/// 这个函数做什么。
///
/// - Parameters:
///   - 参数名1: 这个参数表示什么。
///   - 参数名2: 这个参数表示什么。
/// - Returns: 返回值表示什么。
func example(...) -> SomeType { ... }
```

以后你每写一个函数，都可以先问自己三件事：

1. 我这个函数到底在做什么
2. 每个参数各自代表什么
3. 返回值对调用方意味着什么

能把这三件事写清楚，通常也更容易继续往下写测试。

这类注释不是必须的，但它会逼你先把函数说清楚。函数的作用、参数、返回值越清楚，测试写起来也越容易。

~~但是在多人项目中不写注释你可能会收到来自其它协作者的问候~~

`Apple`对这套`Quick Help`标记格式有官方说明，想深入了解的可以看这里：

- [Apple Developer: Swift 文档注释与 Quick Help 标记格式](https://developer.apple.com/library/archive/documentation/Xcode/Reference/xcode_markup_formatting_ref/SymbolDocumentation.html)

### 模块 0C：写出第一条测试

函数有了，接下来给它写一条最简单的测试。

先看 Swift Testing 版本：

```swift
import Testing
@testable import swiftTestingBasics

struct AddTests {
    @Test("add 会返回两个整数的和")
    func addReturnsSum() {
        let result = add(2, 3)

        #expect(result == 5)
    }
}
```

具体解释一下：

1. `import Testing`
   - 导入测试框架
2. `@testable import swiftTestingBasics`
   - 导入被测试的业务模块
3. `struct AddTests`
   - 用一个普通类型装相关测试
4. `@Test(...)`
   - 标记“下面这个函数是一条测试”
5. `let result = add(2, 3)`
   - 调用真正要测的函数
6. `#expect(result == 5)`
   - 断言结果应该等于 5

如果把它再翻译成人话，就是：

- 当我传入 `2` 和 `3` 时，`add` 应该返回 `5`

这已经是一条完整测试了。虽然它很简单，但它已经把测试的骨架完整展示出来了：

- 准备输入
- 调用函数
- 断言结果

如果你打开本章 demo，会发现这个最小例子已经作为真实文件放进项目里了：

- `swiftTestingBasics/Add.swift`
- `swiftTestingBasicsTests/AddTests.swift`

#### 如果你想最快感受到“测试在观察行为”，故意让它失败一次

很多新手第一次写测试时，不是不会敲，而是不知道测试到底在观察什么。最直接的办法就是让它故意失败一次。

例如你把断言改成：

```swift
#expect(result == 6)
```

或者你把 `add` 函数错误地写成：

```swift
func add(_ lhs: Int, _ rhs: Int) -> Int {
    lhs - rhs
}
```

这时测试就会失败。

失败带来的价值不是“出错了”，而是：

- 它在明确告诉你“函数当前行为”和“你期望的行为”不一致

这就是测试最根本的作用：

- 自动观察代码行为
- 在行为偏离预期时立刻报警

如果你后面在 Xcode 里运行测试，通常会看到：

- 哪一条测试失败了
- 失败的断言是什么
- 当前表达式为什么不成立

`Apple`关于测试运行与结果阅读也有官方文档：

- [Apple Developer: Running tests and interpreting results](https://developer.apple.com/documentation/xcode/running-tests-and-interpreting-results)

### 模块 1：先把结论说清楚，避免一开始就误判技术边界

这一章一开头必须先澄清一个概念：

- `Swift Testing` 是更新的测试框架
- 但它不代表`XCTest`从此作废

#### 常见的误解

- “既然 Swift Testing 更新，那以后所有测试都应该统一改成 Swift Testing。”

- “既然历史上很多项目都在用 XCTest，那 Swift Testing 可能只是包装层，没必要学。”

显然这两种想法都是错误的。

更准确的理解是：

- `Swift Testing`是`Apple`现在为`Swift`代码提供的更新的`unit test`写法
- 它的`API`更贴近现代`Swift`表达方式
- 它和`Swift`语言特性、宏能力、并发模型结合得更自然

但与此同时：

- `XCTest` 仍然会继续存在
- UI 自动化测试仍然主要建立在 `XCTest / XCUI` 体系上
- 性能测试也仍然常见地写在 `XCTestCase` 体系里
- 老项目中已有的大量测试也不需要一夜之间全部重写

一语概之：

- **对新的 unit test，优先学 Swift Testing；对已有 XCTest 工程，渐进迁移；对 UI tests 和 performance tests，继续认识 XCTest 的边界。**

`Apple Developer`官方文档中也给出了同方向的信息：

- `Swift Testing` 官方页面把它定位成新的测试框架
- `XCTest` 官方文档则明确说明：新的 unit test 开发可以优先考虑 Swift Testing，同时 XCTest 仍覆盖 unit tests、performance tests、UI tests 等场景

原文链接如下：

- [Apple Developer: Swift Testing 概览](https://developer.apple.com/cn/xcode/swift-testing/)
- [Apple Developer: XCTest](https://developer.apple.com/documentation/xctest/)

#### 为什么 Swift Testing 更适合今天的新单元测试

因为它需要解决的已经不是“能不能写测试”，而是“测试写起来是否更自然”。

它的核心改进体现在三个方向：

1. 写法更轻
2. 断言更贴近表达式
3. 参数化、trait、tag 这些能力更统一

### 模块 2：XCTest vs Swift Testing，最小代码对比

先看传统 `XCTest` 风格：

```swift
import XCTest

final class StudyProgressTests: XCTestCase {
    func testSummaryCountsCompletedTasks() {
        let tasks = [
            StudyTask(title: "阅读第 50 章", estimatedMinutes: 20, isCompleted: true),
            StudyTask(title: "运行示例", estimatedMinutes: 30, isCompleted: false),
        ]

        let summary = StudyProgress.summary(for: tasks)

        XCTAssertEqual(summary.completedCount, 1)
        XCTAssertEqual(summary.remainingCount, 1)
        XCTAssertEqual(summary.totalMinutes, 50)
    }
}
```

再看 Swift Testing 风格：

```swift
import Testing

struct StudyProgressTests {
    @Test("summary 会统计已完成数量、剩余数量和总时长")
    func summaryTracksCountsAndMinutes() {
        let tasks = [
            StudyTask(title: "阅读第 50 章", estimatedMinutes: 20, isCompleted: true),
            StudyTask(title: "运行示例", estimatedMinutes: 30, isCompleted: false),
        ]

        let summary = StudyProgress.summary(for: tasks)

        #expect(summary.completedCount == 1)
        #expect(summary.remainingCount == 1)
        #expect(summary.totalMinutes == 50)
    }
}
```

如果你从来没有见过这两套写法，不要急着直接比差异。

先把它们都当成：

- “用来检查业务逻辑的代码”

然后分别逐行看。

#### 先把 XCTest 代码逐行拆开

先看这一行：

```swift
import XCTest
```

它的意思是：

- 导入 `XCTest` 框架

也就是告诉当前文件：

- 接下来我要使用 `XCTest` 提供的测试能力

再看：

```swift
final class StudyProgressTests: XCTestCase
```

对于初学者来说，先不用把它想得太复杂。

你只需要先记住：

- `class` 表示这里定义了一个类
- `StudyProgressTests` 是这个测试类的名字
- `: XCTestCase` 表示它继承自 `XCTest` 的测试基类

在传统 `XCTest` 写法里，你能在各种地方看到：

- 继承 `XCTestCase` 的类

再看：

```swift
func testSummaryCountsCompletedTasks() { ... }
```

这是一条测试方法。

它也是函数，只是放在测试类里，而且通常会用：

- `test...`

开头命名。

为什么要这样命名？

~~显然不是闲的蛋疼~~

因为在传统 `XCTest` 风格里，框架会靠这类命名习惯识别：

- 哪些方法是测试

最后看：

```swift
XCTAssertEqual(summary.completedCount, 1)
```

这是 `XCTest` 里的断言函数。

它的意思是：

- 检查左边的值和右边的值是否相等

如果不相等：

- 这条测试失败

所以这整个 `XCTest` 翻译成人话就是：

1. 导入 `XCTest`
2. 声明一个测试类
3. 在类里写一个测试方法
4. 调用业务函数
5. 用 `XCTAssertEqual` 检查结果

#### 再把 Swift Testing 代码逐行拆开

再看这一行：

```swift
import Testing
```

它和刚才的 `import XCTest` 作用很像：

- 导入 `Swift Testing` 框架

再看承载测试的类型：

```swift
struct StudyProgressTests
```

这里用的是 `struct`，不是 `class`。

这恰好在提醒你：

- `Swift Testing` 不要求你一定写 `XCTestCase` 子类

这个 `struct` 只是：

- 用来把相关测试放在一起的普通类型

真正让测试函数被识别出来的关键，不是类型继承，而是下面这行：

```swift
@Test("summary 会统计已完成数量、剩余数量和总时长")
```

这里的 `@Test` 可以先把它理解成：

- “告诉测试框架：下面这个函数是一条测试”

括号里的中文字符串则是：

- 这条测试展示给人看的名字

然后看函数本体：

```swift
func summaryTracksCountsAndMinutes() { ... }
```

它也是一个普通函数。

但和 `XCTest` 不同的是，这里不需要靠：

- `test...`

这种命名规则来告诉框架“我是测试函数”。

最后看断言：

```swift
#expect(summary.completedCount == 1)
```

它表达的是：

- 我期望这个布尔表达式成立

也就是说，`Swift Testing` 更鼓励你把“想判断的条件”直接写成表达式。

所以整段 `Swift Testing` 示例，也可以翻译成人话：

1. 导入 `Testing`
2. 用一个普通类型装测试
3. 用 `@Test` 标出测试函数
4. 调用业务函数
5. 用 `#expect` 直接写出期望条件

你应该能看出来这里有几处差异：

#### 差异 1：`XCTestCase` 类 vs `@Test` 普通函数

在 `XCTest` 里，通常会用这样的写法：

- 一个继承自 `XCTestCase` 的类
- 多个以 `test...` 开头的方法

在 `Swift Testing` 里，你更常看到：

- 一个普通的 `struct` / `actor` / `class` / `enum`
- 或者甚至不强调承载类型
- 重点是测试函数用 `@Test` 标出来

也就是说，焦点从：

- “这个类是不是测试类”

转成了：

- “这个函数是不是测试用函数”

#### 差异 2：`XCTAssert...` 系列 vs `#expect`

`XCTest` 常见写法是：

- `XCTAssertEqual`
- `XCTAssertTrue`
- `XCTAssertNil`
- `XCTAssertThrowsError`

`Swift Testing` 更强调：

- 直接把你真正想判断的表达式写出来

例如：

```swift
#expect(summary.completedCount == 1)
#expect(nextTask == nil)
#expect(titles.contains("Swift Testing 基础"))
```

这里的好处不只是“短”，而是：

- 更佳的可读性
- 失败时能够保留更多上下文

#### 差异 3：测试显示名更自然

`XCTest` 的方法名很多时候很像接口名：

- `testSummaryCountsCompletedTasks`
- `testNextTaskReturnsNilWhenEverythingIsDone`

这不影响代码运行，但它经常会让测试读起来像接口声明，而且常常导致开发者不知道这个函数对应哪个测试。

`Swift Testing` 可以直接写显示名：

```swift
@Test("当所有任务都已完成时，nextTask 返回 nil")
```

这让测试在测试报告和 Xcode 左侧列表里更接近一句完整中文说明。

#### 差异 4：并存，而不是互斥

本章 demo 故意在同一个 unit test target 里放了两种写法：

- `SwiftTestingBasicsTests.swift`
- `XCTestComparisonTests.swift`

当然我不是为了“鼓励混写”，而是为了让你意识到：

- 同一个测试 target 里，Swift Testing 与 XCTest 可以同时存在
- 但**不要在同一个测试函数里混用两套断言风格**

换句话说，允许并存，但不推荐无条理地混用。

### 模块 3：先认识本章 demo 里的业务代码

这一章暂时不涉及网络、文件、数据库、异步任务，只用一组纯逻辑函数。

因为我们当前学习的是：

- 测试框架的最小写法

不是：

- 如何处理副作用
- 如何写 fake / stub / spy
- 如何测试 async service

这些内容会放到后面两章。

本章 demo 的业务代码是：

```swift
import Foundation

struct StudyTask: Equatable {
    let title: String
    let estimatedMinutes: Int
    let isCompleted: Bool
}

struct StudySummary: Equatable {
    let completedCount: Int
    let remainingCount: Int
    let totalMinutes: Int
    let completionRate: Double
}

enum StudyProgress {
    static func summary(for tasks: [StudyTask]) -> StudySummary {
        let completedCount = tasks.filter(\.isCompleted).count
        let totalMinutes = tasks.reduce(0) { $0 + $1.estimatedMinutes }
        let completionRate = tasks.isEmpty ? 0 : Double(completedCount) / Double(tasks.count)

        return StudySummary(
            completedCount: completedCount,
            remainingCount: tasks.count - completedCount,
            totalMinutes: totalMinutes,
            completionRate: completionRate
        )
    }

    static func nextTask(in tasks: [StudyTask]) -> StudyTask? {
        tasks.first { !$0.isCompleted }
    }

    static func completionLabel(for summary: StudySummary) -> String {
        if summary.completedCount == 0 {
            return "刚刚开始"
        }

        if summary.remainingCount == 0 {
            return "已完成"
        }

        if summary.completionRate >= 0.5 {
            return "过半"
        }

        return "继续推进"
    }

    static func allTaskTitlesAreValid(_ tasks: [StudyTask]) -> Bool {
        tasks.allSatisfy { task in
            !task.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
    }
}
```

之所以用这一组代码作为测试示例，是因为它有三个特点：

1. 输入输出很清楚
2. 没有副作用
3. 可以稳定覆盖几种不同判断

也就是说，当你第一次学测试框架时，应该尽量先挑这种对象练手：

- 规则明确
- 不依赖外部环境
- 出错路径好解释

### 模块 4：`import Testing` 和 `@Test` 到底在做什么

本章最小的 Swift Testing 实现是：

```swift
import Testing
@testable import swiftTestingBasics

struct SwiftTestingBasicsTests {
    @Test("summary 会统计已完成数量、剩余数量和总时长")
    func summaryTracksCountsAndMinutes() {
        let summary = StudyProgress.summary(for: sampleTasks)

        #expect(summary.completedCount == 2)
        #expect(summary.remainingCount == 1)
        #expect(summary.totalMinutes == 65)
    }
}
```

先拆开看。

#### `import Testing`

这表示你正在使用 Swift Testing 框架。

这是一套新的测试 API 入口。

#### `@testable import swiftTestingBasics`

这和你在 `XCTest` 里看到的 `@testable import` 没本质区别：

- 测试 target 需要访问被测模块
- `@testable` 允许你访问 `internal` 级别符号

这里要注意一个边界：

- `@testable` 是“让测试能看到模块内部 API”
- `Testing` 是“让你能用 Swift Testing 的测试写法”

这两个概念不是一回事。

#### `@Test`

这是真正让函数被测试运行器识别成“测试用例”的标记。

你可以把它先理解成：

- “告诉测试系统，这个函数需要被当成测试执行”

它后面可以带显示名、trait、参数化输入等信息。

本章先只把它当成：

- 标记一个最普通的测试函数

### 模块 4A：先认识一下 `@Suite`

到这里为止，你已经看到：

- 可以用一个普通类型把相关测试放在一起
- 可以用 `@Test` 标记其中的测试函数

例如：

```swift
struct SwiftTestingBasicsTests {
    @Test("summary 会统计已完成数量、剩余数量和总时长")
    func summaryTracksCountsAndMinutes() { ... }
}
```

但在 `Swift Testing` 里，除了 `@Test` 之外，还有一个之后会频繁见到的标记：

- `@Suite`

先给当前阶段一个够用的结论：

- `@Test` 标的是“一条测试”
- `@Suite` 标的是“一组测试”

例如同样一组测试，也可以写成：

```swift
@Suite("Study progress basics")
struct SwiftTestingBasicsTests {
    @Test("summary 会统计已完成数量、剩余数量和总时长")
    func summaryTracksCountsAndMinutes() { ... }
}
```

这里的 `@Suite` 可以先理解成：

- 给这组测试一个更明确的分组身份
- 让测试报告和工具更容易把它当成同一个测试集合来看

#### 为什么本章前面的例子没有急着写 `@Suite`

因为在这章我们的重点是：

- 先会写一条测试
- 知道 `@Test` 怎么标记测试函数
- 知道 `#expect` 和 `#require` 分别解决什么问题

也就是说：

- `@Suite` 很有用
- 但我们还用不着

你完全可以先把它理解成：

- “给测试组加说明和元数据的入口”

等测试开始变多后，`@Suite` 的价值才会迅速放大，例如：

- 给一组测试起统一显示名
- 给整组测试加共同的 tag 或 trait
- 让不同主题的测试边界更清楚

这些内容会在下一章系统展开。本章你先记住最核心的区别就够了：

- `@Test` 负责“这是哪一条测试”
- `@Suite` 负责“这一组测试共同在测什么”

### 模块 5：`#expect` 断言

在 Swift Testing API，最重要的就是：

- `#expect`

因为它是最常用的判断方式。

来看本章第一组测试：

```swift
import Testing
@testable import swiftTestingBasics

struct SwiftTestingBasicsTests {
    private let sampleTasks = [
        StudyTask(title: "阅读第 50 章", estimatedMinutes: 20, isCompleted: true),
        StudyTask(title: "运行示例", estimatedMinutes: 30, isCompleted: false),
        StudyTask(title: "整理笔记", estimatedMinutes: 15, isCompleted: true),
    ]

    @Test("summary 会统计已完成数量、剩余数量和总时长")
    func summaryTracksCountsAndMinutes() {
        let summary = StudyProgress.summary(for: sampleTasks)

        #expect(summary.completedCount == 2)
        #expect(summary.remainingCount == 1)
        #expect(summary.totalMinutes == 65)
    }
}
```

这一段其实已经覆盖了三种最常见的初学者需求：

1. 判断某个结果是不是等于某个值
2. 判断多个字段是不是都符合预期
3. 把一个业务规则拆成多个独立判断

#### 为什么这里不用“一条大断言”包住全部结果

例如你也可以写：

```swift
#expect(summary == StudySummary(
    completedCount: 2,
    remainingCount: 1,
    totalMinutes: 65,
    completionRate: 2.0 / 3.0
))
```

这并不是不行。

但在教学阶段，当前写成三条更好，因为它帮助你建立一个更稳定的习惯：

- 一个测试可以验证一个业务结论
- 但这个结论通常会拆成几个并列事实

例如“summary 计算正确”这件事，本身就包含：

- 已完成数量对
- 剩余数量对
- 总时长对

把这三条拆开，会比一条大对象比较更容易读。

#### `#expect` 不只会做相等判断

它也常用于真假判断：

```swift
#expect(StudyProgress.allTaskTitlesAreValid(sampleTasks))
#expect(!StudyProgress.allTaskTitlesAreValid(invalidTasks))
```

这时你可以把它理解成：

- 直接验证一个业务表达式本身

这也是 Swift Testing 很自然的一点：

- 你的断言更像业务判断句
- 而不是“先挑一个特定 assert API，再把参数塞进去”

### 模块 6：`#require` 什么时候比 `#expect` 更合适

光会 `#expect` 还不够。

因为测试里经常会出现一种情况：

- 你后面的断言必须建立在“某个值非空”这个前提上

例如本章这个测试：

```swift
@Test("nextTask 会返回第一项未完成任务")
func nextTaskReturnsFirstIncompleteTask() throws {
    let nextTask = try #require(StudyProgress.nextTask(in: sampleTasks))

    #expect(nextTask.title == "运行示例")
    #expect(nextTask.estimatedMinutes == 30)
}
```

这里 `StudyProgress.nextTask(in:)` 的返回值是：

- `StudyTask?`

也就是说，它可能是 `nil`。

如果你只写：

```swift
let nextTask = StudyProgress.nextTask(in: sampleTasks)
```

那你后面每一步都要继续解包。

而测试里的真实意图是：

- “这个值在这里必须存在，如果不存在，这个测试就没必要继续往下跑”

这就是 `#require` 最适合的场景。

#### 先记一句话

- `#expect` 更像“我在验证一个条件”
- `#require` 更像“后续逻辑成立所依赖的前置条件必须满足”

如果你把两者混成一种用法，测试虽然也能写，但表达意图会变弱。

#### 用 `#expect` 也能写吗

可以，比如这样：

```swift
let nextTask = StudyProgress.nextTask(in: sampleTasks)
#expect(nextTask != nil)
#expect(nextTask?.title == "运行示例")
```

这不是错。

但它有两个问题：

1. 后面的断言都要继续带着 `?`
2. 如果 `nextTask` 为 `nil`，后面表达会变得更绕

而 `#require` 会让测试在语义上更直接：

- 先拿到一个必须存在的值
- 再继续断言它的内部字段

### 模块 7：测试命名到底该怎么写

这一章要顺手建立一个非常重要的习惯：

- 测试名应该先表达行为，再表达场景

例如下面这类写法，可读性通常比较弱：

```swift
@Test
func test1() {}

@Test
func checkSummary() {}
```

它们的问题不是“不能运行”，而是：

- 测试报告里几乎不给你业务信息

相比之下，本章写法更推荐：

```swift
@Test("summary 会统计已完成数量、剩余数量和总时长")
func summaryTracksCountsAndMinutes() { ... }
```

这里你会同时看到两层命名：

#### 层 1：显示名

给测试报告、左侧列表、人类阅读。

例如：

- `summary 会统计已完成数量、剩余数量和总时长`

#### 层 2：函数名

给源码导航、自动补全、代码搜索。

例如：

- `summaryTracksCountsAndMinutes`

如果你问“这两个都要吗”，我的建议是：

- 在教学和业务项目里，通常都值得保留

因为它们分别服务：

- UI 可读性
- 代码可维护性

### 模块 8：一个测试应该测多大粒度

这也是初学者最容易走歪的地方之一。

有的人会写得过碎：

- 一个字段一条测试
- 一个 if 一条测试

有的人会写得过大：

- 一个测试函数里把全部业务路径都测了

本章这个 demo 刻意放在中间位置。

例如：

- `summaryTracksCountsAndMinutes`

它不是只测一个字段，也不是把 `summary`、`nextTask`、`completionLabel` 全塞一起。

它只负责一个业务结论：

- `summary(for:)` 的汇总逻辑正确

而这个业务结论内部，再拆成几条并列事实。

这就是一个比较稳定的粒度。

#### 判断方式

写测试前先问自己：

- “如果这个测试失败，我能不能立刻知道是哪一段业务结论坏了？”

如果答案是否定的，通常说明：

- 测试太大

如果你发现测试多到每次读都像在看重复代码，通常说明：

- 测试太碎

### 模块 9：本章为什么还保留一个 XCTest 对照文件

本章 demo 里除了 Swift Testing 文件外，还有一份：

```swift
import XCTest
@testable import swiftTestingBasics

final class XCTestComparisonTests: XCTestCase {
    func testSummaryWithXCTestAssertionStyle() {
        let tasks = [
            StudyTask(title: "阅读第 50 章", estimatedMinutes: 20, isCompleted: true),
            StudyTask(title: "运行示例", estimatedMinutes: 30, isCompleted: false),
        ]

        let summary = StudyProgress.summary(for: tasks)

        XCTAssertEqual(summary.completedCount, 1)
        XCTAssertEqual(summary.remainingCount, 1)
        XCTAssertEqual(summary.totalMinutes, 50)
    }
}
```

这份文件的存在是为了讲三件很现实的事：

#### 第一，老项目里你一定会看到 XCTest

如果你以后进团队项目，你几乎不可能只看到一种测试风格。

你会看到：

- 历史 XCTest
- 新写的 Swift Testing
- UI tests 里的 XCTest/XCUI

所以这一章必须让你对 XCTest 的外观保持识别能力。

#### 第二，并存不是问题，混写才是问题

这句话很关键：

- 同一 target 中可以并存
- 但不要在同一个测试函数里混用 `XCTAssert...` 和 `#expect`

原因很简单：

- 断言风格混用会让测试可读性变差
- 也不利于团队逐步统一风格

#### 第三，本章不是要教你“大迁移”

本章只给你迁移方向，不给你大而全迁移策略。

因为真正合理的迁移策略，必须建立在你已经会：

- 写基础 Swift Testing
- 组织 Swift Testing 文件
- 处理 async 测试

这些内容会留到之后的章节。

### 模块 10：运行测试时，你在 Xcode 里应该关注什么

本章不展开完整 Xcode 测试面板教程，但你至少应该知道观察点：

#### 观察点 1：测试 target 是谁

先确认你运行的是 unit test target，而不是 app target 本身。

本章 demo 里你应该重点看：

- `swiftTestingBasicsTests`

#### 观察点 2：Swift Testing 和 XCTest 都会出现在测试列表里

这正是本章要表达的并存现实。

你会同时看到：

- `SwiftTestingBasicsTests/...`
- `XCTestComparisonTests...`

#### 观察点 3：失败信息不一样

当 `#expect` 失败时，你会看到更贴近表达式的失败描述。

而 `XCTest` 往往更多表现为：

- 某个 `XCTAssert...` 失败

两者都能定位问题，但 Swift Testing 在表达式视角上通常更自然。

## 本章小结

经过这一章的学习，你应该已经理解了以下概念：

- `Swift Testing` 是更新的 unit test 写法
- `XCTest` 仍然有现实价值，尤其在 UI tests 和 performance tests 里
- `@Test` 是测试函数入口
- `@Suite` 用来表达一组相关测试，但最小示例里可以先不写
- `#expect` 是最常用的断言方式
- `#require` 适合处理必须成立的前置条件
- 同一 target 里允许并存，但不要在同一个测试里混用两套风格

## 下一步建议

显然你已经能编写最简单的测试了，但是实际的工程会远比这个小demo复杂，例如你会遇到这些问题：

- 当测试变多以后，怎么组织
- 当同一条规则要覆盖多组输入时，怎么用参数化测试减少重复

让我们继续下一章的阅读，来解决这些问题：

[51. Swift Testing 组织与复用：Suite、参数化测试、Tag 与 Trait](./51-swift-testing-organization-parameterized-tags-and-traits.md)
