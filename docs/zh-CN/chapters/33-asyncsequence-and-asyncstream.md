# 33. 异步序列：AsyncSequence 与 AsyncStream

## 阅读导航

- 前置章节：[14. 数组与字典：列表与键值对](./14-arrays-and-dictionaries.md)、[25. 闭包：把函数当成值来传递](./25-closures-functions-as-values.md)、[29. 并发入门：async/await 与 Task](./29-concurrency-basics-async-await-and-task.md)、[32. 结构化并发：async let、TaskGroup 与父子任务](./32-structured-concurrency.md)
- 上一章：[32. 结构化并发：async let、TaskGroup 与父子任务](./32-structured-concurrency.md)
- 建议下一章：34. JSON 格式与解析
- 下一章：34. JSON 格式与解析
- 适合谁先读：已经理解一次性异步结果和结构化并发，准备学习“异步地持续收到一串值”该怎么表达的读者

## 本章目标

学完这一章后，你应该能够：

- 理解为什么有些异步工作不是返回一个值，而是持续产生多个值
- 看懂 `AsyncSequence` 和 `for await` 的最基础写法
- 理解 `AsyncSequence` 和普通 `Sequence` 的关键差别
- 看懂 `AsyncStream` 最基础的构造方式
- 理解如何把“回调不断推送结果”的模型，整理成异步序列
- 对异步流的结束、取消和消费边界建立初步直觉

## 本章对应目录

- 对应项目目录：`demos/projects/33-asyncsequence-and-asyncstream`
- 练习起始工程：`exercises/zh-CN/projects/33-asyncsequence-and-asyncstream-starter`
- 练习答案文稿：`exercises/zh-CN/answers/33-asyncsequence-and-asyncstream.md`
- 练习参考工程：`exercises/zh-CN/answers/33-asyncsequence-and-asyncstream`

建议你这样使用：

- 先把本章当成“异步结果模型扩展”来读，而不是只把它看成一个新协议
- 阅读时优先关注：这些值是一口气返回，还是会陆续到达
- 如果你之前已经习惯“函数返回一个最终结果”，这一章最重要的是建立“结果也可能是一条流”的直觉

你可以这样配合使用：

- `demos/projects/33-asyncsequence-and-asyncstream`：先建立 `AsyncStream` 和 `for await` 的最小语法直觉。
- `exercises/zh-CN/projects/33-asyncsequence-and-asyncstream-starter`：再把“回调生产数据”完整接成“异步流消费数据”。
- `exercises/zh-CN/answers/33-asyncsequence-and-asyncstream.md`：做完后对照生产、结束、清理和消费分别落在哪里。
- `exercises/zh-CN/answers/33-asyncsequence-and-asyncstream`：最后运行参考工程，观察整条数据流怎样被接通。

## 先看本章最常见的通用语法

这一章如果先不看模板，很容易只记住“异步流”这个概念词，却不知道代码到底长什么样。因此我们先来认识下面四种外形。

### 1. 用 `for await` 消费异步序列

```swift
for await value in sequence {
    print(value)
}
```

### 2. 如果元素可能抛错，用 `for try await`

```swift
for try await value in sequence {
    print(value)
}
```

### 3. 用 `AsyncStream` 构造一条最基础的异步流

```swift
let stream = AsyncStream<Int> { continuation in
    continuation.yield(10)
    continuation.yield(50)
    continuation.yield(100)
    continuation.finish()
}
```

### 4. 一边构造，一边消费

```swift
let stream = AsyncStream<String> { continuation in
    continuation.yield("开始")
    continuation.yield("进行中")
    continuation.yield("完成")
    continuation.finish()
}

for await status in stream {
    print(status)
}
```

如果你先熟悉这几种模板，后面再去理解：

- 为什么有些异步工作更像“一个最终值”
- 为什么有些异步工作更像“一串陆续到来的值”

就不会那么抽象。

## 为什么在结构化并发之后学习异步序列

前面几章你已经逐步建立了下面这些认识：

- `async/await` 用来表达“这里会等待”
- actor 用来隔离共享状态
- `async let` 和 `TaskGroup` 用来组织多个子任务

但这里面其实默认了一个前提：

- 每段异步工作最终都会给你一个结果

例如：

- 返回一组任务标题
- 返回一条提醒文本
- 返回一份完整报告

可实际项目里，还有一大类异步工作并不是“一次返回一个最终值”，而是：

- **随着时间推进，陆续产生一串值**

例如：

- 下载进度不断更新
- 学习计时器每秒推送一次剩余时间
- 日志事件持续流入
- 一条连接不断产生新消息

这时如果你还只用“返回一个值”的模型去理解代码，就会越来越别扭。

所以这一章要解决的问题是：

- **当异步结果本身是一条流时，Swift 怎样表达它**

