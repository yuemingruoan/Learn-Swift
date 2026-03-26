//
//  main.swift
//  30-concurrency-shared-state
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

// 这是本章最小的“共享状态 + 并发访问”代码模板。
// 重点不是业务意义，而是让读者先记住这类代码最常见的外形：
// 1. 一个可被共享引用的 class 实例
// 2. 里面有可变状态
// 3. 两个并发任务同时调用会修改这份状态的方法
final class MinimalSharedCounter: @unchecked Sendable {
    var value = 0

    func increment() async {
        let oldValue = value
        await pause(nanoseconds: 50_000_000)
        value = oldValue + 1
    }
}

// 这个类型故意使用 class，让两个并发任务共享同一个引用。
// 这样一来，两个任务看到的就是同一份 finishedCount，
// 便于演示“共享可变状态”在并发里为什么危险。
final class StudyCounter: @unchecked Sendable {
    var finishedCount = 0

    func markFinished(label: String) async {
        // 这里不要把 += 1 想成一个绝对不可分割的黑盒动作。
        // 为了把风险讲清楚，我们把它展开成：
        // 1. 读取旧值
        // 2. 等待一小段时间，制造两个任务交错执行的机会
        // 3. 基于旧值算出新值，再写回去
        //
        // 如果两个任务都读到同一个旧值，它们就可能把彼此的结果覆盖掉。
        let oldValue = finishedCount
        print("\(label) read \(oldValue)")
        await pause(nanoseconds: 300_000_000)

        let newValue = oldValue + 1
        finishedCount = newValue
        print("\(label) write \(newValue)")
    }
}

// 这个类型演示另一种常见风险外形：先检查条件，再根据条件修改状态。
// 单线程里这很常见，但在并发里“检查时看到的状态”和“真正修改时的状态”
// 可能已经不是同一份快照了。
final class WorkshopCenter: @unchecked Sendable {
    var seatsLeft = 1
    var acceptedNames: [String] = []

    func register(name: String) async -> Bool {
        print("\(name) sees \(seatsLeft)")

        if seatsLeft <= 0 {
            print("\(name) rejected")
            return false
        }

        await pause(nanoseconds: 300_000_000)
        seatsLeft -= 1
        acceptedNames.append(name)
        print("\(name) accepted \(seatsLeft)")
        return true
    }
}

func runMinimalSyntaxDemo() async {
    // 最小模板：
    // 1. 先创建会被共享访问的引用类型实例
    // 2. 再用 async let 并发发起两个调用
    // 3. 最后等待它们完成，并查看共享状态的最终结果
    let counter = MinimalSharedCounter()

    async let first: Void = counter.increment()
    async let second: Void = counter.increment()
    _ = await (first, second)

    print("value: \(counter.value)")
}

func runIndependentTasksDemo() async {
    // 这一段先做对照组。
    // 两个异步任务确实会并发推进，但它们只是分别产出自己的结果，
    // 并没有共同修改同一份可变状态，所以这里不会触发共享状态问题。
    async let loadTitles: [String] = {
        await pause(nanoseconds: 250_000_000)
        return ["第 30 章", "第 31 章"]
    }()

    async let loadReminder: String = {
        await pause(nanoseconds: 200_000_000)
        return "先理解共享状态，再看 actor"
    }()

    let titles = await loadTitles
    let reminder = await loadReminder
    print("titles: \(titles)")
    print("reminder: \(reminder)")
}

func runLostUpdateDemo() async {
    let counter = StudyCounter()

    // 两个任务都会走同一套“读旧值 -> 等待 -> 写回”的流程。
    // 理想情况下调用两次后 finishedCount 应该是 2，
    // 但这个 demo 的目的就是让你看到：结果可能只剩 1。
    async let first: Void = counter.markFinished(label: "任务 A")
    async let second: Void = counter.markFinished(label: "任务 B")
    _ = await (first, second)

    print("finishedCount: \(counter.finishedCount)")
}

func runCheckThenActDemo() async {
    let center = WorkshopCenter()

    // 这里故意制造“先检查，再修改”的并发冲突。
    // 正常业务约束是：只剩 1 个名额时，最多只允许 1 个人成功。
    // 但两个任务如果都在扣减之前看到 seatsLeft == 1，
    // 它们就可能一起沿着“成功报名”的路径继续往下走。
    async let first = center.register(name: "小林")
    async let second = center.register(name: "小周")

    let firstResult = await first
    let secondResult = await second

    print("results: 小林 \(firstResult), 小周 \(secondResult)")
    print("accepted: \(center.acceptedNames)")
    print("seatsLeft: \(center.seatsLeft)")
}

// 本章重点可以按下面顺序理解：
// 1. 多个任务同时存在，不等于一定会出问题。
//    真正要先找的是：它们有没有共同读写同一份可变状态。
// 2. 只要代码依赖“我刚刚读到的旧状态”，就要提高警惕。
//    典型外形包括：先读后写、+= 1、append、字典写入、先检查再修改。
// 3. 这类问题最难受的地方是：代码不一定崩溃，
//    但结果会偶尔不对，而且每次不一定都稳定复现。
// 4. 下一章的 actor，不是为了让代码“更并发”，
//    而是为了给这种共享可变状态建立清楚的隔离边界。
printDivider(title: "最小语法示例")
await runMinimalSyntaxDemo()

printDivider(title: "多个任务同时运行，不一定危险")
await runIndependentTasksDemo()

printDivider(title: "读旧值再写新值，会丢失更新")
await runLostUpdateDemo()

printDivider(title: "先检查再修改，也会破坏业务约束")
await runCheckThenActDemo()
