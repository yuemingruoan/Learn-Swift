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

// 这是本章最小的 actor 语法模板。
// 它只保留三个最核心的动作：
// 1. 定义 actor
// 2. 创建实例
// 3. 在 async 上下文里用 await 调用成员
actor MinimalCounterStore {
    private var value = 0

    func addOne() {
        value += 1
    }

    func currentValue() -> Int {
        return value
    }
}

// actor 也是引用类型，但它比普通 class 多了一层“隔离边界”。
// 外部代码不能像访问普通共享对象那样，随手在任意并发上下文里直接改内部状态。
actor StudyProgressStore {
    private var finishedCount = 0

    func markFinished() {
        finishedCount += 1
    }

    func currentCount() -> Int {
        return finishedCount
    }

    func markFinishedAndLog() {
        markFinished()
        print("count: \(finishedCount)")
    }
}

// 这个 actor 故意写得“不够稳妥”。
// 虽然 seatsLeft 被关进了 actor 里，但 register() 中间跨过了 await。
// 这意味着：函数前半段检查过的状态，不保证在后半段继续成立。
actor UnsafeWorkshopCenter {
    private var seatsLeft = 1

    func register(name: String) async -> Bool {
        if seatsLeft <= 0 {
            print("\(name) rejected")
            return false
        }

        print("\(name) sees \(seatsLeft)")
        await pause(nanoseconds: 300_000_000)
        seatsLeft -= 1
        print("\(name) accepted \(seatsLeft)")
        return true
    }

    func currentSeatsLeft() -> Int {
        return seatsLeft
    }
}

// 这个版本把关键状态变更放进一个不跨等待点的动作里。
// 重点不是“actor 会自动修好一切”，而是：
// 你要主动把业务上必须保持一致的那一小段逻辑收拢起来。
actor SafeWorkshopCenter {
    private var seatsLeft = 1

    func register(name: String) -> Bool {
        if seatsLeft <= 0 {
            print("\(name) rejected")
            return false
        }

        seatsLeft -= 1
        print("\(name) accepted \(seatsLeft)")
        return true
    }

    func currentSeatsLeft() -> Int {
        return seatsLeft
    }
}

func runMinimalSyntaxDemo() async {
    // 最小模板：
    // 1. 创建 actor 实例
    // 2. 用 await 调用修改方法
    // 3. 再用 await 读取内部状态
    let store = MinimalCounterStore()
    await store.addOne()
    let value = await store.currentValue()
    print("value: \(value)")
}

func runBasicSyntaxDemo() async {
    // 最基础的 actor 使用路径：
    // 1. 创建实例
    // 2. 在 async 作用域里调用 actor 成员
    // 3. 需要结果时再通过 await 取回
    let store = StudyProgressStore()
    await store.markFinished()
    let count = await store.currentCount()
    print("count: \(count)")
}

func runInternalCallDemo() async {
    let store = StudyProgressStore()
    await store.markFinishedAndLog()
}

func runConcurrentAccessDemo() async {
    let store = StudyProgressStore()

    // 这里并发调用同一个 actor。
    // 观察重点不是“有没有并发”，而是最终 count 仍然稳定变成 2，
    // 说明这份状态没有像上一章的 class 那样被随手并发改坏。
    async let first: Void = store.markFinished()
    async let second: Void = store.markFinished()
    _ = await (first, second)

    let count = await store.currentCount()
    print("count: \(count)")
}

func runReentrancyDemo() async {
    let center = UnsafeWorkshopCenter()

    // 这里要观察 actor 的“重入”现象。
    // 当第一个 register() 执行到 await 暂停时，actor 可以先去处理第二个调用。
    // 所以“我前面检查过 seatsLeft > 0”并不代表后面回来时仍然安全。
    async let first = center.register(name: "小林")
    async let second = center.register(name: "小周")

    let firstResult = await first
    let secondResult = await second
    let seatsLeft = await center.currentSeatsLeft()

    print("results: 小林 \(firstResult), 小周 \(secondResult)")
    print("seatsLeft: \(seatsLeft)")
}

func runSafeWorkflowDemo() async {
    let center = SafeWorkshopCenter()

    // 对照上一段。
    // 这里把“检查还有没有名额”和“真正扣减名额”放在同一个不等待的动作里，
    // 因此这段关键业务逻辑不会在中途把执行权让出去。
    async let first = center.register(name: "小林")
    async let second = center.register(name: "小周")

    let firstResult = await first
    let secondResult = await second
    let seatsLeft = await center.currentSeatsLeft()

    print("results: 小林 \(firstResult), 小周 \(secondResult)")
    print("seatsLeft: \(seatsLeft)")
}

func startFromSyncPosition() {
    let store = StudyProgressStore()

    // 同步位置本身不能直接写 await，
    // 所以先进入一个 Task，再在异步上下文里访问 actor。
    Task {
        await store.markFinished()
        let count = await store.currentCount()
        print("count: \(count)")
    }
}

// 本章重点可以这样串起来看：
// 1. actor 的核心价值，是给共享可变状态建立边界，而不是自动提速。
// 2. 跨 actor 边界访问成员时，经常要写 await，
//    因为你是在请求这个边界替你完成一次受控访问。
// 3. actor 能避免“外部同时乱改内部状态”，
//    但它不会替你自动修正跨 await 的业务流程。
// 4. 只要一个 actor 方法中途 await，后半段就不能想当然地相信前半段看到的状态。
printDivider(title: "最小语法示例")
await runMinimalSyntaxDemo()

printDivider(title: "最基础的 actor 创建与调用")
await runBasicSyntaxDemo()

printDivider(title: "actor 内部继续调用自己的成员")
await runInternalCallDemo()

printDivider(title: "两个任务同时访问同一个 actor")
await runConcurrentAccessDemo()

printDivider(title: "actor 不是魔法锁：await 之后可能发生重入")
await runReentrancyDemo()

printDivider(title: "更稳妥的写法：把关键状态变更收在同一个动作里")
await runSafeWorkflowDemo()

printDivider(title: "同步位置也能先进入异步上下文")
startFromSyncPosition()
await pause(nanoseconds: 200_000_000)
