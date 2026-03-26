# 32. 结构化并发：async let、TaskGroup 与父子任务

## 阅读导航

- 前置章节：[29. 并发入门：async/await 与 Task](./29-concurrency-basics-async-await-and-task.md)、[30. 并发中的共享状态：当多个任务同时改数据时会发生什么](./30-concurrency-shared-state.md)、[31. Actor：隔离共享可变状态](./31-actor-state-isolation.md)
- 上一章：[31. Actor：隔离共享可变状态](./31-actor-state-isolation.md)
- 建议下一章：[33. 异步序列：AsyncSequence 与 AsyncStream](./33-asyncsequence-and-asyncstream.md)
- 下一章：[33. 异步序列：AsyncSequence 与 AsyncStream](./33-asyncsequence-and-asyncstream.md)
- 适合谁先读：已经理解 `Task`、共享状态和 actor，准备进一步学习“多个异步子任务怎样组织得更清楚”的读者

## 本章目标

学完这一章后，你应该能够：

- 理解什么叫结构化并发，以及它为什么重要
- 看懂 `async let` 的最基础写法
- 理解 `TaskGroup` 适合处理“子任务数量不固定”的场景
- 理解父任务、子任务、取消传播和错误传播的基本关系
- 区分 `Task { ... }`、`async let` 和 `TaskGroup` 各自更适合的使用边界
- 知道为什么不是所有异步并发都该手写一堆裸 `Task`

## 本章对应目录

- 对应项目目录：`demos/projects/32-structured-concurrency`
- 练习起始工程：`exercises/zh-CN/projects/32-structured-concurrency-starter`
- 练习答案文稿：`exercises/zh-CN/answers/32-structured-concurrency.md`
- 练习参考工程：`exercises/zh-CN/answers/32-structured-concurrency`

建议你这样使用：

- 先把本章当成“并发组织方式升级”来读，而不是背三套新语法
- 阅读时优先关注：谁是谁的父任务、结果在哪里汇总、取消和错误会沿哪条边传播
- 如果你上一章学 actor 时更关注“状态边界”，这一章则更适合把注意力转到“任务边界”

你可以这样配合使用：

- `demos/projects/32-structured-concurrency`：先看 `async let`、`TaskGroup` 和 `withThrowingTaskGroup` 的最小模板。
- `exercises/zh-CN/projects/32-structured-concurrency-starter`：再把固定数量、动态数量和错误路径分别整理回父流程。
- `exercises/zh-CN/answers/32-structured-concurrency.md`：做完后对照每一类任务边界为什么这样选。
- `exercises/zh-CN/answers/32-structured-concurrency`：最后运行参考工程，观察输出顺序和错误回传路径。

## 先看本章最常见的通用语法

这一章很容易一上来就陷进概念里，所以更稳妥的顺序通常是：先把三种最常见代码模板认出来，再去理解父子任务、错误传播和取消传播。

### 1. `async let`：固定数量的并发子任务

```swift
async let tasks = loadTaskTitles()
async let reminder = loadReminderText()

let titles = await tasks
let text = await reminder
```

### 2. `withTaskGroup`：动态添加子任务

```swift
let results = await withTaskGroup(of: String.self, returning: [String].self) { group in
    for title in chapterTitles {
        group.addTask {
            await loadChapterSummary(title)
        }
    }

    var summaries: [String] = []
    for await summary in group {
        summaries.append(summary)
    }
    return summaries
}
```

### 3. `withThrowingTaskGroup`：子任务可能失败

```swift
let results = try await withThrowingTaskGroup(of: String.self, returning: [String].self) { group in
    for title in chapterTitles {
        group.addTask {
            try await loadChapterSummary(title)
        }
    }

    var summaries: [String] = []
    for try await summary in group {
        summaries.append(summary)
    }
    return summaries
}
```

### 4. 顺序等待的对照写法

```swift
let tasks = await loadTaskTitles()
let reminder = await loadReminderText()
```

这一章真正要帮你分清的，基本就是下面这几类边界：

- 固定数量时，什么时候更像 `async let`
- 数量动态时，什么时候更像 `TaskGroup`
- 只是顺着流程往下走时，什么时候其实只该直接 `await`

## 在 actor 之后学习结构化并发

前面两章你已经分别看到：

- 并发里最危险的是共享可变状态
- actor 可以把共享状态关进更清楚的边界

这时很自然会出现另一个问题：

- 如果我现在要同时做三件、五件、十件异步工作，应该怎样组织它们

很多初学者学到 `Task { ... }` 之后，会自然进入一个阶段：

- 只要想并发，就先包一层 `Task`

这条路有时能跑，但很快就会变乱。因为你会开始不清楚：

