# 48. SwiftData 工程建模：DTO、持久化模型与领域边界

## 阅读导航

- 前置章节：[35. JSON 进阶：字段映射与复杂结构](./35-json-advanced-field-mapping-and-nested-structures.md)、[43. 本地快照缓存：Codable、文件落盘与恢复路径](./43-codable-persistence-and-local-cache.md)、[44. 从快照到记录：SwiftData 最小持久化闭环](./44-swiftdata-basics-model-container-context-and-crud.md)、[45. 结构化读取与关系一致性：筛选、排序、列表与删除规则](./45-swiftdata-advanced-query-sort-relationships-and-boundaries.md)、[47. 工程化第一步：多文件协作、类型边界与项目拆分](./47-multi-file-project-organization-and-cross-file-collaboration.md)
- 上一章：[47. 工程化第一步：多文件协作、类型边界与项目拆分](./47-multi-file-project-organization-and-cross-file-collaboration.md)
- 建议下一章：待定
- 下一章：待定
- 适合谁先读：已经理解 SwiftData 的最小 CRUD，也已经开始把项目拆成多个文件；现在想知道真实工程里 DTO、SwiftData 模型和业务模型为什么不该混成一个类型的读者

## 本章目标

学完这一章后，你应该能够：

- 说清为什么 `DTO` 不应该直接拿来当 SwiftData 模型
- 说清为什么 `@Model` 也不适合直接充当全工程通用业务模型
- 把工程里的三层模型分清楚：
  - 远程 DTO
  - SwiftData 持久化模型
  - 领域模型
- 理解 `DTO -> Record -> Domain` 这条映射链分别服务于哪一层问题
- 用一个控制台 demo 跑通“解码 JSON -> 保存 SwiftData -> 重建容器 -> 读回领域模型”的完整链路

## 本章对应资源

- 文稿：`docs/zh-CN/chapters/48-swiftdata-engineering-modeling-dto-persistence-and-domain-boundaries.md`
- 示例项目：`demos/projects/48-swiftdata-engineering-modeling-dto-persistence-and-domain-boundaries`

建议你这样读：

- 先把这一章当成“工程边界”而不是“SwiftData 新语法”
- 重点观察每一层类型到底在服从谁
- 如果你曾经习惯“一个结构体从接口解码、拿来渲染、顺便还拿去持久化”，这一章正是在拆开那个习惯

## 这一章不是重复第 44、45 章

第 44 章解决的是：

- 如何跑通最小 SwiftData 持久化闭环

第 45 章解决的是：

- 如何做查询、排序、关系和删除规则

这一章要解决的不是这些，而是另一个更工程化的问题：

- **真实项目里，SwiftData 模型到底应该怎么和远程 DTO、业务模型分层**

也就是说，本章不再问：

- `insert / fetch / save` 怎么写

而是问：

- 哪些类型该服从接口
- 哪些类型该服从本地存储
- 哪些类型该服从业务表达

## 场景升级：远程 JSON、落本地、再读回业务对象

从这一章开始，场景变成这样：

1. 远程返回一份学习计划 JSON
2. 应用先把它解成 `StudyPlanDTO`
3. 再映射成 SwiftData 可持久化的 `StudyPlanRecord / StudyTaskRecord`
4. 落盘后重建 `ModelContainer`
5. 再把持久化记录映射成领域模型 `StudyPlan / StudyTask`

这条链路听起来比第 44 章长，但它在真实工程里更常见。

原因很简单：

- 远程接口关心的是传输结构
- SwiftData 关心的是本地记录和关系
- 业务层关心的是当前应用要怎么表达数据

这三件事经常长得相似，但不应该被误认为是同一件事。

## 先立一条总则：不要让一个类型承担三种职责

如果你把一个类型同时拿来做：

- JSON 解码
- SwiftData 持久化
- 业务表达

短期看起来会少写几个类型，长期通常会带来三类问题：

- 字段命名越来越别扭，因为既想贴 JSON，又想贴业务表达
- 本地持久化专用字段会污染业务层
- 远程结构一改，整条本地和业务链路都跟着震动

所以这一章的总原则可以压成一句话：

- **不要让一个类型同时服从接口、数据库和业务**

## 第一层：远程 DTO 只服从接口 JSON

demo 里的 DTO 文件长这样：

```swift
struct StudyPlanDTO: Decodable {
    let planID: Int
    let planTitle: String
    let owner: OwnerDTO
    let publishedAt: Date
    let tasks: [StudyTaskDTO]
}

struct StudyTaskDTO: Decodable {
    let taskID: Int
    let taskTitle: String
    let estimatedMinutes: Int
    let isFinished: Bool
}
```

