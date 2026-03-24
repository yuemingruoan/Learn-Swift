# 29. 并发入门：async/await 与 Task

## 阅读导航

- 前置章节：[23. 错误处理：让失败路径更清楚](./23-error-handling-clear-failure-paths.md)、[25. 闭包：把函数当成值来传递](./25-closures-functions-as-values.md)、[28. 选读：ARC 进阶：weak、unowned 与循环引用](./28-arc-advanced-weak-unowned-and-capture-lists.md)
- 上一章：[28. 选读：ARC 进阶：weak、unowned 与循环引用](./28-arc-advanced-weak-unowned-and-capture-lists.md)
- 建议下一章：30. 并发中的共享状态：当多个任务同时改数据时会发生什么（待补充）
- 下一章：30. 并发中的共享状态：当多个任务同时改数据时会发生什么（待补充）
- 适合谁先读：已经理解函数、错误处理、闭包捕获和对象生命周期，并且想开始读懂异步代码的读者

## 本章目标

学完这一章后，你应该能够：

- 理解 `async` 和 `await` 在解决什么问题
- 知道“挂起”和“阻塞”不是一回事
- 看懂最基础的 `async` 函数声明
- 在调用点正确使用 `await`
- 看懂 `try await` 这种把失败路径和异步等待放在一起的写法
- 使用 `Task` 启动最基础的异步任务
- 知道什么时候该继续沿着 `async` 往下传，什么时候才需要 `Task`
- 对异步代码里的取消、闭包捕获和对象生命周期建立初步直觉

## 本章对应目录

- 对应项目目录：`demos/projects/29-concurrency-basics-async-await-and-task`
- 练习起始工程：`exercises/zh-CN/projects/29-concurrency-basics-async-await-and-task-starter`
- 练习答案文稿：`exercises/zh-CN/answers/29-concurrency-basics-async-await-and-task.md`
- 练习参考工程：`exercises/zh-CN/answers/29-concurrency-basics-async-await-and-task`

建议你这样使用：

- 先把本章当成“理解等待点和任务边界”的入门章来读，而不是一上来就追底层调度细节
- 阅读时优先盯住三件事：哪里启动了异步工作、哪里显式等待结果、哪里真正响应了取消
- 如果你第一次读到 `Task` 和 `task.value` 觉得绕，建议一边运行 demo，一边对照正文里的“顺序等待”和“先启动，再等待”

你可以这样配合使用：

- `demos/projects/29-concurrency-basics-async-await-and-task`：先看“整理好的异步看板示例”，建立 `await`、`Task`、`task.value` 和取消的直觉。
- `exercises/zh-CN/projects/29-concurrency-basics-async-await-and-task-starter`：再打开“功能完整但异步组织很乱”的版本，自己判断哪些地方只是应该继续 `await`，哪些地方才该新建 `Task`。
- `exercises/zh-CN/answers/29-concurrency-basics-async-await-and-task.md`：做完后对照每一处重构为什么这样改。
- `exercises/zh-CN/answers/29-concurrency-basics-async-await-and-task`：最后运行参考答案工程，观察并发启动和取消生效后的输出差别。

导读建议：

- 先看 demo 里的“最小 async 函数和 await”，把“调用点显式等待”这件事建立成稳定直觉。
- 再看“顺序等待”和“先启动，再等待”，对照观察为什么 `Task { ... }` 和 `task.value` 会把等待组织成两个阶段。
- 接着看“完整功能：异步学习看板”，把前面的最小片段重新放回一个更完整的流程里。
- 最后看“取消会真正影响流程”，对应正文里 `Task.checkCancellation()` 的小节，确认 cancel 为什么不是强制断电。

本章当前已经补齐了正文、demo 和练习起始工程，所以你现在阅读时可以先把重点放在：

- `async` 函数到底在表达什么
- 为什么调用点要显式写 `await`
- `Task` 到底是在什么时候出现的
- 异步任务和前面学过的闭包捕获、对象生命周期有什么联系

## 为什么现在适合学习并发

前面你已经学过：

- 函数负责封装一段可复用流程
- 闭包可以把行为当成值传递
- 错误处理要求你在调用点显式面对失败路径
- ARC 会让你开始关心对象什么时候被继续留在内存里

这时再往前走，一个非常现实的问题就会出现：**如果某段工作不是立刻出结果，而是要等一会儿，代码应该怎么写？**

例如：

- 读取一份需要一点时间整理的学习报告
- 等待一个后台任务把今日任务列表准备好
- 先发出多个加载动作，稍后再统一拿结果

如果没有并发这条主线，很多初学者会停在一种模糊状态：我知道程序有时候会"慢一下"，但不知道这种等待应该怎样在代码里表达。

而 `async/await` 正是在解决这个问题。它最先解决的，不是"让程序显得更高级"，而是：**把"这里会等待"写清楚**。

## 先说结论：async/await 不是"开线程按钮"

很多人第一次看到并发，会立刻把注意力放到：

- 有没有开新线程
- 底层到底怎么调度
- 这样写是不是一定会更快

这些问题不是完全不重要，但都不是当前阶段最该先抓住的重点。

本章先建立的核心认识应该是：

- `async` 用来标记"这个函数的执行过程中可能会发生等待"
- `await` 用来标记"这里要等待一个异步结果"

所以 `async/await` 首先是一种**把等待过程写清楚的方式**，而不是一个神秘按钮——只要写上它，程序就自动快起来。