- 这些任务是谁创建的
- 谁负责等待它们
- 如果父流程失败了，子任务该怎么办
- 如果外部取消了，内部任务会不会跟着停

这就是结构化并发要解决的问题。

## 先说结论：不是所有并发都该手写裸 `Task`

`Task { ... }` 很重要，但它不是并发世界里唯一的组织方式。

当前阶段更值得建立的认识是：

- 如果这些子任务本来就属于同一个上层异步流程，那么最好把它们组织在这个流程的结构里面

这就是“结构化并发”最值得先抓住的直觉：

- 子任务不是到处漂着的
- 它们应当和父流程有清楚的归属关系

也就是说，当前阶段不要把“会并发”理解成：

- 能够随手到处起任务

更稳妥的理解应该是：

- 能把这些任务的生命周期、等待点、错误路径和取消路径组织清楚

## 什么叫结构化并发

当前阶段可以先把结构化并发近似理解成：

- 异步子任务不是散落在系统各处
- 而是被放进一个明确的父任务结构里管理

这意味着：

- 子任务从哪里启动，更清楚
- 结果在哪里汇总，更清楚
- 如果父任务取消了，子任务通常也该跟着受影响
- 如果某个子任务失败了，错误也更容易沿结构往上返回

你可以把它理解成：

- 不是“临时叫来一堆人干活”
- 而是“把这批工作纳入同一个项目结构里管理”

## `async let`：适合少量、固定数量的并发子任务

先看最基础的外形：

```swift
async let tasks = loadTaskTitles()
async let reminder = loadReminderText()

let titles = await tasks
let text = await reminder
```

这里的重点不是语法像不像局部变量，而是：

- 这两个异步子任务都属于当前这个父异步流程
- 它们会在后面被显式等待

`async let` 特别适合的场景通常是：

- 子任务数量比较少
- 数量在代码里是固定的
- 每一项任务都比较明确

例如：

- 同时加载任务列表和提醒文本
- 同时读取标题、摘要和统计信息

## `async let` 和顺序 `await` 的差别

这也是最需要建立直觉的一点。

顺序写法通常是：

```swift
let tasks = await loadTaskTitles()
let reminder = await loadReminderText()
```

这种写法表达的是：

- 先等第一项完成
- 再开始第二项

而 `async let` 更接近：

```swift
async let tasks = loadTaskTitles()
async let reminder = loadReminderText()

let titles = await tasks
let text = await reminder
```

它表达的是：

- 先把两个子任务都发出去
- 稍后再等它们各自结果

所以当前阶段最值得你先抓住的不是语法差别，而是：

- **顺序 `await` 在表达串行推进**
- **`async let` 在表达同属一个父流程的并发子任务**

## 什么时候更适合 `async let`

一个很实用的判断顺序通常是：

1. 这些任务彼此独立吗
2. 它们数量固定吗
3. 它们都属于当前函数的工作吗

如果答案都越来越偏向“是”，那么 `async let` 往往就很自然。

例如：

- 加载任务列表
- 加载提醒文本
- 加载今日统计

这三件事彼此独立，而且数量固定，就很适合 `async let`。

## `TaskGroup`：适合子任务数量不固定的情况

但很多时候，子任务数量并不是写死的。

例如：

- 一共有多少个章节，要根据输入数组决定
- 一共有多少份报告，要根据目录扫描结果决定
- 一共有多少个用户要处理，要根据请求结果决定

这时继续用 `async let` 就不自然了，因为：

- 你没有固定数量的声明位置

这时更适合的工具通常是 `TaskGroup`。

最基础的外形如下：

```swift
let results = await withTaskGroup(of: String.self, returning: [String].self) { group in
    for title in chapterTitles {
        group.addTask {
            await loadChapterSummary(title)
        }
    }

    var summaries: [String] = []
    for await summary in group {
        summaries.append(summary)
    }
    return summaries
}
```

当前阶段先不要急着记全签名，先抓住三件事：

- `group.addTask` 用来不断加入子任务
- 子任务数量可以根据运行时数据决定
- 结果可以在 group 中逐步收集

## 为什么 `TaskGroup` 比“自己先建一堆 Task 放数组里”更稳

很多初学者的第一反应可能是：

- 那我自己用数组存一堆 `Task` 不也能做吗

有时候当然也能跑，但结构化并发更想给你的，不只是“能跑”，而是：

- 更清楚的父子归属
- 更统一的等待路径
- 更自然的取消和错误传播

也就是说，`TaskGroup` 的价值不只在“可以动态起任务”，还在：

- 它让这些任务明确属于当前这个父异步流程

这会比“到处散落一堆 Task 对象”更容易维护。

## 错误传播为什么会更清楚

结构化并发的另一个核心价值，是错误路径更清楚。

