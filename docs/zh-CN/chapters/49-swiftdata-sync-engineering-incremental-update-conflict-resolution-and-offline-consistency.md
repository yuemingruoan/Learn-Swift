# 49. SwiftData 同步工程：增量更新、冲突处理与离线一致性

## 阅读导航

- 前置章节：[39. 网络层分层与错误建模](./39-network-layer-architecture-and-error-modeling.md)、[43. 本地快照缓存：Codable、文件落盘与恢复路径](./43-codable-persistence-and-local-cache.md)、[46. 语言进阶：协议抽象、依赖注入与可测试设计](./46-protocol-abstraction-dependency-injection-and-testability.md)、[48. SwiftData 工程建模：DTO、持久化模型与领域边界](./48-swiftdata-engineering-modeling-dto-persistence-and-domain-boundaries.md)
- 上一章：[48. SwiftData 工程建模：DTO、持久化模型与领域边界](./48-swiftdata-engineering-modeling-dto-persistence-and-domain-boundaries.md)
- 建议下一章：待定
- 下一章：待定
- 适合谁先读：已经能把远程 DTO 保存成 SwiftData 记录，也已经开始思考“离线修改、本地备注、重复同步、远程删除”这些真实工程问题的读者

## 本章目标

学完这一章后，你应该能够：

- 理解为什么第 48 章的 `replaceStoredPlan(with:)` 只适合演示，不适合真实同步
- 写出一份记录列出字段归属表，区分服务端权威字段、共享可编辑字段、本地专属字段
- 为`SwiftData`持久化模型补上同步元数据，并知道每个字段到底在解决什么工程痛点
- 用`远程快照 -> 本地 upsert -> 本地离线修改 -> 待上传队列 -> push/pull -> merge -> 领域读取`这条链路理解同步系统
- 实现一个最小可维护的待上传队列，而不是每次同步时临时遍历全部脏数据拼请求
- 用一张固定的冲突矩阵处理共享字段冲突、删除冲突，而不是把规则散落在不同文件里
- 理解同步系统的核心不是“多写几个网络请求”，而是“为状态变化建立稳定解释”

## 本章对应资源

- 文稿：`docs/zh-CN/chapters/49-swiftdata-sync-engineering-incremental-update-conflict-resolution-and-offline-consistency.md`
- 示例项目：`demos/projects/49-swiftdata-sync-engineering-incremental-update-conflict-resolution-and-offline-consistency`

## 这一章要解决什么开发问题

第 48 章已经把地基建立起来了：

- 远程 DTO 服从接口
- SwiftData Record 服从本地存储
- Domain 服从业务表达

但真实项目很快会出现新的问题：

- 用户离线时先勾选了一条任务完成
- 用户给任务补了一段仅本地使用的备注
- 应用重启后还要记得哪些修改没上传
- 远程下一轮快照回来时，标题顺序变了，某条任务被删除了
- 这时你既不能把本地变化全丢掉，也不能盲目让“本地赢一切”

这说明问题已经从“怎么保存”升级成了“怎么同步”。

所以本章不再问：

- `@Model` 怎么写
- `insert / fetch / save` 怎么写

而是改问：

- 哪些字段该让远程覆盖
- 哪些字段必须本地保留
- 哪些字段一旦本地和远程都改了，就必须走冲突判定
- 哪些意图应该落成待上传队列
- 哪些删除不能静默吞掉

## 先把结论说清：第 48 章的“先删再插”为什么不够

第 48 章里有这样一条教学级保存路径：

1. 拉到一份远程 DTO
2. 删除本地已有记录
3. 重新创建全部 `StudyPlanRecord / StudyTaskRecord`

这条路径非常适合演示下面这些概念：

- `DTO -> Record -> Domain`
- SwiftData 容器重建后仍然能读回记录
- 远程字段、本地字段、业务字段为什么不该混成一个类型

但它并不适合继续承担真实同步，原因很直接：

- 本地专属字段会丢
  - 例如你给任务写的本地备注 `localNote`
- 已有对象身份会丢
  - 同一个 `remoteID` 对应的记录被删了又新建，同步状态和历史信息也跟着断掉
- 你无法知道本轮到底是：
  - 新增了哪些记录
  - 更新了哪些记录
  - 删除了哪些记录
- 本地离线修改会被整包覆盖
  - 这是最典型也最危险的工程问题

把这个问题压成一句话：

- 第 48 章解决的是“存下来”
- 第 49 章解决的是“存下来以后，如何同步之后的变化”

## 两个对比场景：什么时候整包覆盖还能接受，什么时候绝对不行

### 场景 A：只读展示

如果你的应用只是：

- 拉一份远程学习计划
- 保存成 SwiftData
- 作为离线只读展示

那整包覆盖往往还能接受，因为：

- 本地没有用户编辑
- 记录没有待上传意图
- 本地只是远程快照副本

### 场景 B：离线可编辑

如果你的应用已经允许用户：

- 离线勾选完成状态
- 写本地备注
- 重启后继续保留这些状态

那整包覆盖就会出事。

因为当下一轮远程快照被拉取下来时，客户端不再面对一份“可随意覆盖的副本”，而是在面对：

- 远程已有变化
- 本地也有变化
- 某些字段该让远程赢
- 某些字段该保留本地
- 某些字段必须进入冲突判定

