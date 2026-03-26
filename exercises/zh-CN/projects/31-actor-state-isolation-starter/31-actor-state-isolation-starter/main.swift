//
//  main.swift
//  31-actor-state-isolation-starter
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

// 这道题直接承接第 30 章。
// starter project 里保留了两类典型冲突：
// 1. 完成数更新会丢失。
// 2. 名额检查与扣减会被并发破坏。
//
// 请按 TODO 修改：
// 1. 把 StudyProgressStore 改成 actor，并让完成数稳定变成 2。
// 2. 把 WorkshopCenter 改成 actor。
// 3. 不要把“检查名额”和“真正扣减名额”继续隔着 await 分开。
// 4. 最终结果应该只允许 1 个人报名成功。

final class StudyProgressStore: @unchecked Sendable {
    var finishedCount = 0

    func markFinished() async {
        let oldValue = finishedCount
        await pause(nanoseconds: 200_000_000)
        finishedCount = oldValue + 1
    }
}

final class WorkshopCenter: @unchecked Sendable {
    var seatsLeft = 1
    var acceptedNames: [String] = []

    func register(name: String) async -> Bool {
        if seatsLeft <= 0 {
            print("\(name) rejected")
            return false
        }

        print("\(name) sees \(seatsLeft)")
        await pause(nanoseconds: 200_000_000)
        seatsLeft -= 1
        acceptedNames.append(name)
        print("\(name) accepted \(seatsLeft)")
        return true
    }
}

func runCounterDemo() async {
    let store = StudyProgressStore()

    let first = Task {
        await store.markFinished()
    }

    let second = Task {
        await store.markFinished()
    }

    _ = await (first.value, second.value)

    // TODO 1：
    // 把 StudyProgressStore 改成 actor 后，这里需要按 actor 调用方式读取结果。
    print("finishedCount: \(store.finishedCount)")
}

func runWorkshopDemo() async {
    let center = WorkshopCenter()

    let first = Task {
        await center.register(name: "小林")
    }

    let second = Task {
        await center.register(name: "小周")
    }

    let firstResult = await first.value
    let secondResult = await second.value

    // TODO 2 和 TODO 3：
    // 这里最终应该表现出：
    // - 只有 1 个人成功
    // - acceptedNames 里只有 1 个名字
    // - seatsLeft 不会掉到负数
    print("results: 小林 \(firstResult), 小周 \(secondResult)")
    print("accepted: \(center.acceptedNames)")
    print("seatsLeft: \(center.seatsLeft)")
}

printDivider(title: "当前冲突：完成数更新")
await runCounterDemo()

printDivider(title: "当前冲突：名额报名")
await runWorkshopDemo()

printDivider(title: "TODO")
print("请把共享状态改进 actor，并让关键状态变更不再跨 await 被打断。")
