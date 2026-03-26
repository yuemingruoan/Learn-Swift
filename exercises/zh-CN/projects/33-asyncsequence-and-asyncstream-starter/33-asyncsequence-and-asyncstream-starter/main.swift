//
//  main.swift
//  33-asyncsequence-and-asyncstream-starter
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

// 这道题的目标不是只写出一个 AsyncStream，
// 而是把“数据怎样产生、怎样进入流、怎样结束、怎样被消费”整条链路接通。
//
// 请按 TODO 修改：
// 1. 在 makeEventStream(from:) 里把回调值传进 continuation.yield(...)。
// 2. 在生产完成时调用 continuation.finish()。
// 3. 在 onTermination 里清理 producer 的回调。
// 4. 在 consumeAllEvents(from:) 里用 for await 真正消费这条流。

final class StudyEventProducer: @unchecked Sendable {
    var onValue: ((String) -> Void)?
    var onFinish: (() -> Void)?

    func start() {
        Task {
            for value in ["开始准备资料", "正在整理重点", "生成完成"] {
                await pause(nanoseconds: 150_000_000)
                onValue?(value)
            }

            onFinish?()
        }
    }
}

func makeEventStream(from producer: StudyEventProducer) -> AsyncStream<String> {
    // TODO 1 到 TODO 3：
    // 当前版本只是返回一条立即结束的空流。
    // 请把 producer 的回调桥接到 AsyncStream。
    return AsyncStream { continuation in
        continuation.finish()
    }
}

func consumeAllEvents(from stream: AsyncStream<String>) async {
    // TODO 4：
    // 请改成：
    // for await value in stream { ... }
    print("TODO：请把这条流真正接到消费端。")
}

printDivider(title: "当前流程：从传出到消费")
let producer = StudyEventProducer()
let stream = makeEventStream(from: producer)
producer.start()
await consumeAllEvents(from: stream)
