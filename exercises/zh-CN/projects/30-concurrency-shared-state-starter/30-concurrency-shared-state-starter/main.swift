//
//  main.swift
//  30-concurrency-shared-state-starter
//
//  Created by Codex on 2026/3/26.
//

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

// 这道作业的重点不是“修好所有问题”，而是先识别危险外形。
//
// 请先运行这份 starter project，再对照代码判断：
// 1. 哪些案例共享了同一份可变状态。
// 2. 哪些属于“先读后写”。
// 3. 哪些属于“先检查再修改”。
// 4. 哪些虽然并发推进，但其实没有共享状态风险。
//
// 请把你的答案填到 ExerciseAnswers 里，直接使用下面这些案例名字：
// - IndependentLoads
// - FinishedCountStore.markFinished
// - NotesStore.append
// - ProgressCache.update
// - WorkshopCenter.register

struct ExerciseAnswers {
    let sharedStateCases: [String]
    let readThenWriteCases: [String]
    let checkThenActCases: [String]
    let independentCases: [String]
}

let answers = ExerciseAnswers(
    sharedStateCases: [],
    readThenWriteCases: [],
    checkThenActCases: [],
    independentCases: []
)

final class FinishedCountStore: @unchecked Sendable {
    var finishedCount = 0

    func markFinished(label: String) async {
        let oldValue = finishedCount
        print("\(label) read \(oldValue)")
        await pause(nanoseconds: 200_000_000)
        finishedCount = oldValue + 1
        print("\(label) write \(finishedCount)")
    }
}

final class NotesStore: @unchecked Sendable {
    var notes: [String] = []

    func append(_ note: String) async {
        let snapshot = notes
        print("\(note) snapshot \(snapshot.count)")
        await pause(nanoseconds: 200_000_000)

        var newNotes = snapshot
        newNotes.append(note)
        notes = newNotes
        print("\(note) stored \(notes.count)")
    }
}

final class ProgressCache: @unchecked Sendable {
    var statusByChapter: [String: String] = [:]

    func update(chapter: String, status: String) async {
        var snapshot = statusByChapter
        print("\(chapter) snapshot \(snapshot.keys.sorted())")
        await pause(nanoseconds: 200_000_000)
        snapshot[chapter] = status
        statusByChapter = snapshot
        print("\(chapter) stored \(status)")
    }
}

final class WorkshopCenter: @unchecked Sendable {
    var seatsLeft = 1
    var acceptedNames: [String] = []

    func register(name: String) async -> Bool {
        print("\(name) sees \(seatsLeft)")

        if seatsLeft <= 0 {
            print("\(name) rejected")
            return false
        }

        await pause(nanoseconds: 200_000_000)
        seatsLeft -= 1
        acceptedNames.append(name)
        print("\(name) accepted \(seatsLeft)")
        return true
    }
}

func runIndependentLoadsDemo() async {
    async let loadTitles: [String] = {
        await pause(nanoseconds: 150_000_000)
        return ["第 30 章", "第 31 章"]
    }()

    async let loadReminder: String = {
        await pause(nanoseconds: 120_000_000)
        return "先识别共享状态，再判断属于哪种风险外形"
    }()

    let titles = await loadTitles
    let reminder = await loadReminder
    print("titles: \(titles)")
    print("reminder: \(reminder)")
}

func runFinishedCountDemo() async {
    let store = FinishedCountStore()

    async let first: Void = store.markFinished(label: "任务 A")
    async let second: Void = store.markFinished(label: "任务 B")
    _ = await (first, second)

    print("finishedCount: \(store.finishedCount)")
}

func runNotesDemo() async {
    let store = NotesStore()

    async let first: Void = store.append("闭包")
    async let second: Void = store.append("并发")
    _ = await (first, second)

    print("notes: \(store.notes)")
}

func runCacheDemo() async {
    let cache = ProgressCache()

    async let first: Void = cache.update(chapter: "第 30 章", status: "已完成")
    async let second: Void = cache.update(chapter: "第 31 章", status: "进行中")
    _ = await (first, second)

    print("cache: \(cache.statusByChapter)")
}

func runWorkshopDemo() async {
    let center = WorkshopCenter()

    async let first = center.register(name: "小林")
    async let second = center.register(name: "小周")

    let firstResult = await first
    let secondResult = await second

    print("results: 小林 \(firstResult), 小周 \(secondResult)")
    print("accepted: \(center.acceptedNames)")
    print("seatsLeft: \(center.seatsLeft)")
}

func printSubmittedAnswers(_ answers: ExerciseAnswers) {
    print("sharedStateCases: \(answers.sharedStateCases)")
    print("readThenWriteCases: \(answers.readThenWriteCases)")
    print("checkThenActCases: \(answers.checkThenActCases)")
    print("independentCases: \(answers.independentCases)")
}

printDivider(title: "案例目录")
print("- IndependentLoads")
print("- FinishedCountStore.markFinished")
print("- NotesStore.append")
print("- ProgressCache.update")
print("- WorkshopCenter.register")

printDivider(title: "案例 1：并发但互不共享状态")
await runIndependentLoadsDemo()

printDivider(title: "案例 2：完成数更新")
await runFinishedCountDemo()

printDivider(title: "案例 3：数组追加")
await runNotesDemo()

printDivider(title: "案例 4：字典缓存写入")
await runCacheDemo()

printDivider(title: "案例 5：名额检查与扣减")
await runWorkshopDemo()

printDivider(title: "TODO")
print("请把你的分类结果填进 ExerciseAnswers。")
printSubmittedAnswers(answers)
