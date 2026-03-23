# 26. 集合高阶操作：用 map、filter、reduce 整理数据

## 阅读导航

- 前置章节：[08. Optional 入门](./08-optional-basics.md)、[14. 数组与字典：列表与键值对](./14-arrays-and-dictionaries.md)、[25. 闭包：把函数当成值来传递](./25-closures-functions-as-values.md)
- 上一章：[25. 闭包：把函数当成值来传递](./25-closures-functions-as-values.md)
- 建议下一章：[27. 协议扩展与默认实现：把抽象和复用放在一起](./27-protocol-extensions-and-default-implementations.md)
- 下一章：[27. 协议扩展与默认实现：把抽象和复用放在一起](./27-protocol-extensions-and-default-implementations.md)
- 适合谁先读：已经理解数组、函数和闭包，准备进一步学习如何更清楚地处理一组数据的读者

## 本章目标

学完这一章后，你应该能够：

- 理解为什么集合高阶操作本质上是在表达“处理意图”
- 看懂 `map`、`filter`、`reduce` 和 `compactMap` 的基础写法
- 将简单的循环处理改写为更清楚的集合变换
- 区分“筛选”“映射”“汇总”和“去掉无效值”这几类常见任务
- 知道什么时候高阶操作更合适，什么时候普通 `for-in` 更直接
- 避免把多层高阶操作写成难读的链式谜语

## 本章对应目录

- 对应项目目录：`demos/projects/26-higher-order-collection-operations`
- 练习起始工程：`exercises/zh-CN/projects/26-higher-order-collection-operations-starter`
- 练习答案文稿：`exercises/zh-CN/answers/26-higher-order-collection-operations.md`
- 练习参考工程：`exercises/zh-CN/answers/26-higher-order-collection-operations`

建议你这样使用：

- 先把本章当成“集合处理的表达方式升级”来读，而不是背一组新方法
- 先看每个例子里的循环版本，再看对应的高阶操作版本
- 每看到一个高阶操作，都先问它在表达什么意图
- 尤其注意 `compactMap` 和 `map` 的区别，它和 Optional 会直接连起来

你可以这样配合使用：

- `demos/projects/26-higher-order-collection-operations`：先看“循环版和高阶版的对照演示”，建立行为对应关系。
- `exercises/zh-CN/projects/26-higher-order-collection-operations-starter`：再自己动手把原始循环逐步重构成更清楚的集合操作。
- `exercises/zh-CN/answers/26-higher-order-collection-operations.md`：做完后对照每段循环分别对应什么。
- `exercises/zh-CN/answers/26-higher-order-collection-operations`：最后查看完整参考实现。

导读建议：

- 先看 demo 里的“完整功能：学习日报生成器”，从原始文本到合法任务对象，把整个数据流先跑通。
- 再分别看 “filter 用来筛出未完成任务”“map 用来提取标题和展示文本”“reduce 用来汇总总时长和完成数量”，把每一种操作和它的处理意图对应起来。
- 接着看“compactMap 负责清洗无效输入”，重点体会它和前面 `Optional` 的联系。
- 最后看“链式调用可以直接表达处理意图”，再回到正文里的“链式调用边界”，判断什么时候该链，什么时候该拆。

## 为什么现在才开始学集合高阶操作

经过上一章对闭包的讲解，你应该已经了解：

- 一段行为可以作为参数传进去

这正是集合高阶操作成立的基础。

例如，当你写：

```swift
tasks.filter { task in
    task.isFinished == false
}
```

它本质上就是：

- `filter` 负责遍历
- 闭包负责判断每个元素要不要留下

所以这一章并不是突然多出一堆新语法，而是把：

- 数组
- 函数
- 闭包

这几条线真正合到一起。

## 先说结论：高阶操作不是为了把代码写短

很多人刚接触 `map`、`filter`、`reduce` 时，会先把注意力放在：

- 链式调用很短
- 一行就能写完

这很容易把方向带偏。

更稳妥的理解是：

- 高阶操作的重点不在“更短”
- 而在“更直接地表达我要对整组数据做什么”

例如，如果你要：

- 从任务列表中挑出未完成任务

那么：

```swift
tasks.filter { !$0.isFinished }
```

比起手动写一个空数组、遍历、判断、追加，更接近人的思维表达：

- 过滤出未完成项

所以本章学习时最重要的问题不是：

- 这句还能不能再缩短

而是：

- 这句是不是把意图表达清楚了

## 什么叫“高阶操作”

当前阶段，可以先把集合高阶操作理解成：

- 由集合提供的一组“接收闭包、对整组数据做统一处理”的操作

这里面最常见的几类任务分别是：

