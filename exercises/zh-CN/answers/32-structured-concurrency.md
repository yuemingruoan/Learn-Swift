# 32. 结构化并发：async let、TaskGroup 与父子任务 练习答案

对应章节：

- [32. 结构化并发：async let、TaskGroup 与父子任务](../../../docs/zh-CN/chapters/32-structured-concurrency.md)

如果你想一边看答案一边运行 starter project，可以打开：

- `exercises/zh-CN/projects/32-structured-concurrency-starter`

如果你想直接运行本章练习的参考工程，也可以打开：

- `exercises/zh-CN/answers/32-structured-concurrency`

说明：

- 本章作业不是共享状态修复题，而是任务组织题。
- starter project 里已经有并发相关代码，但父子任务关系和错误路径都不够清楚。
- 这道题的重点是先分清：固定数量任务该用什么，动态数量任务该用什么，错误该沿哪条路回来。

## 当前问题

starter project 里主要有三类问题：

1. `loadOverview()` 里固定数量的两项加载仍然写成了顺序等待。
2. `buildChapterSummaries(for:)` 面对动态数量任务时，还是一项一项顺序处理。
3. 章节摘要加载失败后，错误在循环里被吞掉了，没有沿父流程返回。

## 你需要完成的重构

1. 把 `loadOverview()` 改成 `async let`。
2. 把 `buildChapterSummaries(for:)` 改成 `async throws`。
3. 在 `buildChapterSummaries(for:)` 里使用 `withThrowingTaskGroup`。
4. 在调用点用 `try await + do-catch` 接回错误。

## 完成标准

完成后，你的代码至少应该表现出下面这些特征：

- `titles` 和 `reminder` 会先一起启动，再统一取结果。
- 动态数量的章节摘要会通过循环 `addTask` 创建。
- 错误不会继续在内部悄悄变成普通字符串。
- 父流程能够明确拿到“第 32 章摘要缺失”的失败信息。

## 参考重构方向

这一题最自然的分工通常是：

- 固定数量、彼此独立：`async let`
- 动态数量、循环创建：`TaskGroup`
- 动态数量且可能失败：`withThrowingTaskGroup`

参考答案里会接近下面这种结构：

```swift
func loadOverview() async -> ([String], String) {
    async let titles = loadPinnedTitles()
    async let reminder = loadReminderText()
    return await (titles, reminder)
}

func buildChapterSummaries(for titles: [String]) async throws -> [String] {
    try await withThrowingTaskGroup(of: String.self, returning: [String].self) { group in
        for title in titles {
            group.addTask {
                try await loadChapterSummary(title)
            }
        }

        var results: [String] = []
        for try await summary in group {
            results.append(summary)
        }
        return results
    }
}
```

## 为什么这里不该继续吞掉错误

这是本题非常关键的一点。

如果你在 `buildChapterSummaries(for:)` 里直接写：

- `catch { results.append("失败：...") }`

表面上看代码还能跑，但父流程已经失去了真正的失败信息。

而结构化并发更想表达的是：

- 子任务属于当前父流程
- 子任务的失败也应该沿当前父流程清楚返回

所以这题的重点不是“把错误变成字符串”，而是“把错误留在错误路径里”。

## 参考工程说明

如果你想直接运行参考实现，可以打开：

- `exercises/zh-CN/answers/32-structured-concurrency`

你最应该重点观察的是：

- 顺序等待和 `async let` 的控制台输出顺序差异
- `TaskGroup` 返回结果更接近“谁先完成谁先被收集”
- `第 32 章` 失败后，错误怎样沿父流程回到调用点