更稳妥的理解是：它让你把"先做什么、等什么、等完后继续做什么"表达得更清楚。

## 什么叫"异步"

当前阶段可以先把"异步"近似理解成：**某段工作不是立刻出结果，中间会有等待**。

这个等待可能来自：

- 数据还没准备好
- 某个后台工作还没做完
- 程序在等另一个任务继续推进

所以异步代码的难点，往往不在于写出一行新语法，而在于：你得把等待前和等待后的逻辑都组织清楚。

这也是为什么本章会和前面的函数、错误处理、闭包直接连起来。因为并发不是一条和前面完全无关的新主线，它只是把前面的这些能力放到"会等待"的场景里重新组织了一遍。

## 什么情况下会想到异步

这一节很重要，因为很多初学者刚学 `async/await` 时，脑子里会只有语法，没有场景。

更实用的学习顺序其实是：**先知道什么问题会让你想到异步，再去看 `async`、`await`、`Task` 分别落在哪里**。

当前阶段你可以先重点记住下面几类场景。

### 1. 网络请求

这是最典型的异步场景之一。例如：

- 请求今日学习计划
- 从服务器拉取课程列表
- 提交一条学习记录后等待服务端返回结果

这类工作天然适合（或者说强需求）异步，是因为结果不会立刻回来，中间存在等待服务器响应的过程。

如果把这种等待完全按同步思路去写，代码通常会很僵硬，因为你不得不面对一个事实：现在结果还没到。

所以网络请求几乎总会让你想到：这里需要一段异步流程。

### 2. 文件 I/O

文件读写也是非常常见的一类场景。例如：

- 读取一份本地保存的学习进度
- 把学习报告写入磁盘
- 打开一个比较大的文本文件并解析内容

这里的关键同样不是"文件 API 长什么样"，而是：磁盘读取和写入通常也需要时间。也就是说，这类工作也经常不是你一调用，结果就立刻完全准备好。

所以当代码开始涉及读文件、写文件、保存本地数据时，你就应该开始有一个条件反射：这里很可能会有等待，也就很可能需要异步组织方式。

### 3. 延时执行或定时等待

这一类场景在教学里特别适合作为入门，因为它最容易把"等待"本身看清楚。例如：

- 先等一秒，再显示提醒
- 过一会儿再刷新状态
- 给用户一个短暂缓冲时间后，再继续下一步

这一章里我们用 `Task.sleep(...)` 来演示等待，本质上就是在模拟这类情况。这样做的好处是：你不用先学网络 API，也不用先学文件 API，但依然能把"这里会等一下"这件事看得很清楚。

所以你可以把本章里的 `sleep` 理解成**用来练习异步控制流的教学替身**，而不是把它误解成异步最主要的真实用途。

### 4. 多个互不依赖的准备工作可以同时推进

还有一类很实用的场景是：你有几项工作彼此独立，它们都需要一点时间，你不想傻等第一项完全做完才开始第二项。

例如：

- 一边加载今日任务列表
- 一边加载今日提醒文本

这正是本章完整示例里"学习看板"那段代码想演示的情况。

这种场景下，异步带来的价值就不只是"代码能表达等待"，还包括：**你可以先把多个任务发出去，稍后再统一等待结果**。

### 5. 某段工作需要在后台继续整理

例如：

- 生成一份学习报告
- 统计大量学习记录
- 整理一批章节笔记摘要

这类工作有时不一定是网络请求，也不一定是文件读写，但它们有一个共同点：**不适合要求调用点立刻拿到最终结果**。

所以你也会自然想到：这是不是该组织成异步流程？

## 为什么本章先不用真实网络和文件 API

这里最好提前说清楚，避免你在读例子时产生疑问：既然异步最常见的场景是网络请求和文件 I/O，为什么正文里先用 `Task.sleep(...)`？

原因很简单：当前这门课前面还没有系统讲网络 API，也还没有系统讲文件读写 API。所以这一章先做了一个刻意收敛——用最小的等待示例，把异步控制流本身讲清楚。

等你把 `async`、`await`、`try await`、`Task` 这些主线先看稳之后，再去接网络请求和文件 I/O，会顺很多。

## 什么叫"挂起"，为什么它和"阻塞"不是一回事

这是本章最容易混淆的概念之一。

先看一句最短的结论：`await` 表达的是"当前异步流程在这里先等一下"。

这里的"等一下"更准确地说是：当前异步函数先暂停到这里，等结果回来后再从这里继续。这通常叫**挂起**。

它和"阻塞"最关键的区别，不在当前阶段去追底层线程细节，而是先抓住行为差别：

- **挂起**：这段异步流程先停一下，稍后继续
- **阻塞**：当前位置被死死卡住，什么都不往下走

所以当前阶段你可以先把 `await` 理解成**一种显式写出来的"稍后继续"**，而不是"程序卡死在这里"的写法。

## 先看最基础语法：如何声明 async 函数

最基础的写法如下：

```swift
func loadDailyPlan() async -> [String] {
    return ["复习闭包", "整理 ARC 笔记", "开始学习并发"]
}
```

这里多出来的关键字是 `async`，它放在参数列表后面、返回类型前面。

这个写法现在先只理解到这一层就够了：`loadDailyPlan()` 是一个异步函数，调用它时，调用方要有能力等待结果。

## 调用点为什么必须显式写 await

继续看最小示例：