从这一刻开始，你需要的已经不是“重新 decode 一次 JSON”，而是一套同步规则。

## 本章主线结构图

本章 demo 和正文都围绕下面这条最小同步链路展开：

```text
StudyPlanRemoteSource
-> 拉取远程快照 / 推送本地 mutation

StudyPlanSyncService
-> 编排 push / pull / merge / 队列清理

PendingTaskMutationRecord
-> 记录“本地当时想上传什么”

StudyPlanStore
-> 管理 SwiftData 记录、队列、领域读取

StudyPlanMerger
-> 把远程快照按字段归属合并到已有本地记录

Domain Read Model
-> 给业务代码提供当前可消费状态
```

这里先强调三个概念：

- 同步不是网络层问题，而是数据边界问题
- 同步不是一次函数调用，而是会不断重复发生的生命周期问题
- 同步系统最重要的问题不是“怎么发请求”，而是“谁拥有哪类字段的最终解释权”

## 本章非目标

本章不会展开：

- SwiftUI 或 UIKit 层的同步提示 UI
- 后台推送驱动同步
- 多人实时协作
- CloudKit
- CRDT
- 通用同步框架 DSL

我们只做一个足够真实、但仍可教学掌控的最小闭环。

## 模块 1：先画边界，不要一上来就写同步逻辑

真实项目里，同步代码最容易失控的原因，不是 API 多，而是没有先回答一个看似朴素的问题：

- 这条记录里的每个字段，到底归谁负责？

如果这个问题没答清，后面所有 merge 都会变成：

- 这里先 `if localChanged`
- 那里再 `if remoteUpdated`
- 最后加一个“实在不行就覆盖掉”

这种代码短期能跑，长期完全不可维护。

### 字段归属表：先分三类

本章固定把 `StudyTask` 里的字段分成三类：

| 字段 | 归属 | 默认策略 | 典型原因 |
| --- | --- | --- | --- |
| `title` | 服务端权威字段 | 远程赢 | 标题来自后端内容管理或教学计划发布 |
| `estimatedMinutes` | 服务端权威字段 | 远程赢 | 这是课程设计的一部分，不应由本地随手改写 |
| `sortOrder` | 服务端权威字段 | 远程赢 | 排序体现远程计划顺序 |
| `isFinished` | 共享可编辑字段 | 需要冲突判定 | 本地可改，远程也可能改 |
| `localNote` | 本地专属字段 | 本地保留 | 只服务当前设备的阅读和学习记录 |
| `isTombstoned` | 同步层字段 | 由同步层驱动 | 这是删除语义，不属于业务数据本体 |

在开始编码前，先记住一件事：

- 没有字段归属表，就不要开始写同步代码

### 为什么不能用标题或下标判断“是不是同一条记录”

同步系统的第一前提是稳定身份。

在本章里，这个身份就是：

- `remoteID`

不能用的东西包括：

- 标题
  - 标题会改名
- 数组下标
  - 远程会重排
- 当前列表顺序
  - 排序本身就是可能变化的字段

只要你不用稳定身份来匹配，本地 `update` 和远程 `update` 就没有可靠参照点，后面也不可能谈什么 upsert 和冲突判定。

## 模块 2：同步元数据不是“额外负担”，它们是状态解释的基础

这一节**不要背字段名单！！！**。同步元数据真正有价值的地方，不在于“多了几个成员”，而在于它们被明确归进了模型当中。

在实际开发中，一个设计“优美”的模型能为后续开发节省大量精力

```swift
@Model
final class StudyPlanRecord {
    var remoteID: Int
    var remoteVersion: Int
    var title: String
    var ownerName: String
    var publishedAt: Date
    var lastSyncedAt: Date

    @Relationship(deleteRule: .cascade, inverse: \StudyTaskRecord.plan)
    var tasks: [StudyTaskRecord] = []
}

@Model
final class StudyTaskRecord {
    var remoteID: Int
    var title: String
    var estimatedMinutes: Int
    var isFinished: Bool
    var sortOrder: Int
    var lastRemoteUpdatedAt: Date
    var lastLocalModifiedAt: Date?
    var syncStateRaw: String
    var localNote: String
    var isTombstoned: Bool
    var conflictKindRaw: String?
    var plan: StudyPlanRecord?
}

@Model
final class PendingTaskMutationRecord {
    var mutationID: String
    var taskRemoteID: Int
    var kindRaw: String
    var payloadJSON: String
    var createdAt: Date
    var retryCount: Int
    var lastAttemptAt: Date?
    var statusRaw: String
}
```

把这三段放在一起看：

- `StudyPlanRecord` 保存计划级快照信息，尤其是 `remoteVersion` 和 `lastSyncedAt`
- `StudyTaskRecord` 保存任务本体和任务级同步状态，字段归属、dirty、conflict、tombstone 都在这里落地
- `PendingTaskMutationRecord` 不保存“当前状态”，而是保存“当时准备上传的意图”

如果你对 Git 更熟，这里可以先借一个不完全等价、但很好用的类比来建立直觉：

- `remoteVersion`
  - 有点像“你上次看到的远程分支版本”
  - 它不一定是 commit SHA，但作用很像“我当前对远程计划看到的是哪一版”