- `map`：把每个元素转换成另一种结果
- `filter`：只保留符合条件的元素
- `reduce`：把整组元素汇总成一个结果
- `compactMap`：转换并顺便去掉 `nil`

你会发现，这几类任务在日常代码里出现得非常频繁。

## 先看 `map`：把一组元素变成另一组元素

先别急着看 `map` 写法，先看读者已经熟悉的循环版本：

```swift
let hours = [1, 2, 3]
var texts: [String] = []

for hour in hours {
    texts.append("\(hour) 小时")
}
```

这段代码在做的事情其实很单纯：

- 遍历原数组里的每个元素
- 把每个 `Int` 转成对应的 `String`
- 把转换结果放进新数组

也就是说，这段循环的核心行为是：

- 对每个元素做同一种转换

当你把这层行为看清以后，再看 `map` 就会顺很多。

最基础的写法如下：

```swift
数组.map { 元素 in
    转换结果
}
```

例如：

```swift
let hours = [1, 2, 3]
let texts = hours.map { hour in
    "\(hour) 小时"
}
```

你可以把它近似理解成：

- “把刚才那段循环，压缩成一个直接表达‘逐个转换’意图的写法”

这里可以继续这样理解：

- 输入是一组 `Int`
- 输出是一组 `String`
- 元素个数通常不变

也就是说，`map` 最适合解决的问题是：

- 我想把“每个元素”都按同一规则转换一下

## `map` 和手写循环的关系

不用 `map`，你当然也可以写成：

```swift
var texts: [String] = []

for hour in hours {
    texts.append("\(hour) 小时")
}
```

这能工作，而且对初学者来说往往更容易先理解。

但 `map` 版本更直接地表达了：

- 我不是在写一个复杂流程
- 我只是想把整组元素逐个转换

所以 `map` 的价值在于：

- 让“逐个转换”的语义更为明确

## 再看 `filter`：只保留符合条件的元素

同样地，先看循环版本：

```swift
var unfinishedTasks: [StudyTask] = []

for task in tasks {
    if task.isFinished == false {
        unfinishedTasks.append(task)
    }
}
```

这段代码在做的事情是：

- 依次检查每个任务
- 如果任务满足条件，就把它留下
- 如果不满足，就跳过

所以它的核心行为是：

- 从整组数据里筛出一部分

最基础的写法如下：

```swift
数组.filter { 元素 in
    是否保留
}
```

例如：

```swift
let unfinishedTasks = tasks.filter { task in
    task.isFinished == false
}
```

你可以把它理解成：

- “把刚才那段‘判断后决定留不留’的循环，改写成直接表达筛选意图的写法”

这里的含义是：

- 遍历整组任务
- 让闭包判断每一项是否应该留下
- 结果仍然是一组 `StudyTask`

和 `map` 相比，`filter` 的重点不是“变成别的东西”，而是：

- 从原集合里筛出一部分

## `filter` 和 `if` 判断不是一回事

这一点最好单独说清。

`if` 更像是在处理：

- 一个具体值当前该走哪条分支

而 `filter` 更像是在处理：

- 整组值里哪些应该保留

例如：

```swift
if task.isFinished == false {
    print(task.title)
}
```

和：

```swift
let unfinishedTasks = tasks.filter { !$0.isFinished }
```

都和条件有关，但它们表达的层次完全不同。

所以读到 `filter` 时，你更应该联想到的是：

- 筛选集合

而不是：

- 换一种方式写 `if`

## 再看 `reduce`：把整组数据汇总成一个结果

这一节最好也先从循环版本进入。

例如，如果要统计总学习时长，你很可能会先写出：

```swift
var totalHours = 0

for task in tasks {
    totalHours += task.estimatedHours
}
```

这段代码在做的事情是：

- 先准备一个累计值
- 再把每个任务的时长不断加进去

所以它的核心行为是：

- 把整组数据逐步汇总成一个最终结果

最常见的入门写法如下：

```swift
数组.reduce(初始值) { 当前累计值, 当前元素 in
    新的累计值
}
```

例如，统计总学习时长：

```swift
let totalHours = tasks.reduce(0) { partialResult, task in
    partialResult + task.estimatedHours
}
```

这里的 `0`，就对应循环版本里的：

- `var totalHours = 0`

而闭包里的：

- `partialResult + task.estimatedHours`

就对应循环里每一轮做的累计动作。

这里可以先这样理解：

- `0` 是起点
- `partialResult` 表示目前累计到哪里了
- 每处理一个任务，就把它的时长继续累加进去

所以 `reduce` 最适合处理：

- 总和
- 计数
- 拼接
- 汇总成单个结果