```swift
func loadDailyPlan() async -> [String] {
    return ["复习闭包", "整理 ARC 笔记", "开始学习并发"]
}

let titles = await loadDailyPlan()
print(titles)
```

这里最关键的不是 `loadDailyPlan()` 里面现在是否真的等了一秒，而是：调用点必须明确写 `await`。

这和前面学过的错误处理很像。你已经知道 `throws` 会要求调用点写 `try`。现在你再记一组非常重要的对应关系：**`async` 会要求调用点写 `await`**。

也就是说：

- `try` 是在调用点显式承认"这里可能失败"
- `await` 是在调用点显式承认"这里会等待"

## async 函数和普通函数的关系

当前阶段先记住两条最重要的规则。

**第一条：异步函数里可以继续调用普通函数。**

例如：

```swift
func summaryLine(for titles: [String]) -> String {
    return "共 \(titles.count) 项学习任务"
}

func loadDailyPlan() async -> [String] {
    return ["复习闭包", "整理 ARC 笔记", "开始学习并发"]
}

let titles = await loadDailyPlan()
let line = summaryLine(for: titles)
print(line)
```

**第二条：普通函数里不能直接写 `await`。**

例如下面这种写法，当前阶段就应该立刻觉得不对：

```swift
func printDashboard() {
    let titles = await loadDailyPlan()  // 编译错误！
    print(titles)
}
```

原因不是语法在"刁难你"，而是：这个普通函数本身没有声明自己会进入等待过程。

所以更稳妥的思考顺序是：

1. 这段函数内部会不会等待异步结果？
2. 如果会，那它自己是不是也应该变成 `async`？
3. 如果当前环境还不能直接 `await`，那是不是应该在合适的位置启动一个 `Task`？

## 一个更接近真实场景的例子：异步函数也会继续调用别的异步函数

前面那个例子虽然语法最简单，但还不够像真实世界。因为真实代码里，异步函数往往不是孤零零存在的，而是一个异步函数继续调用另一个异步函数。

例如：

```swift
func fetchReminderText() async -> String {
    return "先完成最重要的一项任务"
}

func loadReminderText() async -> String {
    let text = await fetchReminderText()
    return text
}

print("开始加载提醒")
let reminder = await loadReminderText()
print("提醒：\(reminder)")
```

这个例子里最值得观察的是流程结构：

1. 外层代码调用 `loadReminderText()`
2. `loadReminderText()` 内部继续等待 `fetchReminderText()`
3. 等结果回来后再继续返回
4. 最后外层代码拿到结果并打印

所以当前阶段你可以先把 `await` 的阅读感觉建立成：**代码在这里先等异步结果，等完再继续往下走**。

## try await：失败路径和等待路径可以叠在一起

前面你已经学过 `try` 处理失败路径，这一章你又开始学 `await` 处理等待路径。而真实代码里，这两件事经常会同时出现——例如一段异步加载不但会等，还可能失败。

这时最常见的组合写法就是 `try await`。

先看基础语法：

```swift
enum StudyPlanLoadError: Error {
    case emptyPlan
}

func loadDailyPlan() async throws -> [String] {
    try await Task.sleep(nanoseconds: 1_000_000_000)

    let titles = ["复习闭包", "整理 ARC 笔记", "开始学习并发"]

    if titles.isEmpty {
        throw StudyPlanLoadError.emptyPlan
    }

    return titles
}
```

这里要重点看两个位置：

1. 函数声明里写的是 `async throws`
2. 调用点写的是 `try await`

调用方可以这样写：

```swift
do {
    let titles = try await loadDailyPlan()
    print("共加载到 \(titles.count) 项任务")
} catch {
    print("学习计划加载失败")
}
```

这一段最好建立成非常稳定的直觉：

- 有可能失败，就在调用点写 `try`
- 需要等待，就在调用点写 `await`
- 两者同时存在，就写 `try await`

## 为什么这里不是“随便调换顺序”

很多初学者看到 `try await` 后，最容易产生的困惑是：

- 这两个关键字为什么要一起写

更稳妥的理解不是去死记顺序，而是先理解它们各自在表达什么：

- `try` 表示：这次调用可能失败
- `await` 表示：这次调用会等待

所以 `try await loadDailyPlan()` 读起来其实就是：

- 我现在要调用这个函数
- 这次调用既可能失败，也会等待结果

当前阶段你只要稳定记住常见写法是：

```swift
let titles = try await loadDailyPlan()
```

就够了。

## Task 是什么

前面你已经看到：

- 如果当前代码位置本来就允许 `await`，那么直接调用异步函数就可以

但现实里还有另一类情况：

- 你当前所在的位置本身还不是异步函数
- 可你又确实想启动一段异步工作

这时最常见的入口之一就是：

- `Task`

先看最基础的感觉：

```swift
func startLoading() {
    Task {
        let reminder = await loadReminderText()
        print("提醒：\(reminder)")
    }
}
```

当前阶段你可以先把 `Task { ... }` 理解成：

- 把大括号里的这段异步工作启动起来

也就是说，它最重要的价值之一是：

- 让你能从一个不能直接写 `await` 的位置，进入异步流程

上面这个例子里没有出现“取回结果”这一步，是因为：

- 结果已经在 `Task` 内部直接被用了
- `print("提醒：\(reminder)")` 就是对结果的处理

也就是说，这是一种很基础的用法：

- 启动异步工作
- 并在任务内部把结果消费掉

