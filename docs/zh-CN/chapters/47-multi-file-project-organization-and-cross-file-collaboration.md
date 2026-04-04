# 47. 工程化第一步：多文件协作、类型边界与项目拆分

## 阅读导航

- 前置章节：[12. 函数与代码复用](./12-functions-and-code-reuse.md)、[13. 结构体与最基础的自定义类型](./13-structs-and-custom-types.md)、[21. 协议：比继承更灵活的抽象方式](./21-protocols-flexible-abstraction.md)、[46. 语言进阶：协议抽象、依赖注入与可测试设计](./46-protocol-abstraction-dependency-injection-and-testability.md)
- 上一章：[46. 语言进阶：协议抽象、依赖注入与可测试设计](./46-protocol-abstraction-dependency-injection-and-testability.md)
- 建议下一章：[48. SwiftData 工程建模：DTO、持久化模型与领域边界](./48-swiftdata-engineering-modeling-dto-persistence-and-domain-boundaries.md)
- 下一章：[48. SwiftData 工程建模：DTO、持久化模型与领域边界](./48-swiftdata-engineering-modeling-dto-persistence-and-domain-boundaries.md)
- 适合谁先读：已经能写“单文件里能跑起来的程序”，但开始觉得一个文件里同时塞模型、流程、输出和依赖组装越来越乱的读者

## 本章目标

学完这一章后，你应该能够：

- 说清“多文件之间通讯”本质上不是文件互相发消息，而是同一个 target 里的类型、函数、协议和实例彼此协作
- 理解为什么前面章节常用单文件，而工程化阶段必须开始把职责拆到多个 `.swift` 文件
- 用一个最小控制台项目把模型、仓储、服务、输出层和入口分开
- 看懂同一 target 内跨文件可见性的基本规则：`internal`、`private`、`fileprivate`
- 理解依赖为什么应该通过构造注入流动，而不是靠全局变量和“谁都能拿到谁”

## 本章对应资源

- 文稿：`docs/zh-CN/chapters/47-multi-file-project-organization-and-cross-file-collaboration.md`
- 示例项目：`demos/projects/47-multi-file-project-organization-and-cross-file-collaboration`

建议你这样读：

- 先把这一章当成“工程整理”而不是“新语法”
- 重点观察职责是怎么分开的，而不是盯着“文件数量变多了”
- 如果你之前总习惯把所有代码塞进 `main.swift`，这章最重要的是改掉那个默认手势

## 先澄清：多文件之间并不是在“互相通讯”

初学者常说：

- “A 文件怎么和 B 文件通讯？”

这个说法并不准确。

在同一个 Xcode target 里，多个 `.swift` 文件通常会一起编译进同一个 module。

在本章demo中真正发生协作的是：

- `StudyPlanService` 调用了 `StudyPlanRepository`
- `ConsoleRenderer` 读取了 `StudyPlan`
- `main.swift` 创建了仓储、服务和渲染器实例

也就是说：

- **文件只是代码组织单位**
- **真正协作的是类型和实例**

只要它们处在同一个 target、访问级别也允许，被定义在不同文件里并不会阻止它们协作。

## 为什么前面可以单文件，这里却不该再单文件

前面很多章节故意把全部代码放进一个文件，是因为教学重点还在：

- 语法
- 数据结构
- 控制流
- 最小可运行链路

那样做的好处是：

- 读者一眼就能看到完整执行路径
- 不需要先理解工程结构

但到了现在，代码已经开始出现这些稳定职责：

- 有些代码负责描述数据
- 有些代码负责读取和保存
- 有些代码负责处理业务动作
- 有些代码负责输出结果
- 有些代码只负责组装依赖和启动流程

如果这些职责继续全塞进一个文件，最常见的后果就是：

- `main.swift` 既在定义模型，又在写业务，又在直接打印
- 依赖边界越来越模糊
- 以后要替换实现时，很难知道应该改哪一段

所以从这一章开始，你需要建立一个概念：

- **不是因为“文件多了更专业”才拆文件**
- **而是因为职责已经稳定了，所以应该拆**

## 最小拆分原则：先按职责拆，不要按“看起来方便访问”拆

多文件组织最容易走偏的地方，是按“我现在写起来顺手”去拆，而不是按职责拆。

本章先固定四条最小原则：

### 1. 一个文件优先承载一组稳定职责

例如：