这一层最重要的判断是：

- DTO 首先服从接口返回，不首先服从你的业务措辞

所以你会看到它的典型特征：

- 字段名可能和业务命名不一样
- 结构可能嵌套得更贴近 JSON
- 目标是“稳定解码”，不是“全工程通用”

这正是第 35 章已经建立过的思路继续往前走：

- 先把 JSON 解成贴近原始结构的类型

当前 demo 里，`CodingKeys` 就在做这件事：

```swift
enum CodingKeys: String, CodingKey {
    case planID = "plan_id"
    case planTitle = "plan_title"
    case publishedAt = "published_at"
}
```

这说明 DTO 的第一职责仍然是：

- 把远程字段可靠地接进来

## 第二层：SwiftData Record 只服从本地存储与关系维护

持久化层文件长这样：

```swift
@Model
final class StudyPlanRecord {
    var remoteID: Int
    var title: String
    var ownerName: String
    var publishedAt: Date
    var syncedAt: Date

    @Relationship(deleteRule: .cascade, inverse: \StudyTaskRecord.plan)
    var tasks: [StudyTaskRecord] = []
}
```

这里最重要的不是 `@Model` 语法本身，而是字段为什么会长成这样。

你会发现它和 DTO 已经不完全一样了：

- `planID` 变成了 `remoteID`
- 嵌套的 `owner.display_name` 被摊平成 `ownerName`
- 多了一个本地字段 `syncedAt`
- 子任务关系不再只是数组，而是带有 SwiftData 关系语义

这说明 SwiftData Record 的第一职责已经变成：

- 让本地记录稳定保存
- 让关系和生命周期被持久化层理解

所以本章一定要明确一个判断：

- **不要把 DTO 直接拿来当 SwiftData 模型**

因为 DTO 关注的是：

- 接口怎么传

而 Record 关注的是：

- 本地怎么存
- 关系怎么维护
- 哪些字段属于本地系统自己需要

## 第三层：领域模型只服从业务表达

领域层文件更朴素：

```swift
struct StudyPlan {
    let title: String
    let ownerName: String
    let publishedAt: Date
    let tasks: [StudyTask]

    var unfinishedTaskCount: Int {
        tasks.filter { !$0.isFinished }.count
    }
}
```

这里故意没有：

- `@Model`
- `remoteID`
- `syncedAt`
- 持久化关系配置

因为领域模型真正要回答的问题是：

- 当前业务代码最自然、最清楚的数据表达是什么

也就是说：

- DTO 不该带着你所有业务便利字段
- Record 不该带着你所有持久化细节到处跑
- Domain 也不该被数据库和接口细节污染

所以本章第二个必须建立的判断是：

- **不要把 `@Model` 直接当成全工程通用业务模型**

## `DTO -> Record` 映射：导入/同步时到底做什么

当前 demo 把这一步集中在 `StudyPlanMapper` 里：

```swift
static func makeRecord(from dto: StudyPlanDTO, syncedAt: Date = .now) -> StudyPlanRecord {
    let record = StudyPlanRecord(
        remoteID: dto.planID,
        title: dto.planTitle,
        ownerName: dto.owner.displayName,
        publishedAt: dto.publishedAt,
        syncedAt: syncedAt
    )

    record.tasks = dto.tasks.enumerated().map { index, taskDTO in
        StudyTaskRecord(
            remoteID: taskDTO.taskID,
            title: taskDTO.taskTitle,
            estimatedMinutes: taskDTO.estimatedMinutes,
            isFinished: taskDTO.isFinished,
            sortOrder: index,
            plan: record
        )
    }

    return record
}
```

这一步做的事情：

- 远程字段改名
- 嵌套结构摊平
- 本地补充 `syncedAt`
- 把 DTO 数组变成带关系的 SwiftData 子记录
- 生成本地排序字段 `sortOrder`

也就是说，`DTO -> Record` 映射真正负责的是：

- **把“远程世界的外形”翻译成“本地存储世界的外形”**

## `Record -> Domain` 映射：业务读取时到底做什么

即使数据已经成功保存了，业务层显然也不会想直接拿 `StudyPlanRecord` 来用。

所以 demo 又定义了：