- `lastSyncedAt`
  - 像“上次 fetch / pull 成功的时间”
  - 它不直接决定内容冲突，却能告诉你这份本地快照多久没和远程重新对账了
- `lastRemoteUpdatedAt`
  - 像“这条记录在上游最近一次被改动的时间”
  - 共享字段冲突时，你本质上就是在比较上游最新改动和本地修改谁更新
- `lastLocalModifiedAt`
  - 像“你工作区里这条内容最后一次本地改动的时间”
  - 没有它，你就很难判断当前保留本地值到底有没有依据
- `syncStateRaw`
  - 像一个极简版的 `git status`
  - 它告诉你这条记录现在是 `synced`、`dirty`、`conflict` 还是 `tombstoned`
- `PendingTaskMutationRecord`
  - 有点像“你本地已经形成、但还没 push 的提交意图”
  - 它不是简单看当前工作区长什么样，而是把当时那次准备上传的操作单独保存下来
- `mutationID`
  - 可以把它理解成这次待上传变更的稳定 ID
  - 类似 Git 里每个提交都有自己的身份，这样重试时才不会把同一条变更重复应用

但这个类比到这里就该停下，不要继续硬套。因为本章同步系统和 Git 仍然有三个关键差异：

- Git 管的是提交历史和文件快照，本章管的是业务记录和字段归属
- Git 不会替你决定“对象里的哪个字段该远程赢、哪个字段该本地保留”
- `PendingTaskMutationRecord` 更像待上传操作日志，而不是完整提交图

这些字段不是为了“让模型更高级”，它们都各有各的用处。

### 没有 `lastRemoteUpdatedAt`，你就不知道远程是不是更新过

假设远程任务标题没变，但完成状态变了。

如果你没有记录：

- 远程上一次更新时间

那你很难回答：

- 当前远程值到底比本地数据更新，还是更旧

### 没有 `lastLocalModifiedAt`，你就不知道本地快照是不是更晚

共享字段冲突最常见的最小规则之一是：

- 如果本地待上传修改时间比远程更新时间晚，则暂时保留本地值并继续等待上传

没有这个时间点，就没有这条规则。

### 没有 `syncStateRaw`，应用重启后你不知道哪些记录被修改了

很多临时 demo 会在内存里记一个：

- `dirtyTaskIDs`

这在应用运行时看起来没问题，但一旦重启，状态就消失了。

真实工程里，修改状态和冲突状态都必须可恢复。

### 没有 `isTombstoned`，删除会变成“到底是没了，还是还没处理完”

远程删除一条记录，不一定意味着你应该立刻物理删除本地对象。

因为你还可能遇到：

- 本地仍有待上传修改
- 需要向用户展示“远程已删除，但本地还有冲突”
- 需要在日志或调试输出里保留删除诊断信息

这就是 `tombstone` 存在的原因。

上面看的是字段声明，下面再看 `StudyTaskRecord` 的计算属性。这里开始出现“这些元数据如何被解释”的代码：

```swift
extension StudyTaskRecord {
    var syncState: SyncState {
        get { SyncState(rawValue: syncStateRaw) ?? .synced }
        set { syncStateRaw = newValue.rawValue }
    }

    var conflictKind: SyncConflictKind? {
        get { conflictKindRaw.flatMap(SyncConflictKind.init(rawValue:)) }
        set { conflictKindRaw = newValue?.rawValue }
    }

    var visibleInDomain: Bool {
        !isTombstoned || syncState == .conflict
    }
}
```

看这段代码时，建议重点关注这三点：

- 业务字段和同步字段被放在同一个 `Record` 里，但没有把这些元数据塞进 `Domain`
- `syncStateRaw`、`conflictKindRaw` 用原始值持久化，是为了让应用重启后还能恢复状态
- `visibleInDomain` 说明 tombstone 不是简单“隐藏一切”，冲突态记录仍然可以继续暴露给业务层

## 模块 3：Domain 不是同步大杂烩

虽然持久化层会加很多同步元数据，但 Domain 显然不应该直接暴露所有内部字段。

业务层通常真正关心的是：

- 当前标题
- 当前是否完成
- 当前本地备注
- 当前是否有同步冲突提醒

与此相对的，业务层通常不关心：

- `retryCount`
- `payloadJSON`
- 队列里第几个 mutation 还没推

所以这一章的 Domain 保持克制：

- 暴露当前可消费状态
- 允许带一点“当前有冲突提示”的结果
- 但不把队列内部实现细节扩散到所有业务代码

这和第 48 章的边界思想是一致的：

- 同步元数据属于持久化和同步层
- 不是领域模型的中心

demo 里的 `StudyPlanStore.makeDomainPlan()` 就在做这层裁剪，它只把业务真正需要读到的结果映射出去：

```swift
func makeDomainPlan() throws -> StudyPlan? {
    guard let plan = try fetchPlanRecord() else {
        return nil
    }

    let tasks = try fetchTaskRecords()
        .filter { $0.visibleInDomain }
        .map { record in
            StudyTask(
                remoteID: record.remoteID,
                title: record.title,
                estimatedMinutes: record.estimatedMinutes,
                isFinished: record.isFinished,
                localNote: record.localNote,
                syncState: record.syncState,
                conflictHint: record.conflictKind.map { StudyPlanStore.conflictMessage(for: $0) }
            )
        }

    return StudyPlan(
        remoteID: plan.remoteID,
        title: plan.title,
        ownerName: plan.ownerName,
        publishedAt: plan.publishedAt,
        tasks: tasks
    )
}
```

