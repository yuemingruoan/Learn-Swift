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
    async let titles = loadPinnedTitles()
    async let reminder = loadReminderText()

    return await (titles, reminder)
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

func buildChapterSummaries(for titles: [String]) async throws -> [String] {
    return try await withThrowingTaskGroup(of: String.self, returning: [String].self) { group in
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

func runOverviewDemo() async -> [String] {
    let (titles, reminder) = await loadOverview()
    print("count: \(titles.count)")
    print("reminder: \(reminder)")
    return titles
}

func runSummaryDemo(titles: [String]) async {
    do {
        let summaries = try await buildChapterSummaries(for: titles)
        print("summaries: \(summaries)")
    } catch SummaryLoadError.missingChapter(let title) {
        print("error: \(title)")
    } catch {
        print("error")
    }
}

printDivider(title: "重构后：固定数量任务")
let titles = await runOverviewDemo()

printDivider(title: "重构后：动态数量任务与错误")
await runSummaryDemo(titles: titles)
