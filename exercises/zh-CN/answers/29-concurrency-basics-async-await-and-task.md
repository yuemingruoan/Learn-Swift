# 29. 并发入门：async/await 与 Task 练习答案

对应章节：

- [29. 并发入门：async/await 与 Task](../../../docs/zh-CN/chapters/29-concurrency-basics-async-await-and-task.md)

如果你想一边看答案一边运行 starter project，可以打开：

- `exercises/zh-CN/projects/29-concurrency-basics-async-await-and-task-starter`

如果你想直接运行本章练习的参考工程，也可以打开：

- `exercises/zh-CN/answers/29-concurrency-basics-async-await-and-task`

说明：

- 本章作业不是让你继续加业务，而是让你把一个已经能跑的异步项目整理清楚。
- starter project 已经能生成学习看板和导出学习报告。
- 这道题的核心不是“哪里都包一层 `Task`”，而是把启动任务、等待结果、处理失败和响应取消分别放对位置。

## 当前问题

starter project 里主要有下面几类问题：

1. `loadDashboardData()` 把彼此独立的加载写成了顺序等待。
2. `buildSummaryLine(tasks:reminder:)` 里没有等待点，却额外创建了一个 `Task`。
3. `runDashboardDemo()` 仍然沿用了不必要的 `await`。
4. `buildStudyReportLines(from:)` 收到取消后还是继续把完整报告整理完。
5. `runReportExportDemo(dashboard:)` 发出了 `cancel()`，但没有把取消真正接回错误路径处理。

这些问题共同导致的现象是：

- 看板加载的等待点不够清楚
- 普通计算被伪装成了异步任务
- 取消信号发出后，代码仍然按完整成功路径继续执行

## 你需要完成的重构

1. 把 `loadDashboardData()` 改成“先启动两个任务，再统一取结果”。
2. 把 `buildSummaryLine(tasks:reminder:)` 改回同步函数。
3. 同步调整 `runDashboardDemo()` 的调用方式。
4. 把 `buildStudyReportLines(from:)` 改成 `async throws`，并在关键等待点检查取消。
5. 用 `try await + do-catch` 重构 `runReportExportDemo(dashboard:)`。

## 完成标准

完成后，你的代码至少应该表现出下面这些特征：

- 学习看板里的任务列表和提醒文本会先分别启动，而不是第一项做完才开始第二项。
- `buildSummaryLine(tasks:reminder:)` 不再额外创建 `Task`。
- `runDashboardDemo()` 里不会继续 `await` 一个已经改成同步函数的调用。
- 报告导出在收到取消后，会沿取消路径结束，而不是继续打印完整报告内容。
- 你能明确指出哪几处使用了 `Task { ... }`、`task.value`、`try await` 和 `Task.checkCancellation()`。

## 参考重构方向

这一题比较稳妥的顺序通常是：

1. 先处理“先启动，再等待”。
2. 再删除那些没有必要的 `Task`。
3. 最后把取消接到 `throws` 和 `do-catch` 上。

参考答案里会接近下面这种结构：

```swift
func loadDashboardData() async throws -> ([StudyTask], String) {
    let tasksTask = Task {
        try await loadTaskTitles()
    }

    let reminderTask = Task {
        await loadReminderText()
    }

    let tasks = try await tasksTask.value
    let reminder = await reminderTask.value
    return (tasks, reminder)
}

func buildSummaryLine(tasks: [StudyTask], reminder: String) -> String { ... }

func buildStudyReportLines(from dashboard: StudyDashboard) async throws -> [String] { ... }
```

## 为什么 `buildSummaryLine(tasks:reminder:)` 不该继续是 async

这是本题很容易被忽略的一点。

`buildSummaryLine(tasks:reminder:)` 当前做的只是：

- 统计未完成任务数量
- 拼一段摘要字符串

这里没有网络请求，没有文件 I/O，也没有任何真实等待点。

所以更自然的写法应该是：

- 同步函数直接返回结果

如果这里还继续包 `Task`，虽然表面上也能跑，但实际会让边界更乱：

- 本来只是普通计算
- 却被写成了异步任务

这正是本章最重要的判断之一：

- 不是出现“结果”就一定要上 `Task`
- 只有真的需要异步组织时，才值得新建任务

## 为什么 `cancel()` 之后还要写 `Task.checkCancellation()`

这也是本题的关键点。

`cancel()` 只是发出一个取消信号。

它不是：

- 强制立刻把所有代码掐断

如果任务内部从来不检查取消状态，那么很容易出现 starter project 里的现象：

- 外面已经调用了 `cancel()`
- 里面还是继续整理完整报告

所以参考答案里，会在等待点之后补上：

```swift
try Task.checkCancellation()
```

这样任务在关键推进节点上，就能明确决定：

- 如果已经取消，就沿失败路径结束

## 这一题最容易犯的几个错误

### 1. 把所有异步调用都包进 Task

这会让流程越来越乱。

如果你已经在 `async` 函数里，而且只是继续往下调用异步函数，很多时候应该直接 `await`。

### 2. 只改启动方式，不改取结果方式

如果你前面已经把工作改成了：

- 先创建 `Task`

那后面就应该配套地用：

- `task.value`

把结果取回来。

### 3. 以为 cancel() 自己就会让任务停下

不会。

你仍然需要在任务内部的关键位置检查取消状态。

### 4. 把本来该是同步函数的逻辑也继续写成 async

这会让读代码的人误以为：

- 这里也存在真实等待点

而这正是本题要避免的混乱。

## 参考工程说明

如果你想直接运行参考实现，可以打开：

- `exercises/zh-CN/answers/29-concurrency-basics-async-await-and-task`

参考工程里最值得重点观察的是：

- 学习看板阶段，“任务列表：开始”和“提醒：开始”都会在最终汇总前启动。
- 摘要整理不再额外创建 `Task`。
- 报告导出在取消后，不会继续打印完整报告，而是走“报告导出已取消”这条路径。