这里最值得注意的是：

- 队列字段没有穿透到 `Domain`
- 领域层只感知“当前状态”和“是否需要冲突提示”
- `visibleInDomain` 把 tombstone 和 conflict 的展示边界收口在 store，而不是散落到业务代码里

## 模块 4：从“整包替换”升级为“增量 upsert”

这是我们在这一章中第一次真正进入同步主线。

### `upsert` 真正解决的是什么

`upsert` 不是什么“框架术语崇拜”，它解决的是一个非常朴素的问题：

- 当远程这条记录回来时，本地到底应该创建新对象，还是更新已有对象？

答案取决于：

- 本地是否已经有同一个 `remoteID` 的记录

所以本章的 pull merge 固定按下面步骤走：

1. 读取本地已有任务记录，建立 `remoteID -> Record` 索引
2. 遍历远程快照，按 `remoteID` 判断是 `create` 还是 `update`
3. 只更新服务端权威字段与可安全覆盖字段
4. 记录本轮看见过哪些 `remoteID`
5. 对本地存在但远程缺失的记录，按删除策略处理
6. 最后一次性 `save()`

直接看 demo 中 `StudyPlanMerger.merge(...)` 的主循环，`upsert` 的工程含义会比文字更清楚：

```swift
let existingTasks = Dictionary(
    uniqueKeysWithValues: try store.fetchTaskRecords().map { ($0.remoteID, $0) }
)
let activeMutations = try store.fetchActivePendingMutationRecords()
let activeMutationRecordsByTaskID = Dictionary(grouping: activeMutations, by: \.taskRemoteID)

for remoteTask in snapshot.tasks {
    seenRemoteIDs.insert(remoteTask.remoteID)

    if let localTask = existingTasks[remoteTask.remoteID] {
        var changed = false
        let hasPendingSharedMutation =
            activeMutationRecordsByTaskID[remoteTask.remoteID]?.contains(where: { $0.kind == .setFinished }) ?? false

        if localTask.title != remoteTask.title {
            localTask.title = remoteTask.title
            changed = true
        }
        if localTask.estimatedMinutes != remoteTask.estimatedMinutes {
            localTask.estimatedMinutes = remoteTask.estimatedMinutes
            changed = true
        }
        if localTask.sortOrder != remoteTask.sortOrder {
            localTask.sortOrder = remoteTask.sortOrder
            changed = true
        }
        if localTask.lastRemoteUpdatedAt != remoteTask.updatedAt {
            localTask.lastRemoteUpdatedAt = remoteTask.updatedAt
            changed = true
        }

        if hasPendingSharedMutation,
           let localModifiedAt = localTask.lastLocalModifiedAt,
           localModifiedAt > remoteTask.updatedAt {
            if localTask.syncState != .dirty {
                localTask.syncState = .dirty
                changed = true
            }
        } else {
            if localTask.isFinished != remoteTask.isFinished {
                localTask.isFinished = remoteTask.isFinished
                changed = true
            }
            if localTask.syncState != .conflict && localTask.syncState != .synced {
                localTask.syncState = .synced
                changed = true
            }
            if localTask.conflictKind != nil {
                localTask.conflictKind = nil
                changed = true
            }
        }
    } else {
        let newTask = StudyTaskRecord(
            remoteID: remoteTask.remoteID,
            title: remoteTask.title,
            estimatedMinutes: remoteTask.estimatedMinutes,
            isFinished: remoteTask.isFinished,
            sortOrder: remoteTask.sortOrder,
            lastRemoteUpdatedAt: remoteTask.updatedAt,
            syncState: .synced,
            localNote: "",
            isTombstoned: false,
            plan: plan
        )
        store.context.insert(newTask)
        createdCount += 1
    }
}
```

这段代码对应前面的规则表，基本是一一落地的：

- `remoteID` 是唯一匹配依据，先建索引再决定 create / update
- 远程权威字段 `title`、`estimatedMinutes`、`sortOrder`、`lastRemoteUpdatedAt` 可以直接覆盖
- `localNote` 没有出现在更新分支里，表示它不会在 pull 时被远程快照抹掉
- 共享字段 `isFinished` 不再直接覆盖，而是先看是否存在待上传共享 mutation，再看本地修改时间和远程更新时间的先后
- “映射”和“合并”已经分离，`Merger` 开始负责状态演进，而不是只做 DTO 形状翻译

### 为什么顺序变化也属于“更新”

很多人第一次写 merge 时只盯着标题和状态，却忘了顺序。

如果你忽略 `sortOrder`：

- 远程计划重排以后
- 本地读回 Domain 时任务顺序就会漂
- 你可能误以为是 SwiftData 读出来的顺序不稳定，但实际上是自己没把顺序当成数据同步的一部分

所以本章里 `sortOrder` 被放进服务端字段，而不是“无关紧要的 UI 细节”。

### 为什么 merge 过程中不要边遍历边保存

如果你把 merge 写成：

- 更新一条就 `save()`
- 删除一条再 `save()`