## 为什么 `reduce` 往往比前两者更难

`map` 和 `filter` 的直觉相对简单：

- 一个是变形
- 一个是筛选

而 `reduce` 更难的地方在于：

- 你必须同时理解“当前元素”和“累计状态”

如果这两个角色没分清，代码就会立刻变得抽象。

所以当前阶段的建议很明确：

- 先把 `reduce` 用在很清楚的汇总任务上

例如：

- 统计总时长
- 统计完成项个数
- 把标题拼成一个列表字符串

不要一上来就试图用 `reduce` 解决所有问题。

## `compactMap`：转换并去掉无效值

这一章里，`compactMap` 和前面的 Optional 知识联系最紧。

先看循环版本：

```swift
let rawScores = ["80", "abc", "95", ""]
var scores: [Int] = []

for text in rawScores {
    if let score = Int(text) {
        scores.append(score)
    }
}
```

这段代码在做两件事：

- 尝试把字符串转成整数
- 如果成功，就留下；如果失败，就跳过

也就是说，它同时包含了：

- 转换
- 去掉无效结果

看清这一点之后，再看 `compactMap` 就会非常自然。

再看同一个例子的高阶操作版本：

```swift
let rawScores = ["80", "abc", "95", ""]
let scores = rawScores.compactMap { text in
    Int(text)
}
```

这里最值得注意的是：

- `Int(text)` 的结果是 `Int?`
- 合法数字会得到具体整数
- 非法内容会得到 `nil`

而 `compactMap` 做的事情是：

- 对每个元素执行转换
- 只保留非 `nil` 的结果

所以最后的 `scores` 会是一组真正的 `Int`。

## `map` 和 `compactMap` 的区别

这两个方法非常容易混。

如果写：

```swift
let results = rawScores.map { text in
    Int(text)
}
```

那么结果类型会是：

- `[Int?]`

也就是说：

- 每个元素都保留
- 只是每个位置上可能是 `nil`

而如果写：

```swift
let scores = rawScores.compactMap { text in
    Int(text)
}
```

那么结果类型会是：

- `[Int]`

因为：

- 转换失败的那些项已经被去掉了

当前阶段最稳妥的判断标准是：

- 想保留位置关系，就用 `map`
- 想只留下有效结果，就考虑 `compactMap`

如果你一时分不清，也可以先退回到循环直觉：

- 如果你的循环里只是“每个都转换一下”，更接近 `map`
- 如果你的循环里出现了 `if let`，只在成功时追加结果，那通常更接近 `compactMap`

## 一个完整示例：从学习任务到学习日报

为了更好地理解这章学的内容有什么用，我们来看这样一个场景

- 从一组学习任务里整理出日报数据

先定义模型：

```swift
struct StudyTask {
    let title: String
    let estimatedHours: Int
    var isFinished: Bool
}
```

假设有这样一组数据：

```swift
let tasks = [
    StudyTask(title: "泛型入门", estimatedHours: 2, isFinished: true),
    StudyTask(title: "闭包基础", estimatedHours: 1, isFinished: false),
    StudyTask(title: "高阶操作", estimatedHours: 3, isFinished: false)
]
```

现在我们想得到几类结果。

### 1. 只取未完成任务

```swift
let unfinishedTasks = tasks.filter { task in
    task.isFinished == false
}
```

这表达的是：

- 从整组任务里筛出未完成项

### 2. 只取标题列表

```swift
let titles = tasks.map { task in
    task.title
}
```

这表达的是：

- 把任务对象转换成标题字符串

### 3. 统计总学习时长

```swift
let totalHours = tasks.reduce(0) { partialResult, task in
    partialResult + task.estimatedHours
}
```

这表达的是：

- 把所有任务时长汇总起来

### 4. 提取所有未完成任务标题

```swift
let unfinishedTitles = tasks
    .filter { task in
        task.isFinished == false
    }
    .map { task in
        task.title
    }
```

这里最值得注意的是：

- 先筛选
- 再转换

链式调用是否清楚，关键不在“是不是一行”，而在：

- 每一步意图都非常明确

### 5. 从原始文本中提取合法时长

```swift
let rawHours = ["2", "x", "5", ""]
let validHours = rawHours.compactMap { text in
    Int(text)
}
```

这表达的是：

- 试着把文本转成数字
- 只留下成功转换的结果

## 高阶操作和链式调用的边界

很多教程讲到这里时，很容易让读者形成另一个误区：

- 只要能链起来，就应该一直链

这不对。

例如，如果你写出这种东西：

```swift
let report = tasks
    .filter { ... }
    .map { ... }
    .reduce(...) { ... }
```

它不一定错，但要问一个更实际的问题：