如果你后面还想在外层代码里拿到这个任务的结果，就要先把 `Task` 存进变量里。

例如：

```swift
let reminderTask = Task {
    await loadReminderText()
}

let reminder = await reminderTask.value
print("提醒：\(reminder)")
```

这里可以先把：

- `reminderTask`

理解成：

- 那个已经启动起来的异步任务本身

而：

- `reminderTask.value`

表示的是：

- 这个任务最终产出的结果

所以上面这段代码的阅读顺序可以先理解成：

1. 先启动 `loadReminderText()` 这项异步工作。
2. 把这项工作对应的 `Task` 存进 `reminderTask`。
3. 之后在真正需要结果时，再通过 `.value` 把结果取回来。

这里的 `.value` 不是额外的新任务，它只是：

- 向这个已经存在的任务要结果

如果这个任务已经完成，那么：

- `.value` 很快就能拿到结果

如果这个任务还没完成，那么：

- `await reminderTask.value` 就会在这里等它完成

所以当前阶段你可以先把它记成一句很实用的话：

- `Task { ... }` 负责启动异步工作
- `task.value` 负责在后面把这个任务的结果取回来

## 一个非常常见的疑问：既然 await 也要等，和同步调用有什么区别

这是很多人第一次学 `async/await` 时都会问的问题，而且这个问题问得对。

如果你只看这一行：

```swift
let titles = await loadTaskTitles()
```

它在阅读感受上，确实很像：

```swift
let titles = loadTaskTitles()
```

这不是巧合，而是 Swift 故意让异步代码尽量保留“顺着往下读”的外形。

这样做的好处是：

- 代码更接近人脑理解流程的顺序
- 你不用为了表达等待，把代码拆成一层又一层回调

但它们的区别在于：

- 同步调用：当前位置会一直卡住，直到结果准备好
- `await`：当前异步流程会在这里挂起，运行时可以在这段时间继续推进别的异步任务

也就是说，`await` 的价值不在于：

- 我写了它之后就“不用等了”

而在于：

- 我把等待点写清楚了
- 并且等待期间，系统还有机会去推进别的异步工作

所以更准确的说法应该是：

- `await` 不会消灭等待
- 它会把等待组织得更清楚，也更容易和别的异步任务配合

## 什么时候看起来真的和同步很像

如果你只有一件事要做，而且写法是：

```swift
let titles = await loadTaskTitles()
let reminder = await loadReminderText()
```

那么从流程顺序上看，它确实很像：

- 先等第一项
- 再等第二项

这也是为什么很多人第一次学异步时，会觉得：

- 这不就是换个关键字继续排队等吗

这种感觉并不奇怪，因为在这个写法里：

- 你确实还没有把“并发推进”这件事用出来

## 差别什么时候才真正出现

差别会在下面这种场景里立刻出现：

- 有多项彼此独立的工作
- 它们都要等一会儿
- 你不想傻等第一项完全做完才开始第二项

先写一个专门用来模拟“要等一下”的小函数：

```swift
func pauseOneSecond() async {
    do {
        try await Task.sleep(nanoseconds: 1_000_000_000)
    } catch {
    }
}
```

再准备两项彼此独立的加载工作：

```swift
func loadTaskTitles() async -> [String] {
    print("任务列表：开始")
    await pauseOneSecond()
    print("任务列表：完成")
    return ["复习闭包", "整理 ARC 笔记", "开始学习并发"]
}

func loadReminderText() async -> String {
    print("提醒：开始")
    await pauseOneSecond()
    print("提醒：完成")
    return "先完成最重要的一项任务"
}
```

### 写法一：顺序等待

```swift
print("顺序等待：开始")

let titles = await loadTaskTitles()
let reminder = await loadReminderText()

print("任务数：\(titles.count)")
print("提醒：\(reminder)")
print("顺序等待：结束")
```

你可以先把它理解成：

- 第一项做完之前，第二项根本还没开始

所以这段代码的输出顺序，通常会更接近：

```text
顺序等待：开始
任务列表：开始
任务列表：完成
提醒：开始
提醒：完成
顺序等待：结束
```

### 写法二：先启动，再等待

```swift
print("先启动，再等待：开始")

let titlesTask = Task {
    await loadTaskTitles()
}

let reminderTask = Task {
    await loadReminderText()
}

let titles = await titlesTask.value
let reminder = await reminderTask.value

print("任务数：\(titles.count)")
print("提醒：\(reminder)")
print("先启动，再等待：结束")
```

这段代码和前面最大的区别不是最后有没有 `await`，而是：

- 两项工作已经先分别启动了
- `await` 发生在“取结果”这个时刻，而不是“启动工作”这个时刻

### 把执行流程一行一行拆开看

这段代码对新读者最难的地方，通常不是语法，而是：

- 明明最后还是写了两个 `await`
- 为什么它就不再是“一个做完再做下一个”

关键要看：

- `Task { ... }` 这一行在做什么
- `await task.value` 这一行又在做什么

可以按下面这个顺序理解。

#### 第 1 步：打印开始语句

```swift
print("先启动，再等待：开始")
```

这一行没有任何等待，就是普通输出。

所以最先出现的一定是：

```text
先启动，再等待：开始
```

#### 第 2 步：创建 `titlesTask`

```swift
let titlesTask = Task {
    await loadTaskTitles()
}
```

这一行最重要的不是“得到一个变量”，而是：

- 任务列表加载这件事已经被启动了

你可以先把 `titlesTask` 理解成：