- `StudyTask.swift` 只放任务模型
- `StudyPlan.swift` 只放计划模型
- `StudyPlanRepository.swift` 只放仓储协议和仓储实现
- `StudyPlanService.swift` 只放业务动作
- `ConsoleRenderer.swift` 只放控制台输出

### 2. `main.swift` 只做入口和组装

`main.swift` 不应该继续承担：

- 领域模型定义
- 仓储细节
- 输出格式实现

它更适合承担：

- 创建依赖
- 调用主流程
- 打印少量演示阶段的分隔信息

### 3. 不要靠全局变量把所有文件串在一起

“多个文件能互相访问”不等于“所有东西都应该做成全局”。

如果你靠这种方式组织：

- 一个文件里放全局数组
- 另一个文件里直接去改
- 第三个文件里再顺手打印

那只是把单文件混乱拆成了多文件混乱。

### 4. 依赖通过构造注入流动

也就是：

- `main.swift` 创建仓储
- 把仓储传给 `StudyPlanService`
- 再把服务产生的数据交给 `ConsoleRenderer`

这样做的好处是：

- 依赖关系更清楚
- 替换实现更容易
- 你不会误以为“文件 A 直接拥有文件 B”

## 示例：把学习计划项目拆成多个文件

这一章的 demo 用的是“学习计划”场景，而不是待办列表。这样既能保持主题简单，也方便下一章继续承接 DTO 和持久化建模。

项目文件结构如下：

- `StudyTask.swift`
- `StudyPlan.swift`
- `StudyPlanRepository.swift`
- `StudyPlanService.swift`
- `ConsoleRenderer.swift`
- `main.swift`

你应该重点看这六个文件分别承担什么。

## 1. 领域模型：先把数据本体拆出去

### `StudyTask.swift`

```swift
struct StudyTask {
    let id: Int
    let title: String
    let estimatedHours: Int
    var isFinished: Bool
}
```

这个文件只回答一个问题：

- 一条学习任务长什么样

### `StudyPlan.swift`

```swift
struct StudyPlan {
    let title: String
    private(set) var tasks: [StudyTask]

    var unfinishedTaskCount: Int {
        tasks.filter { !$0.isFinished }.count
    }

    mutating func markTaskFinished(id: Int) -> Bool {
        guard let index = tasks.firstIndex(where: { $0.id == id }) else {
            return false
        }

        tasks[index].isFinished = true
        return true
    }
}
```

这里可以看到两个很关键的工程点：

- `StudyPlan` 和 `StudyTask` 已经不在 `main.swift` 里
- `tasks` 用了 `private(set)`，表示外部能读，但不能随手改写

这一点非常适合用来理解访问控制的第一层直觉：

- `private(set)`：外部可以读取，只有当前类型内部可以写

本章先不引入更复杂的访问控制组合，只要先建立这条经验就够了：

- **访问级别不是为了显得高级**
- **访问级别是在保护你的边界**

## 2. 仓储层：把“数据从哪里来”单独收口

`StudyPlanRepository.swift` 里，先定义协议，再给一个内存实现：

```swift
protocol StudyPlanRepository {
    func loadPlan() -> StudyPlan
    func savePlan(_ plan: StudyPlan)
}

struct InMemoryStudyPlanRepository: StudyPlanRepository {
    func loadPlan() -> StudyPlan { ... }
    func savePlan(_ plan: StudyPlan) { ... }
}
```

这一层在工程里解决的是：

- 学习计划从哪里读取
- 修改后要保存到哪里

当前 demo 只用了内存仓储，是因为这章重点不是持久化，而是文件职责和协作路径。

你可以把它理解成：

- 先把“数据入口”抽出来
- 这样服务层就不用关心底层到底是内存、文件还是数据库

## 3. 服务层：把业务动作从入口文件里拿走

`StudyPlanService.swift` 负责处理业务动作：

```swift
struct StudyPlanService {
    private let repository: StudyPlanRepository

    func loadPlan() -> StudyPlan {
        repository.loadPlan()
    }

    func finishTask(id: Int) -> StudyPlan? {
        var plan = repository.loadPlan()
        guard plan.markTaskFinished(id: id) else {
            return nil
        }

        repository.savePlan(plan)
        return plan
    }
}
```

这一层最重要的不是“语法新不新”，而是职责变化：

- `main.swift` 不再自己改任务完成状态
- 业务动作开始集中在服务层
- 仓储负责存取，服务负责流程