最容易出现的问题是：

- 半轮同步失败后，本地处于“一半旧、一半新”的过程态
- 调试时看不出这轮到底完成了哪些动作
- 很难对一轮同步生成可解释的统计结果

所以本章默认做法是：

- 先完整 merge
- 再一次性 `save()`

这不是形式主义，而是为了让同步具备最基本的原子性。

## 模块 5：删除不是一句 `delete`就结束了，而是要先决定语义

远程缺失一条本地记录时，最常见的偷懒写法是：

```swift
context.delete(task)
```

它看起来很直接，但真实同步里立刻会碰到两个问题：

- 本地还有没有待上传意图？
- 这条删除现在能不能被用户或调试信息解释清楚？

### 本章默认删除策略

本章固定采用下面这套教学默认值：

- 远程缺失，本地没有待上传共享字段修改
  - 标记为 `tombstone`
- 远程缺失，但本地仍有待上传共享字段修改
  - 标记为 `conflict`
  - 同时保留 `isTombstoned = true`
- 最终清理阶段
  - 只清掉已经确认同步完成、且没有冲突的 tombstone

这里要注意：

- `tombstone` 不是“永远不删”
- `tombstone` 是“先把删除变成可解释状态，再决定何时物理清理”

demo 里处理“远程缺失但本地还留着记录”的逻辑也被单独提了出来：

```swift
for (remoteID, localTask) in existingTasks where !seenRemoteIDs.contains(remoteID) {
    let hasPendingSharedMutation =
        activeMutationRecordsByTaskID[remoteID]?.contains(where: { $0.kind == .setFinished }) ?? false

    if hasPendingSharedMutation {
        if localTask.syncState != .conflict
            || localTask.conflictKind != .deletedRemotelyWithPendingMutation
            || !localTask.isTombstoned {
            localTask.syncState = .conflict
            localTask.conflictKind = .deletedRemotelyWithPendingMutation
            localTask.isTombstoned = true
            conflictCount += 1
            conflicts.append(
                SyncConflict(
                    taskRemoteID: remoteID,
                    kind: .deletedRemotelyWithPendingMutation,
                    message: "任务 #\(remoteID) 在远程已被删除，但本地仍有待上传完成状态。"
                )
            )
        } else {
            skippedCount += 1
        }
    } else {
        if !localTask.isTombstoned || localTask.syncState != .tombstoned {
            localTask.isTombstoned = true
            localTask.syncState = .tombstoned
            localTask.conflictKind = nil
            deletedCount += 1
        } else {
            skippedCount += 1
        }
    }
}
```

这段代码中有三个重点：

- 删除被拆成了“普通 tombstone”和“删除冲突”两条路径
- 冲突不会只留在日志里，而是被持久化成 `syncState` 和 `conflictKind`
- `SyncConflict` 被顺手写进结果集，后面的 `SyncReport` 才能把这轮删除解释清楚

这些都是实际工程中常用的技巧

### 为什么删除冲突不能静默吞掉

最典型的删除冲突是：

- 本地用户离线勾选任务完成
- 这条 mutation 还没成功上传
- 下一轮远程快照却告诉你：这条任务已经不存在了

如果你此时静默删除本地记录，结果就是：

- 用户会觉得“我明明刚改过，为什么突然没了”
- 你自己也很难定位，这到底是正常删除，还是本地意图被覆盖了

所以本章固定把它建模为：

- `syncState = conflict`
- `conflictKind = deletedRemotelyWithPendingMutation`

## 模块 6：本地修改不是立刻上传，本地先稳定落地

这一模块处理离线优先最核心的一步：

- 本地操作先成功
- 上传是后续同步阶段的事

### 为什么不应该同步时临时遍历所有 dirty 记录拼请求

很多 demo 会写成：

- 同步开始时查出所有 `syncState == dirty` 的记录
- 根据当前字段值临时构造请求

这种做法的最大问题是：

- 你丢失了“当时到底想上传什么”的意图

例如：

1. 用户第一次把任务改成完成
2. 还没上传成功
3. 用户又改回未完成
4. 同步时你只看当前字段值，已经无法知道中间到底发生过什么

这就是为什么本章引入：

- `PendingTaskMutationRecord`

### 队列记录的真实价值

显式队列不是为了让代码“更像同步系统”，重点是它确实解决了几个核心问题：

- 应用崩溃后仍能恢复待上传意图
- 可以知道上传顺序
- 可以记录重试次数
- 可以带 idempotency key
- 可以在 push 结果里逐条确认哪些成功、哪些失败

### 为什么 `payloadJSON` 要持久化

很多人一开始会问：

- 队列里为什么还要存 `payloadJSON`
- 直接在同步时从当前记录重新读字段不行吗

不行的原因非常工程化：

- 当前记录的值可能已经又变了
- 你需要重放的是“当时准备上传的 mutation”，不是“现在这条记录长什么样”

这也是同步系统和普通本地 CRUD 最大的区别之一：

- 它不仅要保存状态
- 还要保存意图

先看 demo 里的待上传队列记录，`payloadJSON`、`retryCount`、`statusRaw` 都是显式持久化的：