- 一张“任务凭证”
- 它代表那段异步工作已经开始推进了
- 以后你可以通过它去取结果

这一步执行完以后，程序不会停在这里傻等任务列表完成，而是会继续往下执行下一行。

也就是说，此时更接近下面这种状态：

- `loadTaskTitles()` 已经在跑
- 但当前外层流程还会继续往下走

#### 第 3 步：创建 `reminderTask`

```swift
let reminderTask = Task {
    await loadReminderText()
}
```

这一行和上面同理。

它表达的是：

- 提醒文本加载这件事也被启动了

执行完这里以后，当前外层流程同样不会立刻卡住等提醒完成，而是继续往下执行。

到这一步为止，最重要的事实是：

- 任务列表在跑
- 提醒文本也在跑
- 两边都已经开始了

这就是它和“顺序等待”真正拉开差别的地方。

在“顺序等待”里，第二项工作这时还根本没有开始。

但在这里，第二项工作已经发出去了。

#### 第 4 步：等待 `titlesTask.value`

```swift
let titles = await titlesTask.value
```

现在才第一次真正进入“我要取结果了”这个阶段。

这行代码的意思不是：

- 现在才开始执行 `loadTaskTitles()`

而是：

- `loadTaskTitles()` 早就开始了
- 如果它现在已经做完，就直接把结果交给我
- 如果它还没做完，我就在这里等它

最关键的一点是：

- 你在这里等待 `titlesTask.value` 的时候，`reminderTask` 并不会停下来

也就是说，哪怕代码字面上先写的是：

```swift
let titles = await titlesTask.value
```

也不代表：

- 提醒任务必须等任务列表任务结束后才能继续

真实情况更接近：

- 当前这条外层流程在等 `titlesTask` 的结果
- 但另一个已经启动的 `reminderTask` 仍然可以继续推进

这正是很多初学者最容易漏掉的点。

`await titlesTask.value` 等待的是：

- “我这条流程什么时候拿到 `titlesTask` 的结果”

它不是在命令整个程序：

- “除了 `titlesTask`，其他任务全部停住”

#### 第 5 步：等待 `reminderTask.value`

```swift
let reminder = await reminderTask.value
```

当代码走到这里时，通常会出现两种情况。

第一种：

- `reminderTask` 早就已经做完了

那这一行几乎可以立刻拿到结果。

第二种：

- `reminderTask` 还没做完

那就在这里再稍微等一下。

所以你看到这里虽然也有第二个 `await`，但它和“顺序等待”仍然不是一回事。

因为在“顺序等待”里：

- 第二项工作是第一项完成之后才启动

而在这里：

- 第二项工作早在前面就已经开始跑了

差别不在“最后有没有两个 `await`”，而在：

- 这两个等待点前面，任务是不是已经先发出去了

#### 第 6 步：两个结果都拿到后，再继续打印

```swift
print("任务数：\(titles.count)")
print("提醒：\(reminder)")
print("先启动，再等待：结束")
```

只有当两个结果都已经拿到，这几行才会继续执行。

所以：

- `先启动，再等待：结束`

一定会出现在两项加载都完成之后。

### 用一条时间线再看一遍

你可以把它想成下面这样的时间线：

1. 打印“开始”。
2. 启动任务列表加载。
3. 启动提醒文本加载。
4. 外层流程去等任务列表结果。
5. 等待期间，提醒任务也在继续跑。
6. 任务列表完成后，外层流程继续往下。
7. 再去取提醒结果；如果提醒早就完成了，这一步几乎立刻返回。
8. 两个结果都到手后，打印最终输出。

如果你把它和“顺序等待”对比，区别就会非常清楚：

- 顺序等待：启动 A，等 A 完，再启动 B，等 B 完
- 先启动再等待：启动 A，启动 B，等 A，等 B

### 输出顺序为什么不一定完全固定

所以它的输出顺序，通常会更接近下面这种“两个开始都先出现”的样子：

```text
先启动，再等待：开始
任务列表：开始
提醒：开始
提醒：完成
任务列表：完成
先启动，再等待：结束
```

但这里一定要补一句很重要的话：

- 两个“完成”谁先出现，不保证固定

因为它取决于：

- 哪个任务先完成
- 调度时机是什么样

真正稳定的，不是“谁一定先完成”，而是：

- 两个任务都比最终的“结束”更早开始
- 两个结果都拿到之后，最后的输出才会继续

如果这两项工作耗时接近，那么：

- 顺序等待更像等两轮
- 先启动再等待更像一起等一轮

这里才真正体现出并发最直观的价值：

- 不是“不等”
- 而是“把几段彼此独立的等待重叠起来”

## 所以这一章最想让你建立的直觉是什么

你可以把这件事压缩成下面这几句：

- `await` 不是“同步调用换皮版”
- 如果你只有一项工作要做，它在阅读感受上确实会像同步流程
- 异步真正的价值，会在“等待期间还有别的事可推进”时体现出来
- `Task` 的一个重要用途，就是先把独立工作发出去，再在真正需要结果时等待

这样你以后再看到：

```swift
let titlesTask = Task { await loadTaskTitles() }
let reminderTask = Task { await loadReminderText() }
```

就不应该只看到：

- 最后还是要 `await`

而应该看到：

- 原来重点是先把两件互不依赖的事都启动起来
- 最后再统一收结果

## 一个非常重要的边界：已经 async 了，就不要随手再包一层 Task

