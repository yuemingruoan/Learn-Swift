# 53. Swift Package Manager 工程化入门：从多文件到多模块、Package.swift、Target 与 Product

## 阅读导航

- 前置章节：[03. Xcode 基础使用](./03-xcode-basics.md)、[46. 语言进阶：协议抽象、依赖注入与可测试设计](./46-protocol-abstraction-dependency-injection-and-testability.md)、[47. 工程化第一步：多文件协作、类型边界与项目拆分](./47-multi-file-project-organization-and-cross-file-collaboration.md)、[50. Swift Testing 入门：从 XCTest 到 @Test、#expect 与第一批单元测试](./50-swift-testing-basics-from-xctest-to-test-expect-and-require.md)、[52. Swift Testing 工程实践：异步测试、依赖替身与从 XCTest 渐进迁移](./52-swift-testing-async-doubles-and-gradual-migration.md)
- 上一章：[52. Swift Testing 工程实践：异步测试、依赖替身与从 XCTest 渐进迁移](./52-swift-testing-async-doubles-and-gradual-migration.md)
- 下一章：待定
- 适合谁读：已经理解“同一个 target 里多个 `.swift` 文件如何协作”，也知道测试 target、协议边界、依赖注入这些概念，现在开始想进一步理解“什么时候应该拆成多个 module / package”的读者

## 本章目标

学完这一章后，你应该能够：

- 理解 `package`、`target`、`product`、`dependency` 这四个词的含义
- 看懂一个最小 `Package.swift` 的结构
- 理解为什么需要多 target / 多 module 拆分”
- 把可复用业务逻辑放进 `library target`
- 把命令行入口放进 `executable target`
- 理解`public`对跨`target`工程的重要性
- 用 `swift run`、`swift test` 和 Xcode 三种方式实现`Swift Package`的运行与测试
- 判断什么时候使用“多文件工程”，什么时候应该升级成 package 工程

## 本章对应资源

- 文稿：`docs/zh-CN/chapters/53-swift-package-manager-from-multi-file-to-multi-module.md`
- 示例项目：`demos/projects/53-swift-package-manager-from-multi-file-to-multi-module`

## 本章怎么读

建议阅读顺序：

1. 先把前四节读完，先把 `package`、`target`、`product` 这些词的分工彻底理清。
2. 再跟着 demo 看 `Package.swift`、`Sources/`、`Tests/` 和两个 target 的职责拆分。
3. 最后回到“什么时候该拆 package、访问控制为什么会变重要、哪些东西本章故意不展开”这些工程判断。

## 正文主体

### 模块 0：为什么现在才讲 Swift Package Manager

如果你回头看第 47 章，会发现那一章已经把一条很重要的工程路线铺出来了：

- 不要把所有代码堆在 `main.swift`
- 要按职责拆成多个 `.swift` 文件
- 要把模型、服务、输出、入口分开

但第 47 章也明确留下了一个边界：

- 当时还不讲多 module / Swift Package 拆分

原因很简单：

- 当时更重要的是先把“同一个 target 内的工程整理”学清楚

如果你连这些基础都还没站稳，就太早进入 `Package.swift`、`target dependency`、`public` 这些话题，很容易把 Swift Package 误解成：

- “只是换一种目录结构”

但现在你已经知道：

- 同一个 target 内，多文件怎么按职责协作
- test target 和业务 target 是不同编译单元
- 可复用逻辑应该和入口壳层分开

所以这一章要继续完成第 47 章留下来的那条路线：

- 第 47 章：从单文件到多文件
- 本章：从多文件到多模块

也就是说，本章不是单独插进来的工具章节，而是工程化主线的下一步。

### 模块 1：第 47 章已经解决了什么，本章要补上什么

第 47 章解决的是：

- 同一个 target 内的职责拆分
- 同一个 module 内的访问规则
- 入口、模型、服务、输出之间的依赖方向

在那一章我们学到了：

- 文件是代码组织单位

这句话今天仍然成立。

但今天要多补一句：

- target 是编译组织单位

换句话说：

- 文件不是协作主体
- target 也不是协作主体
- 真正协作的仍然是类型、函数、协议和实例

只是现在它们不一定都处在同一个编译单元里了。

第 47 章的世界里，你更常看到的是：

- `StudyPlanService` 和 `StudyPlanRepository` 处在同一个 target
- 默认访问级别 `internal` 往往就够用
- 入口文件和业务文件一起被编译进同一个 module

而本章要讲解的是：

- `StudyPlanCore` 负责提供可复用业务逻辑
- `StudyPlanCLI` 负责提供命令行入口
- `StudyPlanCoreTests` 负责验证核心逻辑
- `StudyPlanCLI` 通过 `import StudyPlanCore` 使用核心能力

一语概之

- 第 47 章解决“怎么在一个屋里把东西收干净”
- 第 53 章解决“什么时候该分成两个房间，如何在它们之间建立联系”

### 模块 2：先来区分四个词语：`package`、`target`、`product`、`dependency`

如果你第一次接触 Swift Package Manager，最容易乱的不是语法，而是词。

很多人会把下面几个词混成一个意思：

- package
- target
- product
- dependency

这会导致你后面看到 `Package.swift` 时，感觉反反复复都在说一个东西。

我们先给它们各自一个最短定义。

#### `package`

`package` 是整个 Swift Package 的描述单位。

你可以先把它理解成：

- 一份工程级清单

它回答的问题是：

- 这个工程叫什么
- 它对外暴露什么成品
- 它内部有哪些 target
- 哪些 target 依赖哪些 target

也就是说：

- `package` 站在整个工程的视角上看问题

#### `target`

`target` 是编译单元。

它回答的问题是：

- 哪一组源代码会被一起编译
- 这一组代码依赖谁
- 这组代码最终产出什么角色

在 Swift Package 里，你最常见的 target 有三种：

- 普通 `target`
- `executableTarget`
- `testTarget`

你可以先把它们理解成：

- 库代码 target
- 可执行入口 target
- 测试代码 target

#### `product`

`product` 是交付出去给别人使用的成品。

它回答的问题是：

- 这个 package 对外提供什么东西

例如：

- 一个库
- 一个可执行程序

这时你应该立刻意识到：

- `target` 是内部编译组织
- `product` 是外部交付结果

两者强相关，但不是同一个概念。

#### `dependency`

`dependency` 是依赖关系声明。

它回答的问题是：

- 当前 target 要使用谁

这里又分两种层次：

- package 级依赖：当前 package 依赖另一个 package
- target 级依赖：当前 target 依赖同一个 package 内的另一个 target，或者来自外部 package 的 product

本章先只聚焦一种：

- 同一个 package 内 target 之间的依赖

#### 总结

如果你记不住上面这些概念，只要记住这些即可

- `package` 描述整个工程
- `target` 描述编译单元
- `product` 描述对外成品
- `dependency` 描述依赖关系

### 模块 3：本章 demo 场景


本章 demo 目录：

- `demos/projects/53-swift-package-manager-from-multi-file-to-multi-module`

它的结构如下：

```text
53-swift-package-manager-from-multi-file-to-multi-module/
├─ Package.swift
├─ Sources/
│  ├─ StudyPlanCore/
│  │  ├─ StudyTask.swift
│  │  ├─ StudyPlan.swift
│  │  ├─ StudyPlanRepository.swift
│  │  └─ StudyPlanService.swift
│  └─ StudyPlanCLI/
│     └─ main.swift
└─ Tests/
   └─ StudyPlanCoreTests/
      └─ StudyPlanServiceTests.swift
```

这个结构里有三个角色：

1. `StudyPlanCore`
2. `StudyPlanCLI`
3. `StudyPlanCoreTests`

它们分别负责：

- `StudyPlanCore`：放真正可复用的核心逻辑
- `StudyPlanCLI`：放命令行入口和依赖组装
- `StudyPlanCoreTests`：测试核心逻辑

你应该注意到：

- 这其实仍然在讲第 47 章那套职责拆分

只不过今天不是继续在一个 target 里拆文件，而是：

- 把职责稳定的一部分正式提到单独 target

而且如果你仔细观察会发现，这一章的demo不再有`.xcodeproj`文件

`package.swift`代替了它的职责

### 模块 4：`Package.swift` 长什么样

对应文件：

- `demos/projects/53-swift-package-manager-from-multi-file-to-multi-module/Package.swift`

先看最小可读版本：

```swift
// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "StudyPlanPackage",
    products: [
        .library(
            name: "StudyPlanCore",
            targets: ["StudyPlanCore"]
        ),
        .executable(
            name: "study-plan",
            targets: ["StudyPlanCLI"]
        ),
    ],
    targets: [
        .target(
            name: "StudyPlanCore"
        ),
        .executableTarget(
            name: "StudyPlanCLI",
            dependencies: ["StudyPlanCore"]
        ),
        .testTarget(
            name: "StudyPlanCoreTests",
            dependencies: ["StudyPlanCore"]
        ),
    ]
)
```

先不要着急背结构

让我们分成四块来分别讲解：

1. `swift-tools-version`
2. `name`
3. `products`
4. `targets`

#### `swift-tools-version` 在做什么

这一行：

```swift
// swift-tools-version: 6.0
```

不是普通注释。

它告诉 SwiftPM：

- 这个 package 期望按什么工具链能力来解析

你现在可以先把它理解成：

- “这份包描述按哪一代 Swift Package 规则来读”

本章不展开版本兼容细节，先知道它存在就够。

#### `name` 在做什么

这一行：

```swift
name: "StudyPlanPackage"
```

描述的是整个 package 的名字。

它不是：

- 某个 target 的名字
- 某个 product 的名字

它对应的是整个工程层级。

#### `products` 在做什么

这一段：

```swift
products: [
    .library(
        name: "StudyPlanCore",
        targets: ["StudyPlanCore"]
    ),
    .executable(
        name: "study-plan",
        targets: ["StudyPlanCLI"]
    ),
]
```

描述的是：

- 这个 package 对外提供哪些成品

这里我们提供了两个成品：

- 一个库：`StudyPlanCore`
- 一个可执行程序：`study-plan`

注意这里第一次出现了一个重要的概念：

- 同一个 package 可以同时提供库和可执行入口

因为在很多场景中我们既想：

- 把逻辑收进可复用库

又想：

- 保留一个可以直接跑起来的入口

#### `targets` 在做什么

这一段：

```swift
targets: [
    .target(
        name: "StudyPlanCore"
    ),
    .executableTarget(
        name: "StudyPlanCLI",
        dependencies: ["StudyPlanCore"]
    ),
    .testTarget(
        name: "StudyPlanCoreTests",
        dependencies: ["StudyPlanCore"]
    ),
]
```

描述的是：

- package 内部有哪些编译单元
- 每个编译单元依赖谁

只看这一段，你已经能读出整个结构：

- `StudyPlanCore` 是核心库 target
- `StudyPlanCLI` 是可执行 target，它依赖 `StudyPlanCore`
- `StudyPlanCoreTests` 是测试 target，它也依赖 `StudyPlanCore`

这就是一个非常干净的最小 package。

### 模块 5：`Sources/` 和 `Tests/` 为什么长这样

很多初学者第一次看到 package 目录时，会忍不住问：

- “我能不能不叫 `Sources`？”
- “我能不能把测试和源码放一起？”
- “我能不能随便建个 `Code/`、`MyFiles/`？”

从技术上说，SwiftPM 当然有更复杂的定制方式。

但是本章先使用最典型的结构：

```text
Sources/
Tests/
```

它的含义最为直接：

- `Sources/` 放源代码
- `Tests/` 放测试代码

再往下，每个 target 通常用自己名字对应一个目录：

```text
Sources/StudyPlanCore/
Sources/StudyPlanCLI/
Tests/StudyPlanCoreTests/
```

这么做的好处有三个。

#### 好处 1：目录一眼就和 target 对上

当你看到：

- `Sources/StudyPlanCore`

你几乎不需要猜：

- 这是谁的代码

当你看到：

- `Tests/StudyPlanCoreTests`

你也几乎不需要猜：

- 这是在测谁

对于一些大工程来说，这种直观感非常重要。

#### 好处 2：减少“目录命名”时的纠结

初学者在学工程组织时，本来就已经要同时理解：

- package
- target
- product
- access control

如果这时还要给目录取名，注意力会被无意义消耗掉。

#### 好处 3：更容易区分“文件属于哪个编译单元”

经过前面那么多章的学习，你会习惯一种感觉：

- 反正都在一个工程里

但 package 世界里更重要的不是：

- 这个文件在不在工程里

而是：

- 这个文件到底属于哪个 target

因为这直接决定：

- 它会和谁一起编译
- 它默认对谁可见
- 它能依赖谁

所以从这一章开始你要先养成一个习惯：

- **先看文件在哪个 target 目录里，再看它写了什么。**

### 模块 6：把领域模型放进 `StudyPlanCore`

对应文件：

- `demos/projects/53-swift-package-manager-from-multi-file-to-multi-module/Sources/StudyPlanCore/StudyTask.swift`
- `demos/projects/53-swift-package-manager-from-multi-file-to-multi-module/Sources/StudyPlanCore/StudyPlan.swift`

先看 `StudyTask.swift`：

```swift
public struct StudyTask: Equatable, Sendable {
    public let id: Int
    public let title: String
    public let estimatedHours: Int
    public var isFinished: Bool

    public init(id: Int, title: String, estimatedHours: Int, isFinished: Bool) {
        self.id = id
        self.title = title
        self.estimatedHours = estimatedHours
        self.isFinished = isFinished
    }
}
```

再看 `StudyPlan.swift`：

```swift
public struct StudyPlan: Equatable, Sendable {
    public let title: String
    public private(set) var tasks: [StudyTask]

    public init(title: String, tasks: [StudyTask]) {
        self.title = title
        self.tasks = tasks
    }

    public var unfinishedTaskCount: Int {
        tasks.filter { !$0.isFinished }.count
    }

    public var totalEstimatedHours: Int {
        tasks.reduce(0) { $0 + $1.estimatedHours }
    }

    public mutating func markTaskFinished(id: Int) -> Bool {
        guard let index = tasks.firstIndex(where: { $0.id == id }) else {
            return false
        }

        tasks[index].isFinished = true
        return true
    }
}
```

这里有两个值得你重点观察的点。

#### 观察点 1：为什么这些类型现在要写 `public`

在第 47 章里，很多类型默认写成：

- 不显式标访问级别

也就是默认 `internal`。

当时这样通常没问题，因为它们都在同一个 target 里。

但现在 `StudyPlanCLI` 要通过：

```swift
import StudyPlanCore
```

来使用这些类型。

这意味着：

- `StudyTask`
- `StudyPlan`

不再只给“自己这个 target 内部”使用。

它们已经变成：

- 需要被另一个 target 看到的公开 API

所以要写：

- `public struct`
- `public init`
- `public var`
- `public mutating func`

这就是跨 target 之后，第一个最直观的变化。

#### 观察点 2：`public` 不等于全部敞开

注意这里并不是把所有东西都无脑公开。

例如：

```swift
public private(set) var tasks: [StudyTask]
```

这表示：

- 外部可以读
- 外部不能随便写

这个设计非常像第 47 章的思路，只不过今天它不再只服务于：

- 同一 target 内的清晰职责

它还服务于：

- 跨 target 的稳定边界

所以 `public` 真正重要的地方，不是“把东西都放出去”。

而是：

- **决定什么应该被放出去**

在实际编码中，我们通常遵循最小暴露的原则，只把必要的接口或类暴露给外界

### 模块 7：把协议和服务也收口到核心 target

对应文件：

- `demos/projects/53-swift-package-manager-from-multi-file-to-multi-module/Sources/StudyPlanCore/StudyPlanRepository.swift`
- `demos/projects/53-swift-package-manager-from-multi-file-to-multi-module/Sources/StudyPlanCore/StudyPlanService.swift`

只把模型放进 `StudyPlanCore` 还不够。

真正可复用的通常不只是数据结构，还有围绕这些数据结构展开的业务动作。

先看仓储协议：

```swift
public protocol StudyPlanRepository {
    func loadPlan() throws -> StudyPlan
    func savePlan(_ plan: StudyPlan) throws
}
```

再看服务：

```swift
public enum StudyPlanServiceError: Error, Equatable {
    case taskNotFound(id: Int)
}

public struct StudyPlanService {
    private let repository: any StudyPlanRepository

    public init(repository: any StudyPlanRepository) {
        self.repository = repository
    }

    public func loadPlan() throws -> StudyPlan {
        try repository.loadPlan()
    }

    public func completeTask(id: Int) throws -> StudyPlan {
        var plan = try repository.loadPlan()

        guard plan.markTaskFinished(id: id) else {
            throw StudyPlanServiceError.taskNotFound(id: id)
        }

        try repository.savePlan(plan)
        return plan
    }
}
```

这里的组织方式，其实仍然完全延续第 46、47 章的路线：

- 仓储能力先抽成协议
- 业务服务只依赖协议
- 入口层负责提供具体实现

这同时说明了：

- `Swift Package Manager`不是要替换你前面学过的工程原则

恰恰相反，它是在给这些原则一个更稳定的容器。

#### 为什么协议放在 `Core` 里，而不是放在 `CLI` 里

因为从依赖方向看：

- `CLI` 依赖 `Core`

如果你把 `StudyPlanRepository` 写在 `CLI` 里，就会出现一个非常别扭的结构：

- 核心服务想依赖仓储协议
- 但协议却定义在入口 target 里

这样就会反过来逼你：

- 要么让 `Core` 依赖 `CLI`
- 要么把服务和入口搅在一起

两种都不对。

所以只要某个协议本身是核心业务的一部分，它就应该跟着核心逻辑一起留在核心 target。

#### 为什么不能 “为了拆而拆”

如果你只是机械地把文件挪来挪去，很容易变成：

- 看起来变成 package 了
- 实际上边界仍然混乱

判断方式其实很简单：

如果 `StudyPlanCore` 被单独拿出来后，它依然能回答下面这个问题：

- “除了CLI,是否有其它部分会使用它”

如果答案是：

- 是

那它就适合成为核心库 target。

### 模块 8：把入口放进 `StudyPlanCLI`

对应文件：

- `demos/projects/53-swift-package-manager-from-multi-file-to-multi-module/Sources/StudyPlanCLI/main.swift`

接下来再看 `main.swift`：

```swift
import StudyPlanCore

final class InMemoryStudyPlanRepository: StudyPlanRepository {
    private var plan = StudyPlan(
        title: "Swift 进阶学习计划",
        tasks: [
            StudyTask(id: 1, title: "复习协议与扩展", estimatedHours: 2, isFinished: true),
            StudyTask(id: 2, title: "阅读 Swift Testing 章节", estimatedHours: 3, isFinished: false),
            StudyTask(id: 3, title: "尝试拆出第一个 Swift Package", estimatedHours: 2, isFinished: false),
        ]
    )

    func loadPlan() throws -> StudyPlan {
        plan
    }

    func savePlan(_ plan: StudyPlan) throws {
        self.plan = plan
    }
}

let repository = InMemoryStudyPlanRepository()
let service = StudyPlanService(repository: repository)

let before = try service.loadPlan()
print("当前计划：\\(before.title)")
print("总预估学时：\\(before.totalEstimatedHours)")
print("未完成任务数：\\(before.unfinishedTaskCount)")

let updated = try service.completeTask(id: 2)
print("完成任务后，未完成任务数：\\(updated.unfinishedTaskCount)")
```

观察这段代码，你会发现：

- 入口 target 终于只负责“组装”和“启动”

也就是说它现在只负责这些内容：

- 具体仓储实现
- 依赖创建
- 程序启动

但下面这些内容已经被剥离到单独的`target`中了：

- 领域模型定义
- 核心业务规则
- 任务完成逻辑

这就是 package 工程化所带来的收益。

它让你更容易遵守第 47 章的要求：

- 入口不应该变成业务层垃圾桶

而不为组织代码花费过多的时间

#### 为什么 `InMemoryStudyPlanRepository` 可以不写 `public`

对于第一次接触`access control`的读者，这一点非常重要

`StudyPlanCLI` 是入口 target。

`InMemoryStudyPlanRepository` 只是给这个入口自己使用的内部实现。

它不需要被别的 target 使用。

所以它完全可以保持默认 `internal`。

这恰好说明：

- 不是所有类型都要加 `public`

真正需要加 `public` 的，是：

- 需要被其它`target`调用的部分

而不是：

- 自己内部的实现细节

### 模块 9：跨过去的不是“文件”，而是 module

这是本章最容易让人真正“通了”的地方。

初学者第一次做多文件时，常说：

- “A 文件怎么访问 B 文件？”

第 47 章已经纠正过这个说法：

- 真正协作的是同一 target 里的类型和实例

今天要继续往前纠正一步：

- 当 `StudyPlanCLI` 使用 `StudyPlanCore` 时，它也不是“main.swift 去访问另一个目录里的文件”

它真正做的事情是：

- `StudyPlanCLI` 这个 target 通过 `import StudyPlanCore` 使用另一个 module 暴露出来的 API

因此从这章开始最好修改一下自己的习惯：

- 少说“文件调用文件”
- 而是说“target 依赖 target”
- 更准确地说“当前 module 导入并使用另一个 module 的公开 API”

为什么这个语言习惯很重要？

因为它会直接影响你的设计判断。

如果你脑中想的是：

- “我只想让这个文件能访问那个文件”

很容易出现下面这些问题：

- 为了访问方便，把本该留在 CLI 的东西硬塞进 Core
- 为了少写一个协议，把依赖方向反过来
- 为了少写 `public`，干脆把所有东西重新堆到同一个 target

但如果你脑中想的是：

- “这是不是一个应该穿过 module 边界的能力”

你的判断就会稳定很多。

### 模块 10：为什么到了 package，`public` 突然被大量使用

很多人第一次学访问控制时，会觉得：

- `public` 好像很远

原因也很简单。

在单文件或者单 target 初学阶段，你最常碰到的其实是：

- `private`
- `fileprivate`
- 默认 `internal`

那时根本没必要使用`public`

而到了`package`阶段，它有了自己的使用场景

先看一个最典型的问题。

假设你把 `StudyPlan` 写成这样：

```swift
struct StudyPlan {
    let title: String
    var tasks: [StudyTask]
}
```

这在同一个 target 里通常没事。

但当 `StudyPlanCLI` 试图：

```swift
import StudyPlanCore
```

然后再使用 `StudyPlan` 时，你很可能会直接遇到访问问题。

- `StudyPlan` 默认只有 module 内部可见

也就是说：

- `StudyPlanCore` 自己内部当然能看到
- `StudyPlanCLI` 这个外部 module 看不到

所以从现在开始，你必须开始思考

这个`target`会被哪些实现调用

#### 什么时候该公开类型

当一个类型需要被其他 target 使用时，它通常要公开。

例如：

- 领域模型
- 服务类型
- 错误类型
- 协议边界

#### 什么时候不该公开类型

当一个类型只服务于 target 内部实现时，它通常不该公开。

例如：

- 某个具体缓存实现
- 某个命令行临时格式化器
- 某个只给测试辅助用的内部帮助类型

#### 什么时候要公开成员而不是只公开类型

这一点相信很多人都没想过。

即使你写了：

```swift
public struct StudyPlan
```

也不代表外部就一定能顺利创建和使用它。

如果构造器、属性、方法没有一并公开，外部仍然可能用不了。

例如：

```swift
public struct StudyPlan {
    let title: String
    init(title: String) {
        self.title = title
    }
}
```

这时外部 target 仍然不能直接初始化它。

所以从现在开始我们要建立一个新习惯：

- **不是只看“类型是不是 public”，还要看“真正要给外部用的成员是不是也 public”。**

### 模块 11：测试 target —— 衔接前面三章的测试知识

对应文件：

- `demos/projects/53-swift-package-manager-from-multi-file-to-multi-module/Tests/StudyPlanCoreTests/StudyPlanServiceTests.swift`

这一章虽然主题是`Swift Package Manager`，但它和前几章仍有不小的联系。

先看测试 target 配置：

```swift
.testTarget(
    name: "StudyPlanCoreTests",
    dependencies: ["StudyPlanCore"]
)
```

它表达的意思很直接：

- 测试 target 依赖核心 target

再看测试代码：

```swift
import Testing
@testable import StudyPlanCore

private final class InMemoryRepository: StudyPlanRepository {
    var plan: StudyPlan
    var saveCallCount = 0

    init(plan: StudyPlan) {
        self.plan = plan
    }

    func loadPlan() throws -> StudyPlan {
        plan
    }

    func savePlan(_ plan: StudyPlan) throws {
        self.plan = plan
        saveCallCount += 1
    }
}

@Test("完成已有任务时会保存更新后的计划")
func completeTaskUpdatesAndPersistsPlan() throws {
    let repository = InMemoryRepository(
        plan: StudyPlan(
            title: "Swift 进阶学习计划",
            tasks: [
                StudyTask(id: 1, title: "协议", estimatedHours: 2, isFinished: false),
                StudyTask(id: 2, title: "SPM", estimatedHours: 2, isFinished: false),
            ]
        )
    )
    let service = StudyPlanService(repository: repository)

    let updated = try service.completeTask(id: 2)

    #expect(updated.unfinishedTaskCount == 1)
    #expect(repository.plan.tasks.last?.isFinished == true)
    #expect(repository.saveCallCount == 1)
}
```

这里有三点需要注意。

#### 第一，前面学过的 Swift Testing 语法完全还能复用

前面我们已经学过：

- `@Test`
- `#expect`
- `#require`

现在它们只是换了个工程容器：

- 不再一定是在 `.xcodeproj` 的 `test target` 里
- 也可以在 `Swift Package` 的 `testTarget` 里使用

#### 第二，测试更为集中

由于核心逻辑已经被提到 `StudyPlanCore`，测试自然就更容易直接围绕它展开。

这比“通过整个 CLI 程序去间接验证”更稳定。

因为你真正想测的通常是：

- 完成任务规则
- 保存动作有没有发生
- 找不到任务时是否抛错

而不是：

- 某一条 `print(...)` 输出是否正常

#### 第三，package 会让“可测试边界”更具体

第 46 章讲依赖注入时，你已经知道：

- 边界先抽成协议，测试就更容易写

有了`Package`这件事变得更容易了

因为现在你能很清楚地区分：

- 哪部分是核心可复用逻辑
- 哪部分只是入口层壳子

这会让测试设计更自然。

### 模块 12：`swift run`、`swift test`、Xcode，三种入口分别怎么理解

第一次学 Swift Package 时，很多人会以为：

- 既然有 `Package.swift`，那是不是以后都只能在命令行里开发

这也是一个典型误解。

Swift Package 不是“只能在终端里用”的模式。

它更像是：

- 一种构建与组织代码的方式

具体怎么运行、怎么调试，可以有多种入口。

#### 入口 1：`swift run`

如果你的 package 里有 executable product，就可以运行：

```bash
swift run study-plan
```

它的含义是：

- 编译并运行可执行成品 `study-plan`

#### 入口 2：`swift test`

当你运行：

```bash
swift test
```

你做的事情是：

- 让 SwiftPM 编译并运行测试 target

这和第 50 章里在 Xcode 里按 `Command + U` 的目标是一样的：

- 运行测试

只是今天入口换成了命令行。

#### 入口 3：Xcode 打开 package

如果你更习惯图形界面，也完全可以用 Xcode 打开 package。

此时你依然可以：

- 查看源码
- 跳转定义
- 运行测试
- 调试程序

所以：

- Swift Package Manager 不等于“抛弃 Xcode”

你当然也可以使用`.xcodeproj`完成多`target`的定义

### 模块 13：为什么 `product` 和 `target` 不是一回事

这个点值得单独拿出来讲。

因为很多人在写 `Package.swift` 时，虽然表面上会写：

- `products`
- `targets`

但脑中仍然把它们当成同一个词。

我们来看一个例子：

```swift
products: [
    .library(
        name: "StudyPlanKit",
        targets: ["StudyPlanCore"]
    ),
],
targets: [
    .target(
        name: "StudyPlanCore"
    ),
]
```

这时你会看到：

- `product` 叫 `StudyPlanKit`
- `target` 叫 `StudyPlanCore`

为什么要这样分开？

因为它们回答的是不同的问题。

#### `target` 回答的是“怎么编译”

也就是：

- 哪组源码会一起编译

#### `product` 回答的是“对外交付什么”

也就是：

- 这个`package`向别人宣布，我提供一个名叫 `StudyPlanKit` 的库

在现阶段，你当然可以让它们同名。

这通常更省心。

但你必须知道：

- 同名只是一个常见选择
- 不是概念本身相同

例如：

- 一个 `product` 可能由一个或多个 `target` 组成
- `target`名和对外品牌名未必相同
- 外部依赖时，你拿到的是`product`，不是“随便 import 某个目录”

一语概之：

- `target` 是内部编译单位
- `product` 是外部交付成品

### 模块 14：什么时候该继续多文件，什么时候应该升级成 package

这是本章最实用的工程判断题之一。

不是所有项目都应该立刻上 package。

如果你一学到新工具就到处拆，很容易把小项目拆得比问题本身还复杂。

那么该如何判断是否需要拆分`target`呢？

#### 适合继续多文件的情况

- 项目还很小
- 代码仍然主要围绕一个入口展开
- 还没有明显的复用需求
- 测试也不需要和多个壳层分开
- 当前痛点主要仍然是“单文件太乱”

这时先做到：

- 模型、服务、输出、入口分离

通常就已经很值。

#### 适合升级到 package 的情况

当你开始出现下面这些情况时，拆分`target`是更好的选择

- 有一部分核心逻辑明显可以脱离入口独立存在
- 你希望命令行、App、测试共用同一份核心能力
- 你开始需要更清楚的 module 边界
- 你想强迫自己显式设计公开 API
- 你不想让入口层继续拥有过多业务实现

同样一语概之：

- 如果你的目标只是“把一个文件拆整齐”，第 47 章就够
- 如果你的目标已经变成“把一部分稳定能力独立成可复用模块”，那就该进入 package

### 模块 15：本章明确不展开什么

为了让这章保持集中，我们故意不展开下面这些主题：

- 远程第三方依赖接入
- 版本约束与语义化版本
- resources
- binary targets
- plugins
- macros
- 多平台条件编译

因为当前阶段的重点是：

- 多文件整理
- 多`target`拆分
- `Package.swift`
- 公开边界
- 测试目标
- 运行入口

只有先掌握了这些，你才能学会后面的高级特性

### 模块 17：从头再捋一遍 demo

这一章的知识都已经学完了，现在让我们再来重读一遍这个demo

#### 第一段：工程描述

`Package.swift` 负责声明：

- 这是一个叫 `StudyPlanPackage` 的 package
- 它提供一个库 product：`StudyPlanCore`
- 它提供一个可执行 product：`study-plan`
- 它内部有三个 target：
  - `StudyPlanCore`
  - `StudyPlanCLI`
  - `StudyPlanCoreTests`

#### 第二段：核心逻辑

`StudyPlanCore` 负责放：

- 领域模型 `StudyTask`、`StudyPlan`
- 协议边界 `StudyPlanRepository`
- 业务服务 `StudyPlanService`

这部分回答的问题是：

- “业务本身是什么”

而不去碰外部交互相关的内容

#### 第三段：入口壳层

`StudyPlanCLI` 负责：

- 提供具体仓储实现
- 创建服务
- 启动程序
- 输出结果

这部分回答的问题是：

- “这个程序怎么被运行起来”

不是：

- “核心规则是什么”

#### 第四段：测试

`StudyPlanCoreTests` 负责：

- 直接测试核心逻辑

这部分回答的问题是：

- “完成任务规则是否正确”
- “保存动作是否发生”
- “错误路径是否被保留”

也就是说，`package`结构天然把三个关注点分开了：

- 核心能力
- 运行壳层
- 测试验证

在实际工程中你应当能感受到它的价值

## 本章小结

这一章我们第一次从`.xcodeproj`进阶到了 `Swift Package Manager`。

经过了这一章的学习，你应该能够：

- 看懂`Package.swift`的语法
- 区分 `package`、`target`、`product`
- 用`test target`直接验证核心模块
- 能够判断在`target`中何时该使用`public`

把第 47 章和本章连起来看，会更容易理解：

- 第 47 章先解决“同一 target 内如何按职责拆文件”
- 本章进一步解决了“什么时候应该把稳定职责提成独立 target / module”

显然学会的不止是“如何写`package.swift`”

你学到的是：

- 如何将一个错综复杂的项目划分为一个个独立清晰的模块

这便是`Swift Package Manager`真正有价值的地方。