```swift
static func makeDomainPlan(from record: StudyPlanRecord) -> StudyPlan {
    let tasks = record.tasks
        .sorted(by: { $0.sortOrder < $1.sortOrder })
        .map(makeDomainTask(from:))

    return StudyPlan(
        title: record.title,
        ownerName: record.ownerName,
        publishedAt: record.publishedAt,
        tasks: tasks
    )
}
```

这一步做的事情是：

- 按本地排序字段恢复稳定顺序
- 去掉持久化细节
- 输出成业务层真正想消费的模型

所以 `Record -> Domain` 映射解决的是：

- **把“数据库里可保存的结构”翻译成“业务里可直接使用的结构”**

## 为什么一对多关系在 DTO 和 SwiftData 里看起来像，但职责不同

你可能会看到：

- DTO 里也有 `tasks: [StudyTaskDTO]`
- Record 里也有 `tasks: [StudyTaskRecord]`

外形确实很像，但职责并不一样。

DTO 里的数组更像是在表达：

- JSON 里有一组子对象

SwiftData Record 里的数组则是在表达：

- 本地持久化层里存在真正的关系
- 删除、保存、读取都会受这层关系影响

所以别被“都是数组”迷惑。它们共同长得像数组，只是因为：

- 一个接口返回了一组子项
- 一个父记录管理了一组子记录

但工程语义已经不同了。

## 文件拆分建议：让每一层都有自己的位置

当前 demo 采用的是下面这组目录：

- `Remote/DTOs`
- `Persistence/Models`
- `Domain/Models`
- `Mappers`
- `Repositories`
- `Support`

当前项目里对应为：

- `Remote/StudyPlanDTO.swift`
- `Persistence/StudyPlanRecord.swift`
- `Persistence/StudyTaskRecord.swift`
- `Domain/StudyPlan.swift`
- `Domain/StudyTask.swift`
- `Mappers/StudyPlanMapper.swift`
- `Repositories/StudyPlanStore.swift`
- `Support/DemoPaths.swift`
- `main.swift`

这种拆法最适合表达一件事：

- 同样都叫“模型”，也可能属于完全不同的工程层

## `StudyPlanStore`：让映射和持久化入口继续收口

为了避免 `main.swift` 到处手写：

- fetch
- delete
- insert
- map

demo 里继续加了一层很薄的 store：

```swift
struct StudyPlanStore {
    let context: ModelContext

    func replaceStoredPlan(with dto: StudyPlanDTO) throws { ... }
    func fetchStoredPlans() throws -> [StudyPlanRecord] { ... }
    func fetchDomainPlans() throws -> [StudyPlan] { ... }
}
```

这层的意义不是“SwiftData 强制你这样写”，而是：

- 让持久化入口更稳定
- 让 `main.swift` 不去关心映射和查询细节
- 让“把 DTO 同步到本地”和“把本地读成领域模型”这两条主线更清晰

## 哪些小项目可以先只保留两层

虽然这一章讲的是三层模型，但并不是说任何小项目都必须立刻上三层。

如果你的项目满足下面这些条件：

- 远程结构很简单
- 本地存储很轻
- 业务表达也几乎一样

那你可以暂时只保留两层，例如：

- `DTO + Record`
- 或 `Record + Domain`

但你应该先有这个判断能力，再做精简，而不是默认把所有职责塞进一个类型。

换句话说：

- **两层可以是经过判断后的简化**
- **一层包打天下通常只是边界还没想清楚**

## Demo 里你应该重点观察什么

第 48 章 demo 最值得观察的是下面四件事：

1. JSON 先被解码成 DTO，而不是直接解成 `@Model`。
2. DTO 到 Record 的映射集中在 `StudyPlanMapper`，而不是散落在 `main.swift`。
3. 重建 `ModelContainer` 后还能读回 Record，说明这不是内存假象。
4. 最终业务输出读的是 `StudyPlan`，而不是把 `StudyPlanRecord` 直接拿去全流程乱用。

如果你能回答下面这三个问题，这章就读通了：

- 这个字段属于接口、属于本地，还是属于业务推导？
- 这个转换应该发生在导入时，还是读取时？
- 这段逻辑为什么不该直接写进 `main.swift`？

## 边界说明

为了保持主题集中，本章明确不做这些事：

- 不展开更多 SwiftData 查询语法
- 不讲网络层真实接入
- 不讲迁移、CloudKit 或同步冲突
- 不讲 UI 绑定和界面层注入

本章要建立的核心能力只有一个：

- 当你在工程里同时面对远程 JSON、本地持久化和业务表达时，知道应该把它们拆成不同层，并用映射把边界连起来