这是本章最需要尽早建立的习惯之一。

先看两段对比。

第一段更自然：

```swift
func refreshDashboard() async {
    let titles = await loadDailyPlan()
    print("共 \(titles.count) 项任务")
}
```

第二段看起来也能跑，但往往没有必要：

```swift
func refreshDashboard() async {
    Task {
        let titles = await loadDailyPlan()
        print("共 \(titles.count) 项任务")
    }
}
```

第二种写法的问题不在于“绝对错误”，而在于它很容易让流程开始变乱：

- 外层函数自己明明已经是 `async`
- 结果真正的工作却被你丢进了另一个任务里
- 这样错误处理、取消和执行顺序都会更难追踪

所以当前阶段一个很实用的判断顺序是：

1. 如果我已经在 `async` 函数里，就优先继续直接 `await`。
2. 如果我当前不在 `async` 环境里，又确实要启动异步工作，再考虑 `Task`。

## 一个完整示例：异步加载学习看板

下面这个例子把本章前面的几条线放到一起：

- 一个异步函数会等待
- 一个异步函数会等待且可能失败
- 两个任务先分别启动
- 稍后再统一等待结果

```swift
enum DashboardLoadError: Error {
    case emptyTasks
}

func loadTaskTitles() async throws -> [String] {
    print("开始加载任务列表")
    try await Task.sleep(nanoseconds: 1_000_000_000)

    let titles = ["复习闭包", "整理 ARC 笔记", "开始学习并发"]

    if titles.isEmpty {
        throw DashboardLoadError.emptyTasks
    }

    print("任务列表加载完成")
    return titles
}

func loadReminderText() async -> String {
    print("开始加载今日提醒")
    try await Task.sleep(nanoseconds: 500_000_000)
    print("今日提醒加载完成")
    return "先完成最重要的一项任务"
}

print("开始生成学习看板")

let taskTitlesTask = Task {
    try await loadTaskTitles()
}

let reminderTask = Task {
    await loadReminderText()
}

do {
    let taskTitles = try await taskTitlesTask.value
    let reminderText = await reminderTask.value

    print("今日任务：")
    for title in taskTitles {
        print("- \(title)")
    }

    print("今日提醒：\(reminderText)")
} catch {
    print("学习看板生成失败")
}
```

## 你需要从这个完整示例中学到什么

不要先急着把它理解成某种“高级并发技巧”。

当前阶段更重要的是看清下面这几点：

### 1. `await` 不等于“自动并行”

如果你写成这样：

```swift
let taskTitles = try await loadTaskTitles()
let reminderText = await loadReminderText()
```

那么它表达的仍然是：

- 先等第一项完成
- 再开始第二项

这当然也是合法而且常见的。

但它不是“先一起发出去，再分别拿结果”。

### 2. `Task` 的作用之一，是先把工作发出去

在完整示例里，我们先写了：

```swift
let taskTitlesTask = Task {
    try await loadTaskTitles()
}

let reminderTask = Task {
    await loadReminderText()
}
```

你当前可以先这样理解：

- 两段异步工作都已经开始推进
- 只是结果还没有在这一行立刻取出来

### 3. 真正需要结果时，再去 await

后面再写：

```swift
let taskTitles = try await taskTitlesTask.value
let reminderText = await reminderTask.value
```

意思就是：

- 现在轮到我要真正拿结果了
- 如果结果还没准备好，就在这里等待

这正是 `Task` 和 `await` 配合时非常常见的一种思路：

- 先启动
- 后等待

## 任务取消入门：为什么“取消”不是强制中断

并发里还有一个很现实的问题：

- 如果这段异步工作已经没有意义了，该怎么办

例如：

- 用户已经离开当前页面
- 这份报告已经不需要继续整理
- 新任务来了，旧任务的结果已经不重要了

这时你通常会遇到：

- 取消

当前阶段最重要的认识不是“取消会像断电一样立刻把所有代码掐掉”，而是：

- 取消更像一种信号

也就是说：

- 任务会收到“这件事没必要继续了”的信息
- 但代码要不要在合适位置停下来，还得看你有没有检查这个状态

## 最基础的取消写法

先看一个最小示例：

```swift
func buildStudyReport() async throws -> [String] {
    var lines: [String] = []

    print("开始整理任务列表")
    try await Task.sleep(nanoseconds: 500_000_000)
    try Task.checkCancellation()
    lines.append("任务：复习 async/await")

    print("开始整理提醒")
    try await Task.sleep(nanoseconds: 500_000_000)
    try Task.checkCancellation()
    lines.append("提醒：先完成未完成内容")

    return lines
}

let reportTask = Task {
    try await buildStudyReport()
}

reportTask.cancel()

do {
    let lines = try await reportTask.value
    print("报告共 \(lines.count) 行")
} catch {
    print("报告整理已取消")
}
```

这里最值得观察的是两件事：

1. 取消是通过 `reportTask.cancel()` 发出去的
2. 任务会在等待点或显式检查取消状态时，决定要不要继续往下走

所以当前阶段可以先建立一个非常朴素但很有用的直觉：

- 取消不是魔法
- 你得在任务推进过程中的关键节点处理它

## Task.isCancelled 和 Task.checkCancellation() 的区别

这两个名字看起来很像，但用途不完全一样。

你可以先这样理解：

- `Task.isCancelled`：问一句“当前任务是不是已经被取消了”
- `Task.checkCancellation()`：如果已经取消，就立刻把这次执行当成失败抛出去

