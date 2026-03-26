//
//  main.swift
//  33-asyncsequence-and-asyncstream
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
    return AsyncStream { continuation in
        producer.onValue = { value in
            continuation.yield(value)
        }

        producer.onFinish = {
            continuation.finish()
        }

        continuation.onTermination = { _ in
            producer.onValue = nil
            producer.onFinish = nil
        }
    }
}

func consumeAllEvents(from stream: AsyncStream<String>) async {
    for await value in stream {
        print("event: \(value)")
    }

    print("stream ended")
}

printDivider(title: "完整流程：从传出到消费")
let producer = StudyEventProducer()
let stream = makeEventStream(from: producer)
producer.start()
await consumeAllEvents(from: stream)