## 先说结论：不是所有异步工作都应该返回一个最终值

这是本章最值得先建立的认识。

很多初学者一学完 `async` 函数，就容易把异步想成：

- 等一会儿
- 然后拿到一个值

这当然是常见场景，但不是全部。

有些工作更像：

- 结果会一批一批来
- 进度会一条一条来
- 事件会不断发生

所以你要开始建立第二种异步心智：

- **异步不仅可以返回一个值，也可以返回一串陆续到达的值**

## 什么是 `AsyncSequence`

当前阶段可以先把 `AsyncSequence` 近似理解成：

- 一个“异步版本的序列”

普通 `Sequence` 的直觉你已经很熟了：

- 里面有很多元素
- 你可以一个一个取

例如：

```swift
let titles = ["闭包", "并发", "Actor"]

for title in titles {
    print(title)
}
```

而 `AsyncSequence` 的区别在于：

- 下一个元素不一定立刻就到
- 你可能要等一下，才会拿到下一项

所以它最自然的消费方式会变成：

```swift
for await value in sequence {
    print(value)
}
```

这里最关键的新点不是 `for`，而是：

- `await` 被放进了逐项消费的循环里

这说明：

- 不是只在函数调用时等一次
- 而是**每取下一项，都可能需要等待**

## `Sequence` 和 `AsyncSequence` 的区别到底在哪

当前阶段最实用的区分方式是下面这一条：

- 普通 `Sequence`：下一个元素现在就能给你
- `AsyncSequence`：下一个元素可能还没来，要等

例如：

- 数组里的第 3 个元素已经在那里
- 但网络消息流的下一条消息，现在还没到

所以这一章不要把 `AsyncSequence` 理解成“数组加个 async 关键字”。它真正对应的是：

- **数据是陆续出现的**

## `for await`：最基础的消费方式

最常见的入门外形如下：

```swift
for await progress in downloadProgressStream {
    print("当前进度：\(progress)%")
}
```

当前阶段最值得观察的是：

- 循环本身没有变成完全陌生的新东西
- 只是每次取下一项时，显式承认“这里可能会等”

这和你之前学过的 `await` 主线是一致的。

也就是说，`for await` 不是突然冒出来的新结构，它只是把：

- “等待下一项结果”

这件事显式写进了循环结构里。

## 一个很直观的场景：进度更新为什么更像流

假设你要导出一份学习报告。

如果你只关心最终文件内容，那么函数返回一个最终 `String` 或 `[String]` 就够了。

但如果你还希望在导出过程中持续看到：

- 10%
- 30%
- 60%
- 100%

那这个过程就已经不再像“一次返回一个值”。

它更像：

- 异步地持续发出多个进度事件

这正是 `AsyncSequence` 适合介入的地方。

## `AsyncStream`：手动构造一条异步流

讲到这里，一个自然问题就是：

- 如果系统 API 还没直接给我 `AsyncSequence`，我自己能不能造一条流

Swift 提供了一个很重要的入门工具：

- `AsyncStream`

最基础的外形如下：

```swift
let stream = AsyncStream<Int> { continuation in
    continuation.yield(10)
    continuation.yield(50)
    continuation.yield(100)
    continuation.finish()
}
```

当前阶段先抓住三个动作就够了：

- `yield(...)`：往流里送出一个新值
- 可以 `yield` 多次：说明它不是只能给一个结果
- `finish()`：说明这条流结束了

这会帮助你建立一个非常重要的概念：

- 生产者可以不断推值
- 消费者可以异步地一条条拿值

## 为什么开发中常用 `AsyncStream` 承接回调式事件

在前面我们已经学过闭包，也学过回调捕获关系。

实际项目里经常会遇到一种模型：

- 某个系统或对象每次有新结果，就调一次回调

例如：

- 下载进度回调
- 新消息到达回调
- 传感器数据变化回调

如果你已经对 `async/await` 这类异步操作的使用足够熟悉，那么一个很自然的重构方向就是：

- 能不能把这种“不断触发回调”的模型，整理成一条异步序列

这正是 `AsyncStream` 很常见的用途之一。

它在我们当前阶段最重要的价值是：

- 把“事件不断推来”的回调模型
- 整理成“通过 `for await` 消费”的流模型

## 流操作中的结束和取消

一次性异步结果通常只要关心：

- 结果到了没有
- 失败了没有

但流不一样。因为它会持续存在一段时间，所以你还要多关心两件事：

- 这条流什么时候结束
- 我什么时候不想继续收了

所以在异步序列里，结束和取消会变得更重要。

例如：

- 下载完成后，进度流应该结束
- 用户离开页面后，某些实时更新流应该停止消费

这也是为什么 `AsyncStream` 会有：

- `finish()`