例如在 `withThrowingTaskGroup` 里，如果某个子任务抛错，当前阶段你可以先建立这样一个直觉：

- 这个错误不是飘在系统里某个角落
- 它会沿着当前这条父任务结构往上返回

这和前面你学过的 `throws` / `try await` 是一条主线。

也就是说，结构化并发并不是把错误路径搞得更模糊，反而通常会让它更好追踪。

## 取消传播为什么也更自然

你在 29 章已经学过：

- `cancel()` 更像取消信号
- 任务内部仍然要在关键位置响应取消

到了结构化并发这里，又会多一层重要认识：

- 如果这些子任务本来就属于同一个父流程，那么取消也应当更自然地沿这个结构传播

这正是父子任务关系非常重要的原因之一。

如果你的任务结构是散的，那么你就更容易遇到下面这种混乱：

- 父流程已经不需要结果了
- 某些子任务却还在远处继续跑

而结构化并发恰恰是在帮助你减少这类“任务漂着不收口”的情况。

## `Task { ... }`、`async let`、`TaskGroup` 该怎么分工

这是本章最值得反复确认的判断题。

### `Task { ... }` 更适合：

- 从同步位置启动一段异步工作
- 需要一个独立任务句柄
- 这段工作不只是当前函数里的局部子步骤

### `async let` 更适合：

- 少量、固定数量的子任务
- 都属于当前父异步函数
- 稍后会在当前作用域内统一等待结果

### `TaskGroup` 更适合：

- 子任务数量不固定
- 需要循环创建子任务
- 需要逐步收集多个子任务结果

当前阶段只要把这三者的分工大致分清，就已经很够用了。

## 一个常见错误：已经在 async 函数里，还到处包 `Task`

这和 29 章的边界是一脉相承的。

很多时候你已经在异步函数里，真正需要的只是：

- 继续 `await`
- 或者用 `async let`
- 或者用 `TaskGroup`

如果这时还把每一步都额外包成 `Task`，就容易让代码出现几个问题：

- 父子关系不清楚
- 等待点分散
- 错误路径不清楚
- 取消传播不自然

所以本章一个很重要的目标，不是教你“起更多任务”，而是教你：

- **怎样让任务关系更清楚**

## 一个很实用的判断顺序

当你想把多段异步工作并发起来时，可以先按下面顺序判断：

1. 这些工作是不是都属于当前函数的一部分
2. 它们是不是彼此独立
3. 数量是不是固定
4. 是否需要动态添加子任务

然后再选择：

- 固定少量：优先想 `async let`
- 数量动态：优先想 `TaskGroup`
- 真的是独立任务入口：再考虑 `Task { ... }`

这个顺序会比“先想语法名词”稳得多。

## 常见误区

### 1. 以为只要想并发，就先手写一堆 `Task`

不是。

很多子任务本来就属于当前父异步流程，更适合结构化并发。

### 2. 以为 `async let` 只是 `Task` 的简写糖

不只是。

它表达的是固定数量、隶属于当前作用域的子任务结构。

### 3. 以为 `TaskGroup` 只是“for 循环里起任务”的工具

不只是。

它还在表达父子任务关系，以及结果、错误和取消的收口方式。

### 4. 以为结构化并发只是在优化性能

不是。

它同样在优化代码组织、生命周期边界和错误路径。

### 5. 以为父任务取消后，子任务一定会像强制断电一样立刻停下

不是。

取消仍然需要子任务在合适位置响应，但结构化关系会让这件事更自然。

## 本章小结

这一章最需要记住的是下面这组关系：

- 结构化并发强调的是：子任务应当属于明确的父流程结构
- `async let` 适合少量、固定数量的并发子任务
- `TaskGroup` 适合数量不固定、需要动态创建的子任务
- 裸 `Task` 很重要，但不应该成为所有并发组织的默认答案
- 结构化并发的价值不只是并发启动，还包括更清楚的等待、错误传播和取消传播
- 真正该学会的不是“起更多任务”，而是“把任务关系组织清楚”

如果你现在已经开始能稳定地区分下面这些场景：

- 这里应该直接 `await`
- 这里更适合 `async let`
- 这里更适合 `TaskGroup`
- 这里只有在任务入口层才需要 `Task { ... }`

那么这一章最重要的目标就已经达到了。

## 接下来怎么读

下一章建议继续阅读：

- [33. 异步序列：AsyncSequence 与 AsyncStream](./33-asyncsequence-and-asyncstream.md)

因为当你已经理解：

- 一次性异步结果该怎么组织
- 多个子任务该怎样放回父流程结构里

接下来一个很自然的问题就是：

- 如果异步结果不是“一次返回一个最终值”，而是会持续不断地产生一串值，该怎么组织
