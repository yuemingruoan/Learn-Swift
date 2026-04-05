# 49. SwiftData 同步工程：增量更新、冲突处理与离线一致性 练习答案

对应章节：

- [49. SwiftData 同步工程：增量更新、冲突处理与离线一致性](../../../docs/zh-CN/chapters/49-swiftdata-sync-engineering-incremental-update-conflict-resolution-and-offline-consistency.md)

如果你想一边看答案一边运行 starter project，可以打开：

- `exercises/zh-CN/projects/49-swiftdata-sync-engineering-starter`

如果你想直接运行本章练习的参考工程，也可以打开：

- `exercises/zh-CN/answers/49-swiftdata-sync-engineering`

## 这道题在练什么

这道练习不是再练一遍 SwiftData 基础 CRUD，而是把第 49 章里最关键的同步判断收成一份可补全的小题：

1. 不再用“全删全建”处理远程快照
2. 本地修改共享字段后，要同时留下 dirty 状态和待上传队列
3. 本地专属字段不应被下一轮远程快照冲掉
4. 远程缺失本地记录时，要区分 tombstone 和 conflict
5. 同步结果要能用一份最小 `SyncReport` 解释清楚

starter project 之所以故意写错，是为了把这些痛点压到一份足够小的代码里，让你能专门练“同步规则”，而不是先被工程结构分散注意力。

## starter 当前的问题

starter 里最关键的缺口有五个：

1. `replaceAll(with:)` 仍然是“先删再插”，会直接丢掉 `localNote`
2. `markFinished(taskRemoteID:isFinished:)` 只改了字段值，没有把记录标成 dirty
3. 本地完成状态修改后，没有写任何待上传队列
4. 第二轮远程快照缺失 task `#1` 时，starter 会直接把旧记录删掉
5. `SyncReport` 只会描述“删了多少旧记录”，而不是本轮真正发生的 create / update / delete / conflict

## 你需要完成的修改

1. 把 `replaceAll(with:)` 改成按 `remoteID` 做 upsert
2. 保留 `localNote` 这样的本地专属字段
3. 在 `markFinished` 里同时写：
   - `lastLocalModifiedAt`
   - `syncState = .dirty`
   - `PendingMutationRecord`
4. 对“远程缺失”的记录区分两种情况：
   - 没有 pending mutation：进入 `tombstoned`
   - 仍有 pending mutation：进入 `conflict`
5. 让 `SyncReport` 能统计：
   - 新建数量
   - 更新数量
   - 删除数量
   - 冲突数量
   - 当前待上传队列数

## 参考实现的关键判断

答案项目里最关键的不是代码量，而是下面这几个判断顺序：

1. 先按 `remoteID` 把本地已有记录建成索引
2. 遍历远程快照时：
   - 有同 `remoteID` 就更新
   - 没有就创建
3. 更新时只覆盖远程权威字段
   - 本题里是 `title`
4. 本地专属字段继续保留
   - 本题里是 `localNote`
5. 本地共享字段一旦被修改：
   - 进入 dirty
   - 进入 pending queue
6. 再处理“远程缺失”的旧记录：
   - 没 pending：tombstone
   - 有 pending：conflict

这正是第 49 章正文里一直在强调的同步视角：

- 不是“重新解码一次 JSON”
- 而是“用规则解释已有本地状态怎么演进”

## 为什么答案不继续用“全删全建”

因为这道题的核心目标之一，就是让你切身体会下面这个工程事实：

- 只要本地开始允许编辑，你就不能再把本地 SwiftData store 当成“远程快照缓存副本”

如果继续全删全建：

- task `#2` 的本地备注会消失
- task `#1` 的本地完成状态会没有任何同步痕迹
- 你也无法知道 task `#1` 是“远程正常删除”还是“本地还有待上传修改时被删掉”

所以答案把“按 `remoteID` 做 upsert”放在第一优先级。

## 为什么 `markFinished` 必须写队列

本地共享字段修改后，只改记录值还不够。

如果你只做：

- `task.isFinished = true`

却没有记录“这条修改待上传”，那应用重启后你就失去了：

- 这条修改还没同步完的证据
- 上传顺序
- 重试入口

所以答案里 `markFinished` 会同时做三件事：

1. 改本地记录值
2. 标记 `syncState = .dirty`
3. 追加一条 `PendingMutationRecord`

## 为什么缺失记录不能一律 `delete`

这题的第二轮远程快照故意移除了 task `#1`。

而 task `#1` 在本地又刚好被标记成完成，并进入了 pending queue。

这时如果你直接删掉本地记录，问题就来了：

- 用户刚做过的本地修改被静默吞掉
- 你无法区分这到底是“远程正常删除”还是“有冲突的删除”

所以答案才会把这种情况标成：

- `syncState = .conflict`
- `isTombstoned = true`

这让删除变成了一个可解释状态，而不是悄悄消失。

## 一份最小 `SyncReport` 为什么值得保留

即便这道题只是练习，答案里也保留了一份很小的 `SyncReport`。

原因很简单：

- 同步系统如果只有“成功/失败”，你很难知道这一轮到底发生了什么

这题只统计五个数字：

- `createdCount`
- `updatedCount`
- `deletedCount`
- `conflictCount`
- `pendingCount`

但已经足够让你回答：

- 远程新增了几条
- 本地更新了几条
- 有几条进入 tombstone
- 有几条进入 conflict
- 队列里还剩几条没处理

## 参考答案代码

参考工程已经放在：

- `exercises/zh-CN/answers/49-swiftdata-sync-engineering`

建议你先自己完成 starter，再回来看答案。因为这道题真正要训练的，不是背某个 SwiftData API，而是建立下面这条工程直觉：

1. 字段要先分归属
2. 共享字段修改要留下同步痕迹
3. 本地专属字段不能被远程快照顺手覆盖
4. 删除要区分普通 tombstone 和冲突
5. 每一轮同步都应该能被解释清楚

只要这套判断顺序稳定了，后面你把它扩展到更完整的同步系统，就不会只剩一堆“刚好能跑”的分支。