```swift
@Model
final class PendingTaskMutationRecord {
    var mutationID: String
    var taskRemoteID: Int
    var kindRaw: String
    var payloadJSON: String
    var createdAt: Date
    var retryCount: Int
    var lastAttemptAt: Date?
    var statusRaw: String
}

extension PendingTaskMutationRecord {
    var kind: MutationKind {
        MutationKind(rawValue: kindRaw) ?? .setFinished
    }

    var status: PendingMutationStatus {
        get { PendingMutationStatus(rawValue: statusRaw) ?? .queued }
        set { statusRaw = newValue.rawValue }
    }

    var payload: TaskMutationPayload {
        get throws {
            let data = Data(payloadJSON.utf8)
            return try JSONDecoder().decode(TaskMutationPayload.self, from: data)
        }
    }

    static func make(from payload: TaskMutationPayload) throws -> PendingTaskMutationRecord {
        let data = try JSONEncoder().encode(payload)
        guard let json = String(data: data, encoding: .utf8) else {
            throw NSError(domain: "PendingTaskMutationRecord", code: 1)
        }

        return PendingTaskMutationRecord(
            mutationID: payload.mutationID,
            taskRemoteID: payload.taskRemoteID,
            kind: payload.kind,
            payloadJSON: json,
            createdAt: payload.createdAt
        )
    }
}
```

这段代码回答了前面那个问题：为什么不能“同步时再临时拼请求”。

- `payloadJSON` 保留的是当时的上传意图，不会被后续记录变化污染
- `retryCount` 和 `lastAttemptAt` 让失败恢复从一开始就是持久化逻辑
- `mutationID` 为幂等重放准备好了基础，不需要等接真实后端再返工

再看本章两种本地修改入口，我们在这里刻意设计“共享字段入队列”和“本地专属字段只落本地”是明确分开的：

```swift
func markTaskFinished(taskRemoteID: Int, isFinished: Bool, changedAt: Date = .now) throws {
    guard let task = try store.taskRecord(remoteID: taskRemoteID) else {
        return
    }

    task.isFinished = isFinished
    task.lastLocalModifiedAt = changedAt
    task.syncState = .dirty
    task.conflictKind = nil

    let payload = TaskMutationPayload(
        mutationID: UUID().uuidString,
        taskRemoteID: taskRemoteID,
        kind: .setFinished,
        isFinished: isFinished,
        createdAt: changedAt
    )
    let pending = try PendingTaskMutationRecord.make(from: payload)
    store.context.insert(pending)
    try store.save()
}

func updateLocalNote(taskRemoteID: Int, note: String, changedAt: Date = .now) throws {
    guard let task = try store.taskRecord(remoteID: taskRemoteID) else {
        return
    }

    task.localNote = note
    task.lastLocalModifiedAt = changedAt
    try store.save()
}
```

重点关注这里的边界设计：

- 改 `isFinished` 时，同时写 `Record` 状态和 `PendingTaskMutationRecord`
- 改 `localNote` 时，不入上传队列，因为它是本地专属字段
- 两个入口都在本地先 `save()`，用户离线操作不会被网络状态阻塞
- 本地记录层的 `dirty` 和队列层的“待上传什么请求”被明确区分开了

## 模块 7：冲突不是异常，冲突是预期中的业务结果

本地和远程同时变化时，最常见的情况是：

- 两边都合法，但含义不一致

这就是冲突。

本章不追求覆盖全部产品策略，只固定一套可讲清、可实现、可验证的最小矩阵。

#### 服务端权威字段冲突

字段：

- `title`
- `estimatedMinutes`
- `sortOrder`

策略：

- 接受远程

理由：

- 这些字段属于远程计划本体

#### 本地专属字段冲突

字段：

- `localNote`

策略：

- 本地保留
- 不参与上传

理由：

- 这是设备本地学习辅助信息

#### 共享字段冲突

字段：

- `isFinished`

策略：

- 如果本地待上传修改时间晚于 `lastRemoteUpdatedAt`
  - 保留本地值
  - 继续保持 dirty，等待后续 push
- 否则
  - 接收远程值
  - 清掉本地 dirty 状态

这套策略不一定是所有业务的最佳答案，但它足够体现一个事实：

- 共享字段不能再用“对象整体远程赢 / 整体本地赢”来偷懒

#### 删除冲突

场景：

- 远程已经删掉任务
- 本地仍有待上传共享字段 mutation

策略：

- 进入 `conflict`
- 不静默删除

### 为什么冲突必须集中定义

如果你把规则分别写在：

- mapper
- store
- sync service
- 控制台输出

~~恭喜你成功产出一坨新鲜的屎山~~

后面一旦新增字段，整个系统就会开始互相打架。

所以这一章会把冲突规则集中在：

- merge / sync service 的位置

你可以把它理解成：

- 先决定策略
- 再编码

而不是遇到一个 case 就补一个 `if`

## 模块 8：为什么同步顺序默认是“先 push，再 pull”

这不是唯一可行方案，但它是本章最容易解释也最符合离线优先直觉的默认值。

### 先 push

先 push 的意义是：

- 尽量先把本地快照送出去
- 减少“远程旧快照把本地刚改的状态又带回来”的概率

### 再 pull

pull 的意义是：

- 把服务端当前最新状态重新拉回本地
- 收敛到统一结果

demo 里的 `performSync()` 就把这条顺序写成了固定编排，而不是在多个文件里各做一半：