因为流不仅要会“产出值”，还要会“正确收口”。

## 异步流和数组的区别，最容易混在哪里

这是一个特别容易混的点。

例如下面两者看起来都像“很多值”：

- `[1, 2, 3, 4]`
- 一条会陆续发出 `1、2、3、4` 的异步流

但它们的本质不同。

数组更像：

- 四个值现在已经全放在那了

异步流更像：

- 第一个值先来
- 第二个值过一会儿才来
- 后面的值什么时候来，取决于外部事件推进

所以当前阶段千万不要把 `AsyncSequence` 想成“晚一点给你的数组”。它更像：

- **随时间到来的值序列**

## 什么时候不用 `AsyncSequence` 反而更好

为了避免把它学成"万能工具"，这一点也需要讲清楚。

如果你的结果是：

- 只返回一次
- 不会持续更新
- 没有必要边生成边消费

那么普通的 `async -> Result` 写法通常更直接。

例如：

- 加载一份完整配置
- 读取一份完整报告
- 获取一次用户资料

这些场景如果硬改成异步流，反而会让模型更绕。

所以和前几章一样，本章最重要的不是“学会一个新工具后到处套”，而是：

- **知道它真正适合什么场景**

## 一个很实用的判断顺序

当你拿不准该用“一次性异步结果”还是“异步流”时，可以先问下面三个问题：

1. 这个异步操作最终只给一个结果，还是会陆续给很多结果
2. 消费方是否需要边收到边处理
3. 这批结果是否天然带有时间顺序

如果答案偏向：

- 会连续产生
- 边到边处理
- 顺序与时间推进有关

那就需要开始考虑使用 `AsyncSequence` 了。

## 常见误区

### 1. 以为所有异步工作都应该建模成一个 `async` 函数返回值

不是。

持续到来的结果更适合用异步序列表达。

### 2. 以为 `AsyncSequence` 就是数组的异步版

不够准确。

它真正强调的是“下一项可能还没到，需要等待”。

### 3. 以为 `for await` 只是语法更长的 `for-in`

不是。

它在表达逐项等待下一条异步结果。

### 4. 以为 `AsyncStream` 只能用在很底层的框架代码里

不是。

只要你需要把持续回调整理成更清楚的异步消费模型，它就很有价值。

### 5. 以为只要能不断 `yield`，就不必关心流的结束

不是。

流的结束和取消边界同样是模型的一部分。

## 本章练习与课后作业

如果你想把这一章的内容真正落实到“把回调式持续事件整理成异步流”上，可以继续完成下面这道桥接作业：

- 作业答案：`exercises/zh-CN/answers/33-asyncsequence-and-asyncstream.md`
- 起始工程：`exercises/zh-CN/projects/33-asyncsequence-and-asyncstream-starter`
- 参考答案工程：`exercises/zh-CN/answers/33-asyncsequence-and-asyncstream`

starter project 当前已经有一个会持续推送事件的生产者，但整条链路还没有接通。

请你按下面这些明确目标完成修改：

1. 在 `makeEventStream(from:)` 里把 `producer.onValue` 接到 `continuation.yield(...)`。
2. 在 `producer.onFinish` 里调用 `continuation.finish()`。
3. 在 `continuation.onTermination` 里清理回调。
4. 在 `consumeAllEvents(from:)` 里用 `for await` 逐项消费这条流。

完成后，你的代码至少应该表现出下面这些结果：

- 生产者发出的每一条事件都会进入 `AsyncStream`。
- 生产完成后，流会正常结束。
- 消费端会逐条打印事件，而不是一次性拿到全部结果。
- 流结束后，生产者身上的回调不会继续残留。

## 本章小结

这一章最需要记住的是下面这组关系：

- 异步结果不一定只会返回一次，也可能是一串陆续到达的值
- `AsyncSequence` 适合表达“逐项异步到来”的结果流
- `for await` 用来一项项等待并消费这些异步结果
- `AsyncStream` 可以帮助你手动构造一条异步流
- 回调式持续事件，很适合逐步整理成异步序列模型
- 流不只要能产出值，还要考虑结束和取消边界

如果你现在已经开始能稳定地区分下面两类模型：

- “等一下，拿到一个最终结果”
- “等一下，拿到一个结果，再等一下，陆续拿到一串结果”

并且开始知道为什么第二类更适合 `AsyncSequence`，那么这一章最重要的目标就已经达到了。

## 接下来怎么读

如果继续沿这条主线往下走，下一步很自然会进入：

- 34. JSON 格式与解析

因为当你已经理解：

- 一次性异步结果
- 结构化并发
- 持续到来的异步事件流

接下来一个很现实的问题就是：

- 怎样先把真实数据格式本身看懂，再把它接到网络和实际应用数据上