- 读代码的人能不能一眼看懂

如果每个步骤都很简单，而且顺序非常自然，那么链式调用通常很清楚。

但如果：

- 某一步的闭包已经很长
- 中间结果有独立业务含义
- 你需要给中间阶段起名字

那么更稳妥的做法通常是：

- 拆开写

例如：

```swift
let unfinishedTasks = tasks.filter { !$0.isFinished }
let unfinishedTitles = unfinishedTasks.map { $0.title }
```

这比一口气塞进一长串表达式更容易维护。

## 什么时候不用高阶操作反而更好

这是本章非常关键的一条边界。

如果你的处理流程包含：

- 多步状态变化
- 中途提前退出
- 复杂分支
- 大量其他逻辑的实现

那么普通 `for-in` 往往更直接。

例如：

- 一边遍历一边打印详细日志
- 一边查找一边在命中后立刻停止
- 每一项都可能触发不同错误处理

这些场景并不是高阶操作做不到，而是：

- 写成高阶操作不一定更清楚

所以更稳妥的原则是：

- 高阶操作服务于清晰表达
- 不是为了强行替代循环

## 一个常见问题：这些操作是不是更“函数式”

可以这么理解，但当前阶段没必要把重点放在术语上。

~~学C的看到这里可能有点脾气，但是我们不管他~~

而更实用(也更准确)的理解是：

- 帮助你更好地表达意图
- 避免你编写重复逻辑

例如：

- `map`：我要转换
- `filter`：我要筛选
- `reduce`：我要汇总

如果你先把这三件事建立成稳定直觉，那么后面再遇到更多 API 时，就不会只是在背名字。

## 常见误区

### 1. 以为 `map` 和 `filter` 可以互相替代

不是。

一个侧重转换，一个侧重筛选，职责不同。

### 2. 以为 `compactMap` 和 `map` 一样

不是。

`compactMap` 会把 `nil` 结果去掉，这会直接影响结果类型和元素个数。

### 3. 以为 `reduce` 应该优先用来解决所有汇总问题

不是。

只有当汇总逻辑本身清楚时，`reduce` 才是好工具。

## 本章练习与课后作业

如果你想把这一章的内容真正落实到一个“能跑但很乱”的项目里，可以继续完成下面这道重构作业：

- 作业答案：`exercises/zh-CN/answers/26-higher-order-collection-operations.md`
- 起始工程：`exercises/zh-CN/projects/26-higher-order-collection-operations-starter`
- 参考答案工程：`exercises/zh-CN/answers/26-higher-order-collection-operations`

starter project 当前保留了大量循环写法。

这一题的重点不是“把所有循环都消灭”，而是：

- 识别哪些循环本质上已经在做 `map`
- 哪些在做 `filter`
- 哪些在做 `reduce`
- 哪些在做 `compactMap`

更稳妥的做法通常是：

1. 先用一句话说清旧循环在做什么。
2. 再判断它最接近哪一种高阶操作。
3. 最后在不牺牲可读性的前提下改写。

要求：

- 使用 `filter` 的形式，重构“筛出未完成任务”的循环。
- 使用 `map` 的形式，重构“提取标题列表”和“生成摘要文本”的循环。
- 使用 `reduce` 的形式，重构“统计总时长”和“统计完成数量”的循环。
- 使用 `compactMap` 的形式，重构“`if let + append` 清洗有效整数”的循环。
- 如果某段循环改成链式调用后反而更难读，可以保留循环，但请先在代码注释或自己的说明里写清为什么没有改。

## 本章小结

这一章最需要记住的是下面这组关系：

- 集合高阶操作的重点在于表达意图
- `map` 用于逐个转换
- `filter` 用于筛选保留
- `reduce` 用于把整组数据汇总成一个结果
- `compactMap` 用于转换并去掉 `nil`
- 链式调用是否优秀，不看长短，只看是否清楚
- 当流程复杂时，普通 `for-in` 依然是很好的选择

如果你现在已经能比较稳定地看懂下面这类代码：

- `tasks.map { ... }`
- `tasks.filter { ... }`
- `tasks.reduce(0) { ... }`
- `rawTexts.compactMap { Int($0) }`

并且知道什么时候该拆开写、什么时候不必硬上链式调用，那么这一章的核心目标就已经达到了。

## 接下来怎么读

下一章建议继续阅读：

- [27. 协议扩展与默认实现：把抽象和复用放在一起](./27-protocol-extensions-and-default-implementations.md)

因为当你已经会用闭包和高阶操作整理数据之后，接下来一个很自然的问题就是：

- 能不能把协议和扩展进一步组合起来，让共享行为本身也更好复用