```swift
func performSync() async throws -> SyncReport {
    var pushedMutationCount = 0
    let activeMutations = try store.fetchActivePendingMutationRecords()

    if !activeMutations.isEmpty {
        do {
            let payloads = try activeMutations.map { try $0.payload }
            let result = try await remote.push(payloads)
            let appliedIDs = Set(result.appliedMutationIDs)
            let rejectedReasons = Dictionary(
                uniqueKeysWithValues: result.rejectedMutations.map { ($0.mutationID, $0.reason) }
            )

            for mutation in activeMutations {
                mutation.lastAttemptAt = .now

                if appliedIDs.contains(mutation.mutationID) {
                    mutation.status = .applied
                    pushedMutationCount += 1
                } else if rejectedReasons[mutation.mutationID] != nil {
                    mutation.status = .failed
                    mutation.retryCount += 1
                }
            }

            try store.save()
        } catch {
            for mutation in activeMutations {
                mutation.lastAttemptAt = .now
                mutation.retryCount += 1
                mutation.status = .failed
            }
            try store.save()
            throw error
        }
    }

    let snapshot = try await remote.fetchLatestPlan()
    let merge = try StudyPlanMerger.merge(snapshot: snapshot, store: store, syncedAt: .now)
    try store.deleteAppliedMutations()
    try store.save()

    let pendingCount = try store.fetchActivePendingMutationRecords().count
    return SyncReport(
        pushedMutationCount: pushedMutationCount,
        pulledCreatedCount: merge.createdCount,
        pulledUpdatedCount: merge.updatedCount,
        pulledDeletedCount: merge.deletedCount,
        conflictCount: merge.conflictCount,
        skippedCount: merge.skippedCount,
        pendingMutationCountAfterSync: pendingCount,
        conflicts: merge.conflicts
    )
}
```

这段代码就是一个“先 push 再 pull”的典型示例：

- 先读取持久化队列，而不是临时扫描所有 record
- push 成功和失败都会更新 `lastAttemptAt`、`retryCount`、`status`
- pull 和 merge 被放在 push 之后，目的是尽量让远程快照反映刚刚提交过的本地意图
- `SyncReport` 直接从这层返回，调用方可以立刻知道这轮同步到底发生了什么

### 这套顺序的边界

它不保证解决所有复杂分布式问题，但至少能在当前教程范围内，稳定解释下面这些情况：

- 哪些本地修改已经成功推上去
- 哪些本地修改还在排队
- 哪些记录远程已经删了
- 哪些最终状态应该体现在 Domain 读取中

## 模块 9：幂等、重试、失败恢复，不是附加题

很多入门 demo 会把同步描述成：

- 发请求
- 成功就完了

真实工程的麻烦恰恰在快乐路径之外。

### 为什么需要 `mutationID`

假设上传时遇到这种情况：

- 客户端请求超时
- 但服务端其实已经处理成功

如果你没有幂等键，下一轮重试就可能把同一条修改再应用一次。

所以本章即便用脚本化远程源，也保留：

- `mutationID`

这是在把“幂等”作为工程概念引入，而不是等接真实服务端时再补救。

### 最小重试策略

本章只实现最小版本：

- push 失败后保留队列
- 增加 `retryCount`
- 写入 `lastAttemptAt`
- 下一轮 `performSync()` 再尝试

我们不展开：

- 指数退避
- 调度器
- 后台任务唤醒

但即便是最小版本，也已经足够把“同步失败后怎么办”从内存状态推进到持久化状态。

### 应用重启为什么仍然能继续同步

因为本章把下面这些状态都保存进 SwiftData：

- 当前记录的 `syncState`
- 本地修改时间
- 待上传 mutation 队列
- 重试计数

所以应用重启后，系统仍知道：

- 哪些记录还 dirty
- 哪些 mutation 还没发完
- 哪些记录已经 conflict

这正是“同步系统”和“运行时凑合逻辑”的分水岭。

## 模块 10：同步逻辑怎么做成可验证、可调试、可解释

第 46 章已经建立过一个重要判断：

- 好的工程边界应该让逻辑更容易验证

同步场景里，这个判断会变得更明显。

### 你真正要测的，不是某个 API 有没有调用，而是状态转换是否合理

例如本章固定要覆盖的场景包括：

- 远程新增任务时，本地应创建记录
- 远程更新标题时，本地 `localNote` 不应丢失
- 本地 dirty 的 `isFinished` 遇到较旧远程更新时间时，应保留本地值
- 远程删除任务但本地仍有 pending mutation 时，应进入 conflict
- 相同 `mutationID` 重放时，不应产生重复效果

### `SyncReport` 为什么重要

同步系统如果只有：

- 成功
- 失败

那定位问题会非常痛苦。

所以本章给每轮同步固定输出：

- `pushedMutationCount`
- `pulledCreatedCount`
- `pulledUpdatedCount`
- `pulledDeletedCount`
- `conflictCount`
- `skippedCount`

这不是装饰，而是最小可观测性。

你可以把它理解成：

- 每轮同步都应该给出一份“这轮到底发生了什么”的摘要

## 本章 demo 会怎么跑

本章 demo 固定使用：

- 控制台应用
- SwiftData 本地 store
- 脚本化远程源