如果你只是想自己决定要不要提前结束，常见写法可以像这样：

```swift
func loadOptionalNotes() async -> [String] {
    do {
        try await Task.sleep(nanoseconds: 500_000_000)
    } catch {
        return []
    }

    if Task.isCancelled {
        return []
    }

    return ["并发不是自动加速器", "await 会显式标出等待点"]
}
```

而如果你希望：

- 一旦取消，就沿失败路径统一处理

那么 `Task.checkCancellation()` 往往更直接。

## 异步代码里为什么更要注意闭包捕获和对象生命周期

这一点和前一章的 ARC 是直接连着的。

前面你已经知道：

- 闭包会捕获外部变量
- `[weak self]` 可以避免把对象不必要地继续强留在内存里

当你开始写异步任务后，这个问题会更现实，因为：

- 任务不是立刻结束的
- 它可能会持续一段时间
- 这段时间里，如果闭包强持有了某个对象，这个对象就可能比你预想中活得更久

先看一个非常基础的例子：

```swift
class StudySession {
    let title: String

    init(title: String) {
        self.title = title
    }

    func startLoading() {
        Task { [weak self] in
            let notes = await loadOptionalNotes()

            if let currentSession = self {
                print("\(currentSession.title)：共拿到 \(notes.count) 条笔记")
            } else {
                print("session 已释放，不再继续更新")
            }
        }
    }
}
```

这一段最想表达的不是“异步代码一定都要写 `[weak self]`”，而是：

- 当任务会持续一段时间时，你更应该有意识地判断闭包是否应该继续强持有对象

也就是说，前一章建立的那条判断顺序，现在仍然成立：

1. 先看关系。
2. 再看对象应不应该被继续留住。
3. 最后决定这里是否需要 `[weak self]`。

## 一个很常见的误区：先把 self 取强，再去 await 很久

看下面这种写法：

```swift
Task { [weak self] in
    if let currentSession = self {
        let notes = await loadOptionalNotes()
        print("\(currentSession.title)：共拿到 \(notes.count) 条笔记")
    }
}
```

这段代码不是语法错误，但它表达的含义要想清楚：

- 一旦 `currentSession` 成功取出来
- 这个对象就会被后面的异步流程继续持有到这段作用域结束

如果这正是你想要的，那没有问题。

但如果你本来更想表达的是：

- 等结果回来之后，如果对象还在，就更新它

那么更自然的组织方式通常是：

```swift
Task { [weak self] in
    let notes = await loadOptionalNotes()

    if let currentSession = self {
        print("\(currentSession.title)：共拿到 \(notes.count) 条笔记")
    } else {
        print("session 已释放，不再继续更新")
    }
}
```

当前阶段不需要把这件事推到特别细的生命周期推导，只要先建立这条直觉就够了：

- 你在 `await` 前后把对象放在哪里重新取出来，可能会影响对象被继续留住多久

## 什么时候不用 Task 反而更好

这和前面“不要已经 `async` 了还乱包一层 `Task`”是同一条主线。

如果你的目标只是：

- 一层异步函数调用下一层异步函数

那最自然的写法通常仍然是：

```swift
func loadDashboard() async throws {
    let titles = try await loadTaskTitles()
    print(titles.count)
}
```

而不是：

```swift
func loadDashboard() async throws {
    let task = Task {
        try await loadTaskTitles()
    }

    let titles = try await task.value
    print(titles.count)
}
```

第二种写法不是完全不能用，而是当前阶段大多数时候都显得绕：

- 你本来就能直接等待
- 却又多创建了一个任务再等它

所以一个很实用的判断方式是：

- 如果我只是要顺着当前异步流程继续往下做，那就直接 `await`
- 如果我需要从同步位置启动异步工作，或者想先发出多个任务再稍后等待结果，再考虑 `Task`

## 常见误区

### 1. 以为写了 await 就一定“并行”

不是。

`await` 最先表达的是：

- 这里要等一个异步结果

至于多个工作是不是同时推进，要看你前面怎样组织任务。

### 2. 以为 Task 越多越高级

不是。

`Task` 是工具，不是层数越多越好。

如果当前流程本来就已经在 `async` 里，很多时候直接 `await` 才更清楚。

### 3. 以为取消会像强制断电一样立刻结束所有代码

不是。

取消更像一种：

- “这件事最好不要继续了”的信号

代码要不要在合适位置停下来，取决于你有没有检查取消状态。

### 4. 以为异步代码和闭包捕获、对象生命周期没有关系

不是。

任务经常就是闭包启动的，而闭包本来就会捕获外部变量。

所以异步代码反而更容易把“对象为什么还没释放”这个问题带出来。

## 本章练习与课后作业

如果你想把这一章的内容真正落实到一个“能跑但异步组织很乱”的项目里，可以继续完成下面这道重构作业：

- 作业答案：`exercises/zh-CN/answers/29-concurrency-basics-async-await-and-task.md`
- 起始工程：`exercises/zh-CN/projects/29-concurrency-basics-async-await-and-task-starter`
- 参考答案工程：`exercises/zh-CN/answers/29-concurrency-basics-async-await-and-task`

starter project 当前已经能完成两件事：

- 生成学习看板
- 导出学习报告

也就是说，这一题的重点不是“把功能补出来”，而是：

- 在不改变当前业务语义的前提下，把异步流程整理清楚

