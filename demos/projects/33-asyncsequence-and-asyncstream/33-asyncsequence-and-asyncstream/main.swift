//
//  main.swift
//  33-asyncsequence-and-asyncstream
//
//  Created by Codex on 2026/3/26.
//

final class StudyEventEmitter: @unchecked Sendable {
    var onEvent: ((String) -> Void)?

    func emit(_ value: String) {
        onEvent?(value)
    }
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

func makeMinimalSyntaxStream() -> AsyncStream<String> {
    // 这是本章最小的异步序列模板。
    // 重点只有两部分：
    // 1. 用 AsyncStream 构造一条流
    // 2. 用 yield 逐个送出值，最后 finish()
    return AsyncStream { continuation in
        continuation.yield("A")
        continuation.yield("B")
        continuation.finish()
    }
}

// 这条流是“立即就能产出所有值”的最小示例。
// 它适合先帮助读者建立最基础的 for await 语法感觉。
func makeStatusStream() -> AsyncStream<String> {
    return AsyncStream { continuation in
        continuation.yield("开始")
        continuation.yield("进行中")
        continuation.yield("完成")
        continuation.finish()
    }
}

// 这条流故意把每个值之间插入等待，
// 用来强调 AsyncSequence 和普通数组的差别：
// 下一个元素不是现在就已经摆在那里，而是可能稍后才到。
func makeProgressStream() -> AsyncStream<Int> {
    return AsyncStream { continuation in
        Task {
            for value in [10, 40, 70, 100] {
                await pause(nanoseconds: 200_000_000)
                continuation.yield(value)
            }
            continuation.finish()
        }
    }
}

// 这里演示 AsyncStream 的另一个重要用途：
// 把“外部不断触发回调”的模型，整理成一条可以 for await 消费的异步流。
// onTermination 里把回调清掉，是为了在流结束后释放这层连接关系。
func makeEventStream(from emitter: StudyEventEmitter) -> AsyncStream<String> {
    return AsyncStream { continuation in
        emitter.onEvent = { value in
            continuation.yield(value)

            if value == "完成" {
                continuation.finish()
            }
        }

        continuation.onTermination = { _ in
            emitter.onEvent = nil
        }
    }
}

func runMinimalSyntaxDemo() async {
    // 消费端的最小模板也一起放在这里：
    // for await 会逐项等待流里的下一个元素。
    for await value in makeMinimalSyntaxStream() {
        print("value: \(value)")
    }
}

// 本章重点可以从“结果模型”来理解：
// 1. 普通 async 函数常常在最后返回一个结果。
// 2. AsyncSequence 表达的是：结果会随着时间推进，一项一项到达。
// 3. for await 不是只等待一次，而是每次取下一个元素时都可能等待。
// 4. AsyncStream 是入门阶段最实用的桥梁工具，
//    它可以把手动 yield 的值，或者回调式事件，整理成统一的异步流接口。
printDivider(title: "最小语法示例")
await runMinimalSyntaxDemo()

printDivider(title: "for await：逐项消费异步序列")
for await status in makeStatusStream() {
    print("status: \(status)")
}

printDivider(title: "AsyncStream：值可以陆续到达")
for await progress in makeProgressStream() {
    print("progress: \(progress)%")
}

printDivider(title: "把回调式事件整理成异步流")
let emitter = StudyEventEmitter()
let eventStream = makeEventStream(from: emitter)

Task {
    // 这里模拟一个“不断推送事件”的外部世界。
    // 消费方不需要知道事件是如何产生的，只需要 for await 按顺序接收即可。
    await pause(nanoseconds: 150_000_000)
    emitter.emit("收到第一条消息")
    await pause(nanoseconds: 150_000_000)
    emitter.emit("收到第二条消息")
    await pause(nanoseconds: 150_000_000)
    emitter.emit("完成")
}

for await event in eventStream {
    print("event: \(event)")
}
