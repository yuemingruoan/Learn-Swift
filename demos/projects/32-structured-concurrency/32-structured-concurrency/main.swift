//
//  main.swift
//  32-structured-concurrency
//
//  Created by Codex on 2026/3/26.
//

enum SummaryLoadError: Error {
    case missingChapter(String)
}

func printDivider(title: String) {
    print("")
    print("======== \(title) ========")
}

func pause(nanoseconds: UInt64) async {
    do {
        try await Task.sleep(nanoseconds: nanoseconds)
    } catch {
    }
}

func loadSyntaxValue(_ value: String) async -> String {
    await pause(nanoseconds: 50_000_000)
    return value
}

// 下面这些辅助函数故意带不同延迟，
// 这样运行时就能更直观看到“顺序等待”和“并发等待”的差异。
func loadTaskTitles() async -> [String] {
    print("titles start")
    await pause(nanoseconds: 500_000_000)
    print("titles end")
    return ["理解 actor", "整理 TaskGroup", "准备 AsyncSequence 例子"]
}

func loadReminderText() async -> String {
    print("reminder start")
    await pause(nanoseconds: 400_000_000)
    print("reminder end")
    return "先把固定数量和动态数量的场景分清"
}

func loadChapterSummary(_ title: String) async -> String {
    let delay: UInt64
    switch title {
    case "第 30 章":
        delay = 400_000_000
    case "第 31 章":
        delay = 200_000_000
    default:
        delay = 300_000_000
    }

    print("\(title) start")
    await pause(nanoseconds: delay)
    print("\(title) end")
    return "\(title) 摘要"
}

func runMinimalSyntaxDemo() async {
    // 这是本章最小的结构化并发模板。
    // 它先展示最常见的 async let 外形：
    // 1. 用 async let 声明固定数量的子任务
    // 2. 子任务仍然属于当前函数
    // 3. 稍后再统一 await 它们的结果
    async let first = loadSyntaxValue("A")
    async let second = loadSyntaxValue("B")

    let results = await [first, second]
    print("results: \(results)")
}

func loadChapterSummaryWithFailure(_ title: String) async throws -> String {
    let delay: UInt64
    switch title {
    case "第 30 章":
        delay = 200_000_000
    case "第 32 章":
        delay = 250_000_000
    default:
        delay = 500_000_000
    }

    print("\(title) start")
    await pause(nanoseconds: delay)
    try Task.checkCancellation()

    if title == "第 32 章" {
        throw SummaryLoadError.missingChapter(title)
    }

    print("\(title) end")
    return "\(title) 摘要"
}

func runSequentialDemo() async {
    // 顺序 await 的含义是：
    // 先把第一件事完整做完，再开始第二件事。
    // 所以控制台上会先看到 titles start/end，再看到 reminder start/end。
    let titles = await loadTaskTitles()
    let reminder = await loadReminderText()
    print("count: \(titles.count)")
    print("reminder: \(reminder)")
}

func runAsyncLetDemo() async {
    // async let 表达的是：
    // 这几个子任务都属于当前函数，并且数量固定，
    // 可以先一起发出去，稍后再分别等待结果。
    async let titles = loadTaskTitles()
    async let reminder = loadReminderText()

    let loadedTitles = await titles
    let loadedReminder = await reminder
    print("count: \(loadedTitles.count)")
    print("reminder: \(loadedReminder)")
}

func runTaskGroupDemo() async {
    let chapterTitles = ["第 30 章", "第 31 章", "第 32 章"]

    // 这里的重点不是“也能并发”，而是“子任务数量来自输入集合”。
    // 当任务个数不是写死在代码里时，TaskGroup 比 async let 更合适。
    // 此外，for await summary in group 收到结果的顺序更接近“谁先完成，谁先返回”。
    let summaries = await withTaskGroup(of: String.self, returning: [String].self) { group in
        for title in chapterTitles {
            group.addTask {
                await loadChapterSummary(title)
            }
        }

        var results: [String] = []
        for await summary in group {
            results.append(summary)
        }
        return results
    }

    print("summaries: \(summaries)")
}

func runThrowingTaskGroupDemo() async {
    let chapterTitles = ["第 30 章", "第 32 章", "第 33 章"]

    do {
        // 这一段和普通 TaskGroup 的差别是：
        // 子任务不仅可以动态创建，还可以把失败沿父流程清楚地抛回来。
        let summaries = try await withThrowingTaskGroup(of: String.self, returning: [String].self) { group in
            for title in chapterTitles {
                group.addTask {
                    try await loadChapterSummaryWithFailure(title)
                }
            }

            var results: [String] = []
            for try await summary in group {
                results.append(summary)
            }
            return results
        }

        print("summaries: \(summaries)")
    } catch SummaryLoadError.missingChapter(let title) {
        print("error: \(title)")
    } catch {
        print("error")
    }
}

// 本章重点可以按“任务归属关系”来理解：
// 1. 结构化并发关心的不是能不能起任务，而是这些子任务是否清楚地属于当前父流程。
// 2. async let 适合少量、固定数量、彼此独立的子任务。
// 3. TaskGroup 适合数量动态、需要循环创建的子任务。
// 4. Throwing TaskGroup 让错误路径仍然沿父子结构返回，而不是把失败藏在角落里。
// 5. 裸 Task 依然有价值，但不该成为组织并发工作的默认答案。
printDivider(title: "最小语法示例")
await runMinimalSyntaxDemo()

printDivider(title: "顺序 await：先做完一个，再做下一个")
await runSequentialDemo()

printDivider(title: "async let：固定数量的并发子任务")
await runAsyncLetDemo()

printDivider(title: "TaskGroup：动态数量的子任务")
await runTaskGroupDemo()

printDivider(title: "withThrowingTaskGroup：把错误沿父流程抛回来")
await runThrowingTaskGroupDemo()