这就是本章最关键的一条拆分线：

- **仓储负责数据入口**
- **服务负责业务动作**

## 4. 输出层：把控制台打印也变成独立职责

如果输出逻辑还继续写在 `main.swift`，你很快会重新回到单文件混乱。

所以 demo 里专门拆了一个 `ConsoleRenderer.swift`：

```swift
struct ConsoleRenderer {
    func renderPlan(_ plan: StudyPlan, headline: String) -> String { ... }
    func renderSummary(for plan: StudyPlan) -> String { ... }
}
```

这样做的作用是：

- 输出格式集中管理
- 入口文件只负责调用，不负责拼字符串
- 以后如果你要换成别的输出形式，也不会把业务层一起改坏

## 5. `main.swift`：现在它真的只剩组装

当上面四层都拆完后，`main.swift` 就会变成这样：

```swift
let repository = InMemoryStudyPlanRepository(seedPlan: makeSeedPlan())
let service = StudyPlanService(repository: repository)
let renderer = ConsoleRenderer()

let initialPlan = service.loadPlan()
print(renderer.renderPlan(initialPlan, headline: "当前学习计划"))
```

这里的重点不是“代码变少了”，而是：

- 它只做依赖组装
- 它只触发流程
- 它不再定义模型或业务规则

也就是说，这一章想让你从 `main.swift` 身上去掉这些职责：

- 数据定义
- 数据存取
- 业务处理
- 输出格式

保留下来的只有：

- 组合
- 触发
- 演示

## 同一 target 内跨文件可见性的基本规则

现在回到最开始那个问题：

- 为什么这些类型分散到多个文件后，还能互相调用？

因为它们都处在同一个 target 内，而 Swift 的默认访问级别是：

- `internal`

也就是说，如果你没有显式写访问级别：

- 同一个 module / target 内通常都能访问到

当前阶段先记住这三个最常见层级：

### `internal`

- 默认访问级别
- 同一 target 内可见

### `private`

- 只在当前声明作用域内可见
- 比如某个属性只想让当前类型内部写，就很适合配合 `private(set)` 或 `private`

### `fileprivate`

- 只在当前文件内可见
- 比 `private` 稍宽，但仍然不会泄露到别的文件

本章先不展开所有访问级别细节，你只需要先建立下面这句判断：

- **类型定义在别的文件，不等于不能访问**

真正决定能不能访问的，是：

- 是否处在同一个 target
- 访问级别是否允许

## 为什么这章强调“依赖流动”，而不是“文件拥有文件”

看完 demo 后，你应该能更自然地描述依赖关系：

- `main.swift` 创建仓储
- 仓储被注入到服务里
- 服务产出计划数据
- 渲染器负责把计划格式化成控制台输出

这里没有任何一步是在说：

- “`StudyPlanService.swift` 文件调用了 `ConsoleRenderer.swift` 文件”

更准确的说法一定是：

- `StudyPlanService` 这个类型依赖 `StudyPlanRepository`
- `ConsoleRenderer` 这个类型消费 `StudyPlan`

这也是为什么工程化阶段要逐步把语言习惯改掉：

- 少说文件和文件通讯
- 多说类型边界、依赖方向和实例协作

## Demo 里你应该重点观察什么

这一章 demo 最值得观察的，不是“文件变多了”，而是下面这些信号：

1. `main.swift` 不再堆所有代码。
2. `StudyPlan` 和 `StudyTask` 被定义在别的文件里，但仍然能正常使用。
3. 仓储协议和仓储实现被收口到一起，服务层只依赖协议能力。
4. 输出层和业务层分开后，主流程变得更容易读。
5. `private(set)` 让读取和写入边界变得更清楚。

如果你读完这一章，能自己把一个上百行的单文件程序拆成“模型 + 仓储 + 服务 + 输出 + 入口”这几层，本章目标就达到了。

## 常见误区

- 按“为了能访问到”拆文件，而不是按职责拆
- `main.swift` 名义上变薄了，但业务逻辑其实还在入口里
- 看到跨文件访问报错，就误以为是“文件之间不能通讯”，而不是先检查访问级别和依赖方向

## 边界说明

为了保持主题集中，本章明确不做这些事：

- 不讲多 module / Swift Package 拆分

这些内容会在下一章继续推进，但前提就是：

- 你已经理解“一个项目应该被拆成多个文件，并按职责协作”这件事