demo 会经历下面几步：

1. 第一次 pull，同步远程 v1 计划到本地
2. 用户离线修改
   - 把一条任务标记为完成
   - 给另一条任务写本地备注
3. 重建 `ModelContainer`
   - 证明 dirty 状态和待上传队列不是内存假象
4. 远程推进到 v2
   - 更新标题与顺序
   - 新增一条任务
5. 执行第二轮同步
   - 先 push 本地完成状态
   - 再 pull v2 快照
   - 观察本地备注保留、远程字段更新、队列被清理
6. 再做一轮本地离线修改
   - 给即将被远程删除的任务补一条待上传 mutation
7. 远程推进到 v3
   - 删除一条本地仍有 pending mutation 的任务
   - 再删除一条本地无 pending mutation 的任务
8. 执行第三轮同步
   - 观察 delete conflict 与 tombstone 的差异
9. 读回 Domain
   - 只暴露业务可消费状态和必要的冲突提示

你应该重点观察三层输出：

- Record 层同步元数据
- Pending queue 层待上传意图
- Domain 层业务结果

## 一个最小代码骨架：远程边界与同步入口长什么样

先看本章的骨架，不要急着背所有细节：

```swift
protocol StudyPlanRemoteSource {
    func fetchLatestPlan() async throws -> RemoteStudyPlanSnapshotDTO
    func push(_ mutations: [TaskMutationPayload]) async throws -> PushResultDTO
}

struct StudyPlanSyncService {
    let remote: StudyPlanRemoteSource
    let store: StudyPlanStore

    func markTaskFinished(taskRemoteID: Int, isFinished: Bool) throws {
        // 本地先更新 Record
        // 再生成 PendingTaskMutationRecord
        // 再 save
    }

    func updateLocalNote(taskRemoteID: Int, note: String) throws {
        // 只改本地专属字段，不入队列
    }

    func performSync() async throws -> SyncReport {
        // 1. 读取待上传队列
        // 2. push
        // 3. fetchLatestPlan
        // 4. merge
        // 5. 清理已完成队列
        // 6. 返回 SyncReport
    }
}
```

如果你只记这一层，也已经抓到本章主线了：

- 本地修改有专门入口
- 同步编排有专门入口
- push / pull / merge / 队列清理被放进明确边界

## 一个更关键的骨架：合并器和映射器不是一回事

第 48 章里，`Mapper` 的工作是：

- 把 DTO 形状翻译成 Record 形状

第 49 章里，`Merger` 的工作变成：

- 当本地已经有记录时，应该如何按字段归属更新它

这两个角色不能继续混写。

因为“创建一条新记录”和“更新一条已有记录”面对的问题不一样：

- 创建时只要关心字段怎么落进去
- 更新时要关心：
  - 哪些字段远程赢
  - 哪些字段本地保留
  - 哪些字段要走冲突矩阵
  - 哪些记录要 tombstone

所以从这一章开始，工程上需要建立一个新的判断：

- `Mapper` 解决形状转换
- `Merger` 解决状态演进

## 读代码时你的重点

如果你打开本章 demo，请优先看下面这些东西：

1. `StudyTaskRecord` 上新增了哪些同步元数据
2. `PendingTaskMutationRecord` 到底保存了什么
3. `StudyPlanSyncService.performSync()` 为什么固定是“先 push 再 pull”
4. `StudyPlanMerger` 里是如何用字段归属矩阵处理不同字段的
5. `SyncReport` 是如何把每轮同步变得可解释的

## 读完后应有的收获

读完整章后，你至少应该形成下面这些稳定判断：

- 同步不是把远程 JSON 多存一份，而是要管理记录生命周期
- 同步系统里最先要决定的是字段归属，而不是先写请求
- 本地 dirty 状态和待上传队列都必须持久化
- 删除不能简化成一句 `delete`
- 共享字段冲突不能继续用“对象整体谁赢”来偷懒
- `SyncReport` 这种可观测性不是锦上添花，而是最小工程必需

## 本章小结

第 49 章相比前面几章，最大的变化是问题视角变了。

你现在面对的不再是：

- “能不能把数据存下来”

而是：

- “当本地和远程都在变化时，这些变化应该如何被解释、保存、恢复、重试和收敛”

这就是同步工程的本质。

同步系统不是“多写几个网络请求”，而是把：

- 数据来源
- 本地意图
- 字段归属
- 冲突规则
- 失败恢复
- 状态解释

收进一套稳定规则。

同时在这一章我们也把角度从api升级到了实际工程中的架构搭建

光学会写代码是不够的，如何将代码优雅地组织起来才是最重要的

## 下一步建议

读完本章后，如果你还想继续往下练，最自然的两个方向是：

- 把同步系统的测试层再做完整
  - 例如把 merge 规则和 queue 状态机拆成更明确的测试用例
- 把同步状态映射到 UI
  - 例如哪些任务应该显示“待同步”
  - 哪些任务应该显示“冲突待处理”

但在进入这些主题之前，请先确认你已经能清楚回答本章最核心的问题：

- 为什么这条记录的某些字段应该远程赢，某些字段必须本地保留，某些字段则必须进入冲突矩阵

如果你心中对这个问题有了明确的答案，你的代码就不会只是一堆胡乱堆积起来的屎山。


