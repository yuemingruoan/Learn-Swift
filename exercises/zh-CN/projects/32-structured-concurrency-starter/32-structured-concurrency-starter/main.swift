//
//  main.swift
//  32-structured-concurrency-starter
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

// 这道题的重点是“把任务组织回父流程里”，不是继续裸起一堆 Task。
//
// 请按 TODO 修改：
// 1. 把固定数量的概览加载改成 async let。
// 2. 把动态数量的章节摘要加载改成 withThrowingTaskGroup。
// 3. 让错误沿父流程抛回，而不是在循环里悄悄吞掉。

func loadPinnedTitles() async -> [String] {
    print("titles start")
    await pause(nanoseconds: 400_000_000)
    print("titles end")
    return ["第 30 章", "第 31 章", "第 32 章"]
}

func loadReminderText() async -> String {
    print("reminder start")
    await pause(nanoseconds: 300_000_000)
    print("reminder end")
    return "固定数量时先想 async let，数量动态时再想 TaskGroup"
}

func loadOverview() async -> ([String], String) {
    // TODO 1：
    // 这里的 titles 和 reminder 数量固定、彼此独立，
    // 请改成 async let 的写法，而不是顺序 await。
    let titles = await loadPinnedTitles()
    let reminder = await loadReminderText()
    return (titles, reminder)
}

func loadChapterSummary(_ title: String) async throws -> String {
    let delay: UInt64
    switch title {
    case "第 30 章":
        delay = 350_000_000
    case "第 31 章":
        delay = 150_000_000
    default:
        delay = 250_000_000
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

func buildChapterSummaries(for titles: [String]) async -> [String] {
    // TODO 2：
    // 当前版本的问题有两个：
    // 1. 这是动态数量任务，但仍然一项一项顺序等待。
    // 2. 错误在这里被吞掉了，没有沿父流程往上抛。
    //
    // 请把它改成：
    //   func buildChapterSummaries(for titles: [String]) async throws -> [String]
    //
    // 并使用 withThrowingTaskGroup。
    var results: [String] = []

    for title in titles {
        do {
            let summary = try await loadChapterSummary(title)
            results.append(summary)
        } catch {
            results.append("失败：\(title)")
        }
    }

    return results
}

func runOverviewDemo() async -> [String] {
    let (titles, reminder) = await loadOverview()
    print("count: \(titles.count)")
    print("reminder: \(reminder)")
    return titles
}

func runSummaryDemo(titles: [String]) async {
    // TODO 3：
    // 如果你把 buildChapterSummaries 改成 async throws，
    // 这里也要一起改成 try await + do-catch。
    let summaries = await buildChapterSummaries(for: titles)
    print("summaries: \(summaries)")
    print("TODO：这里应该让错误沿父流程回到调用点。")
}

printDivider(title: "当前流程：固定数量任务")
let titles = await runOverviewDemo()

printDivider(title: "当前流程：动态数量任务与错误")
await runSummaryDemo(titles: titles)
