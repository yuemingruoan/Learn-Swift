//
//  main.swift
//  31-actor-state-isolation
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

actor StudyProgressStore {
    private var finishedCount = 0

    func markFinished() {
        finishedCount += 1
    }

    func currentCount() -> Int {
        return finishedCount
    }
}

actor WorkshopCenter {
    private var seatsLeft = 1
    private var acceptedNames: [String] = []

    func reserveSeat(for name: String) -> Bool {
        guard seatsLeft > 0 else {
            return false
        }

        seatsLeft -= 1
        acceptedNames.append(name)
        return true
    }

    func snapshot() -> ([String], Int) {
        return (acceptedNames, seatsLeft)
    }
}

func register(name: String, center: WorkshopCenter) async -> Bool {
    let accepted = await center.reserveSeat(for: name)

    if accepted {
        await pause(nanoseconds: 200_000_000)
        print("\(name) accepted")
        return true
    }

    print("\(name) rejected")
    return false
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
    let finishedCount = await store.currentCount()
    print("finishedCount: \(finishedCount)")
}

func runWorkshopDemo() async {
    let center = WorkshopCenter()

    let first = Task {
        await register(name: "小林", center: center)
    }

    let second = Task {
        await register(name: "小周", center: center)
    }

    let firstResult = await first.value
    let secondResult = await second.value
    let snapshot = await center.snapshot()

    print("results: 小林 \(firstResult), 小周 \(secondResult)")
    print("accepted: \(snapshot.0)")
    print("seatsLeft: \(snapshot.1)")
}

printDivider(title: "actor 隔离后的完成数更新")
await runCounterDemo()

printDivider(title: "actor 隔离后的名额报名")
await runWorkshopDemo()

printDivider(title: "重构结果")
print("共享状态已经放进 actor，名额检查和扣减也被收进同一个不等待的关键动作。")
