# 33. 异步序列：AsyncSequence 与 AsyncStream 练习答案

对应章节：

- [33. 异步序列：AsyncSequence 与 AsyncStream](../../../docs/zh-CN/chapters/33-asyncsequence-and-asyncstream.md)

如果你想一边看答案一边运行 starter project，可以打开：

- `exercises/zh-CN/projects/33-asyncsequence-and-asyncstream-starter`

如果你想直接运行本章练习的参考工程，也可以打开：

- `exercises/zh-CN/answers/33-asyncsequence-and-asyncstream`

说明：

- 这道题不是只让你“会写一个 `AsyncStream` 壳子”。
- starter project 里已经有一个能不断推送数据的生产者。
- 你要做的是把生产、传入流、结束、清理、消费整条链路真正接通。

## 当前问题

starter project 里主要有三类问题：

1. `makeEventStream(from:)` 现在返回的是一条立刻结束的空流。
2. 生产者发出的值没有真正进入异步序列。
3. 消费端也还没有用 `for await` 逐项读取这些值。

## 你需要完成的修改

1. 在 `makeEventStream(from:)` 里把 `producer.onValue` 接到 `continuation.yield(...)`。
2. 在 `producer.onFinish` 里调用 `continuation.finish()`。
3. 在 `continuation.onTermination` 里清理回调。
4. 在 `consumeAllEvents(from:)` 里用 `for await` 消费整条流。

## 完成标准

完成后，你的代码至少应该表现出下面这些特征：

- 生产者发出的每一条事件都会进入 `AsyncStream`。
- 生产完成后，流会正常结束。
- 消费端会逐条打印事件，而不是一次性拿到全部结果。
- 流结束后，生产者身上的回调不会继续残留。

## 参考重构方向

这一题比较典型的桥接写法接近下面这样：

```swift
func makeEventStream(from producer: StudyEventProducer) -> AsyncStream<String> {
    AsyncStream { continuation in
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
```

而消费端则接近：

```swift
func consumeAllEvents(from stream: AsyncStream<String>) async {
    for await value in stream {
        print("event: \(value)")
    }
}
```

## 为什么 `onTermination` 也要处理

这是这道题里很容易被忽略的一点。

很多初学者会完成前两步：

- 会 `yield`
- 会 `finish`

但如果不处理 `onTermination`，就容易留下一个问题：

- 流已经结束了
- 生产者却还保留着旧回调

所以这题不是只让你把值送进去，而是让你把“开始连接”和“结束连接”都写完整。

## 参考工程说明

如果你想直接运行参考实现，可以打开：

- `exercises/zh-CN/answers/33-asyncsequence-and-asyncstream`

你最应该重点观察的是：

- 事件怎样从生产者回调进入流
- 流怎样被 `for await` 逐项消费
- 生产完成后，消费端为什么会自然结束