这一题不是开放式自由发挥，而是请你按下面这几处明确修改。

### 修改 1：重构 `loadDashboardData()`

当前版本把两项彼此独立的加载写成了顺序等待：

```swift
let tasks = try await loadTaskTitles()
let reminder = await loadReminderText()
```

请把它改成：

- 用 `Task { ... }` 分别启动两项工作
- 再用 `task.value` 统一取结果

也就是说，这里应该明确写出下面这些语法：

- `let tasksTask = Task { try await loadTaskTitles() }`
- `let reminderTask = Task { await loadReminderText() }`
- `let tasks = try await tasksTask.value`
- `let reminder = await reminderTask.value`

这一题最关键的目标不是“少写几行代码”，而是：

- 把“启动任务”和“等待结果”拆成两个阶段

### 修改 2：重构 `buildSummaryLine(tasks:reminder:)`

当前版本在一个只是拼接字符串的函数里，又额外包了一层 `Task`。

请把这个函数改成同步函数：

```swift
func buildSummaryLine(tasks: [StudyTask], reminder: String) -> String
```

要求：

- 删除内部的 `Task { ... }`
- 直接 `return` 摘要字符串
- 不要在这里继续制造新的异步任务

这一题要你建立的判断是：

- 如果这里只是普通计算，没有等待点，就不该为了“看起来像并发”硬套 `Task`

### 修改 3：同步调整 `runDashboardDemo()`

当你把 `buildSummaryLine(tasks:reminder:)` 改成同步函数后，`runDashboardDemo()` 里这一行也要跟着改：

```swift
let summary = buildSummaryLine(tasks: tasks, reminder: reminder)
```

不要再写：

```swift
let summary = await buildSummaryLine(...)
```

这一题的重点是：

- 上游函数签名变了，下游调用点也要跟着回到正确的同步/异步边界

### 修改 4：重构 `buildStudyReportLines(from:)`

当前版本虽然在外面调用了 `cancel()`，但这个函数内部收到取消后还是继续整理完整报告。

请把这个函数改成：

```swift
func buildStudyReportLines(from dashboard: StudyDashboard) async throws -> [String]
```

要求：

- 保留当前两个等待点
- 在等待点之后使用 `try Task.checkCancellation()`
- 如果任务已经被取消，就提前结束，不要继续把后面的 `lines` 整理完

这一题要明确用到的语法是：

- `async throws`
- `try await`
- `try Task.checkCancellation()`

### 修改 5：同步调整 `runReportExportDemo(dashboard:)`

当你把 `buildStudyReportLines(from:)` 改成 `async throws` 后，这里也要一起调整。

要求：

- 用 `Task { try await buildStudyReportLines(from: dashboard) }` 启动导出任务
- 用 `try await reportTask.value` 读取结果
- 用 `do-catch` 处理取消和失败
- 如果任务被取消，就不要继续打印完整报告内容

更具体地说，当前版本最少应该改到下面这种结构：

```swift
let reportTask = Task {
    try await buildStudyReportLines(from: dashboard)
}

reportTask.cancel()

do {
    let lines = try await reportTask.value
    ...
} catch {
    ...
}
```

### 完成标准

完成后，你的代码至少应该表现出下面这些特征：

- 学习看板里的任务列表和提醒文本会以“先启动，再等待”的方式组织，而不是顺序等待。
- `buildSummaryLine(tasks:reminder:)` 不再额外创建 `Task`。
- 报告导出在收到取消后，不会继续把完整报告打印出来。
- 你能明确指出哪几处用了 `Task { ... }`，哪几处用了 `task.value`，哪几处用了 `try await` 和 `Task.checkCancellation()`。

### 思考题：什么时候该继续把函数写成 async，什么时候才该新建 Task？

请结合 starter project 里的代码，试着用自己的话回答：

- 哪些地方只是应该继续沿着当前异步流程直接 `await`
- 哪些地方才真的适合单独新建 `Task`

如果你能把这道题说清楚，通常说明你已经开始真正理解：

- `Task` 是异步工作的启动入口之一
- 但它不是所有异步代码都该套上的外壳

## 本章小结

这一章最需要记住的是下面这组关系：

- `async` 用来声明“这个函数执行过程中可能会等待”
- `await` 用来标记“这里要等待异步结果”
- `throws` 对应 `try`，`async` 对应 `await`
- 如果一段调用既会等待又可能失败，常见写法就是 `try await`
- `Task` 常用于从同步位置启动异步工作，或先发出任务再稍后等待结果
- 取消更像一种信号，而不是强制断电
- 异步任务和闭包捕获、对象生命周期仍然直接相关

如果你现在已经能比较稳定地看懂下面这类代码：

- `func loadDailyPlan() async -> [String]`
- `let titles = await loadDailyPlan()`
- `let titles = try await loadTaskTitles()`
- `let task = Task { await loadReminderText() }`
- `reportTask.cancel()`

并且开始知道什么时候该直接 `await`，什么时候才需要 `Task`，那么这一章的核心目标就已经达到了。

## 接下来怎么读

如果继续沿这条主线往下走，下一步很自然会进入：

- 30. 并发中的共享状态：当多个任务同时改数据时会发生什么（待补充）

因为当你已经理解了：

- 任务会异步推进
- 任务可以被取消
- 任务里的闭包会捕获外部对象

接下来一个更现实的问题就是：

- 如果多个任务同时读写同一份状态，代码边界应该怎样继续组织
