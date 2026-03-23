# 27. 协议扩展与默认实现：把抽象和复用放在一起

## 阅读导航

- 前置章节：[21. 协议：比继承更灵活的抽象方式](./21-protocols-flexible-abstraction.md)、[22. 扩展：给已有类型补充能力](./22-extensions-adding-capabilities.md)、[24. 泛型：让同一套逻辑适配更多类型](./24-generics-reusable-abstractions.md)
- 上一章：[26. 集合高阶操作：用 map、filter、reduce 整理数据](./26-higher-order-collection-operations.md)
- 建议下一章：[28. 选读：ARC 进阶：weak、unowned 与循环引用](./28-arc-advanced-weak-unowned-and-capture-lists.md)
- 下一章：[28. 选读：ARC 进阶：weak、unowned 与循环引用](./28-arc-advanced-weak-unowned-and-capture-lists.md)
- 适合谁先读：已经理解协议和扩展，准备继续学习如何让多种类型共享默认行为的读者

## 本章目标

学完这一章后，你应该能够：

- 理解协议扩展在 Swift 里的角色
- 看懂“协议要求”和“默认实现”分别应该放在哪里
- 使用协议扩展为多个类型提供共享行为
- 区分“要求所有类型必须自己实现”和“可以直接继承默认实现”这两类情况
- 理解协议扩展为什么常常能减少重复代码
- 知道什么时候默认实现会让代码更清楚，什么时候反而会隐藏业务差异

## 本章对应目录

- 对应项目目录：`demos/projects/27-protocol-extensions-and-default-implementations`
- 练习起始工程：`exercises/zh-CN/projects/27-protocol-extensions-and-default-implementations-starter`
- 练习答案文稿：`exercises/zh-CN/answers/27-protocol-extensions-and-default-implementations.md`
- 练习参考工程：`exercises/zh-CN/answers/27-protocol-extensions-and-default-implementations`

建议你这样使用：

- 先带着“协议解决抽象，扩展解决组织”这条主线来读本章
- 重点观察一个协议的能力要求，哪些应该留在协议本体，哪些适合下放到扩展
- 阅读时尤其注意默认实现的边界，不要把它误解成另一种继承

你可以这样配合使用：

- `demos/projects/27-protocol-extensions-and-default-implementations`：先看“整理好的统一进度看板”，理解协议和协议扩展怎样配合。
- `exercises/zh-CN/projects/27-protocol-extensions-and-default-implementations-starter`：再打开“能跑但重复很多”的版本，练习把共享行为抽出去。
- `exercises/zh-CN/answers/27-protocol-extensions-and-default-implementations.md`：做完后对照判断标准。
- `exercises/zh-CN/answers/27-protocol-extensions-and-default-implementations`：最后运行参考答案工程。

导读建议：

- 先看 demo 里的“协议定义共同要求”，确认 `ProgressTrackable` 到底要求了哪些最小信息。
- 再看“协议扩展补统一默认实现”，对应正文里“默认实现”与“额外辅助方法”的边界。
- 接着看“完整功能：统一进度看板”，观察不同类型怎样直接接入同一套展示流程。
- 最后看“不同类型也能共享同一套默认行为”和“这一章最想演示的差别”，把协议本体、协议扩展、具体类型三者的分工重新梳理一遍。

## 为什么在讲了协议和扩展之后又出来个协议扩展

协议扩展也不等于单纯的“协议 + 扩展”四个字放在一起。

前面两章我们已经分别学习了：

- 协议：定义一组能力要求
- 扩展：给已有类型补充能力

这时一个非常自然的问题就会出现：

- 如果很多类型都遵守同一个协议，而且它们有一部分行为本来就相同，我还要每个类型都重新写一遍吗

例如：

- 多种学习对象都要输出标题
- 多种学习记录都要生成摘要行
- 多种进度项都要判断自己是否完成

如果这些行为真的具有稳定的共同结构，那么每个类型都自己写一遍，通常就会出现新的重复。

Swift 在这里给出的重要工具是：

- 协议扩展

## 先说结论：协议扩展不是继承的替身

这一点必须先说清。

很多读者第一次看到默认实现时，容易产生这样的直觉：

- 这是不是和基类提供默认方法差不多

这种联想有帮助，但不能直接画等号。

更稳妥的理解是：

- 协议扩展是在“能力约定”的基础上补充共享实现
- 它不是在建立一棵父类子类层次

所以本章真正要建立的认识不是：

- 默认实现等于另一种继承

~~全部用继承就等着继承树变成屎山吧~~

而是：

- 当共同点主要体现在“行为约定”上，而不是 `is-a` 关系上时，协议扩展会非常自然

## 先回顾：协议本体负责什么

最基础的协议写法如下：

```swift
protocol DailyBriefPrintable {
    var name: String { get }
    func dailyBrief() -> String
}
```

这里表达的是：

- 遵守协议的类型至少要提供这些成员

也就是说，协议本体最适合放的是：

- 能力要求
- 接口约定

而不是一大堆具体逻辑。

## 再回顾：普通扩展负责什么

前一章你已经知道：

- 扩展适合给已有类型补方法、计算属性和协议遵守

例如：

```swift
extension StudyTask {
    var isLongTask: Bool {
        return estimatedHours >= 2
    }
}
```

这里的重点是：

- 原类型本体不改
- 能力可以按主题补上

协议扩展就是把这两件事进一步合起来。

## 协议扩展的最基础语法

最基础的写法如下：

```swift
extension 协议名 {
    默认实现
}
```

例如：

```swift
protocol ProgressDescribable {
    var title: String { get }
    var isFinished: Bool { get }
}

extension ProgressDescribable {
    func progressText() -> String {
        let status = isFinished ? "已完成" : "未完成"
        return "\(title) - \(status)"
    }
}
```

这里可以先这样理解：

- 协议要求遵守者至少提供 `title` 和 `isFinished`
- 扩展利用这两个要求，进一步拼出一个通用的 `progressText()`

于是，任何遵守 `ProgressDescribable` 的类型，只要已经满足前面的要求，就能直接获得这个默认行为。

## 什么是“默认实现”

当前阶段，可以先把默认实现理解成：

- 只要某个类型遵守协议，而且没有提供自己的版本，就可以直接使用协议扩展里的实现

例如：

```swift
protocol DailyBriefPrintable {
    var name: String { get }
    func dailyBrief() -> String
}

extension DailyBriefPrintable {
    func dailyBrief() -> String {
        return "\(name) 今天完成了既定学习任务。"
    }
}
```

这表示：

- `dailyBrief()` 是协议要求的一部分
- 但协议扩展已经给出了一个默认版本

所以某些类型可以直接用这份默认实现，而不必每个都重新写一遍。

## 什么时候适合给协议要求提供默认实现

这要看一条很关键的判断标准：

- 这段行为是否真的对大多数遵守者都成立

如果答案是“是”，默认实现通常很有价值。

例如：

- 统一的标题格式
- 统一的状态文本
- 统一的摘要拼接规则

如果答案是“不是”，那就不应该为了省代码硬塞一个默认实现。

例如：

- 学生的日报和老师的日报结构完全不同

这种时候，更稳妥的做法通常是：

- 协议只写要求
- 具体类型自己实现

## 一个非常重要的边界：协议要求和额外辅助方法

协议扩展里可以放两类东西，但它们含义不同。

### 1. 给协议要求提供默认实现

例如：

```swift
protocol SummaryPrintable {
    func summaryLine() -> String
}

extension SummaryPrintable {
    func summaryLine() -> String {
        return "默认摘要"
    }
}
```

这里的 `summaryLine()` 本来就写在协议要求里。

### 2. 添加协议本体里没有要求的辅助方法

例如：

```swift
protocol SummaryPrintable {
    var title: String { get }
}

extension SummaryPrintable {
    func summaryLine() -> String {
        return "标题：\(title)"
    }
}
```

这里的 `summaryLine()` 并不是协议要求的一部分。

它只是：

- 一个所有遵守者都能额外获得的辅助能力

这两种写法在使用效果上都可能很方便，但语义不完全一样。

当前阶段最稳妥的建议是：

- 如果调用方明确依赖某个能力，就把它写进协议要求
- 如果它只是一个共享辅助能力，可以只放在协议扩展里

## 一个完整示例：学习对象的统一进度描述

接下来我们开看一个场景：“让对象都能生成一段统一进度文本”。

先定义协议：

```swift
protocol ProgressTrackable {
    var title: String { get }
    var completedSteps: Int { get }
    var totalSteps: Int { get }
}
```

这里表达的是：

- 只要某个对象能提供标题、已完成步数和总步数
- 它就具备被统一描述进度的基础

接着用协议扩展补默认实现：

```swift
extension ProgressTrackable {
    var isFinished: Bool {
        return completedSteps >= totalSteps
    }

    var progressRateText: String {
        if totalSteps == 0 {
            return "0%"
        }

        let rate = Double(completedSteps) / Double(totalSteps) * 100
        return String(format: "%.0f%%", rate)
    }

    func progressSummary() -> String {
        let status = isFinished ? "已完成" : "进行中"
        return "\(title) - \(completedSteps)/\(totalSteps) - \(progressRateText) - \(status)"
    }
}
```

然后定义几种具体类型：

```swift
struct StudyTask: ProgressTrackable {
    let title: String
    let completedSteps: Int
    let totalSteps: Int
}

struct ChapterPlan: ProgressTrackable {
    let title: String
    let completedSteps: Int
    let totalSteps: Int
}
```

这里最值得注意的是：

- `StudyTask` 和 `ChapterPlan` 之间没有父子关系
- 但它们都能遵守同一个协议
- 一旦遵守，就都能直接获得 `isFinished`、`progressRateText` 和 `progressSummary()`

调用时：

```swift
let items: [ProgressTrackable] = [
    StudyTask(title: "闭包练习", completedSteps: 1, totalSteps: 3),
    ChapterPlan(title: "第 27 章", completedSteps: 4, totalSteps: 4)
]

for item in items {
    print(item.progressSummary())
}
```

这段代码展示的正是协议扩展的典型价值：

- 抽象来自协议
- 共享实现来自扩展

## 为什么这能减少重复

如果没有协议扩展，你可能会在每个类型里都写：

- `isFinished`
- 百分比计算
- 进度摘要拼接

这不仅重复，而且很容易出现：

- 一个类型格式是 `3/5`
- 另一个类型格式是 `3 / 5`
- 第三个类型忘了处理 `totalSteps == 0`

协议扩展把这些共同规则集中到一个地方后，带来的好处是：

- 一致性更强
- 修改点更集中
- 新增遵守者时成本更低

## 什么时候不该把逻辑塞进协议扩展

这一点和前面的“默认实现边界”是一致的。

如果某段逻辑其实包含很多具体业务假设，那么放进协议扩展往往会让抽象变脆弱。

例如：

- 默认摘要里强行写死“今天完成了既定学习任务”
- 默认显示逻辑默认所有对象都有“老师批改”

这类内容一旦放进协议扩展，很快就会出现：

- 某些类型根本不适配
- 但为了复用，又被迫接受了这套默认措辞

所以更稳妥的标准是：

- 默认实现只放那些真正通用的逻辑

## 一个很实用的判断顺序

如果你不确定某段共享行为该不该写进协议扩展，可以按下面顺序判断：

1. 这段行为依赖的输入，能否完全由协议要求提供？
2. 这段行为是否对大多数遵守者都成立？
3. 如果以后新增类型，这段逻辑会不会立刻显得别扭？

如果前两条成立，而第三条风险也不高，那么协议扩展通常是合理的选择。

## 协议扩展和普通工具函数的区别

有些读者会问：

- 既然只是共享一段逻辑，为什么不直接写成普通函数

普通函数当然也能复用，但协议扩展有一个非常明显的优势：

- 逻辑更贴近能力本身

例如，与其写：

```swift
func progressSummary(for item: ProgressTrackable) -> String {
    ...
}
```

很多时候写成：

```swift
item.progressSummary()
```

更自然，因为它表达的是：

- 这是对象自身具备的一项能力

所以协议扩展非常适合那些“从领域语义上看，本来就应该挂在对象身上”的共享行为。

## 协议扩展和具体类型扩展的分工

这一章最好再和[第 22 章](22-extensions-adding-capabilities.md)对照一下。

### 具体类型扩展更适合：

- 某个类型专属的辅助能力
- 只有该类型才知道的细节逻辑

### 协议扩展更适合：

- 多个遵守者都共享的通用行为
- 基于协议要求就能推导出来的逻辑

所以让我们回到刚才讲的判断思路：

- 如果行为只属于 `StudyTask`，优先考虑 `extension StudyTask`
- 如果行为属于“所有 `ProgressTrackable`”，优先考虑 `extension ProgressTrackable`

## 常见误区

### 1. 以为协议扩展就是另一种继承

不是。

它是在协议抽象基础上补共享行为，不是在建立父类层次。

### 2. 以为默认实现越多越好

~~屎山就是这么堆出来的~~

不是。

默认实现只有在“真的通用”时才有价值。

### 3. 以为协议扩展里写的方法一定是协议要求

不是。

它也可以只是额外辅助能力。

### 4. 以为只要能复用，就应该放进协议扩展

不是。

如果业务差异很大，强行共享只会让抽象变模糊。

## 本章练习与课后作业

如果你想把这一章的内容真正落实到一个“能跑但很乱”的项目里，可以继续完成下面这道重构作业：

- 作业答案：`exercises/zh-CN/answers/27-protocol-extensions-and-default-implementations.md`
- 起始工程：`exercises/zh-CN/projects/27-protocol-extensions-and-default-implementations-starter`
- 参考答案工程：`exercises/zh-CN/answers/27-protocol-extensions-and-default-implementations`

这一题的重点是处理 starter project 里这种典型重复：

- 多个进度对象都在各写各的完成判断
- 多个进度对象都在各写各的摘要文本
- 共享逻辑散落在具体类型里

更稳妥的重构顺序通常是：

1. 先提炼协议要求。
2. 再把真正通用的逻辑移到协议扩展。
3. 最后保留那些只属于具体类型自己的部分。

要求：

- 使用“协议要求”的形式，统一抽出多个进度对象都必须提供的最小信息。
- 使用“协议扩展”的形式，重构重复的完成判断逻辑。
- 使用“协议扩展”的形式，重构重复的进度摘要和建议文本逻辑。
- 不要把所有成员都塞进协议扩展；只属于具体类型自己的成员，应继续保留在具体类型里。
- 主流程应改成依赖协议统一处理多个对象，而不是继续分别调用三个具体类型的重复方法。

## 本章小结

这一章最需要记住的是下面这组关系：

- 协议负责定义能力要求
- 协议扩展负责补共享行为和默认实现
- 默认实现适用于真正通用的逻辑
- 协议扩展不是继承替身，而是抽象和复用的组合方式
- 如果行为只属于某个具体类型，应优先考虑具体类型扩展
- 如果行为属于一整类遵守者，协议扩展会非常自然

如果你现在已经能比较稳定地看懂下面这类代码：

- `protocol ProgressTrackable { ... }`
- `extension ProgressTrackable { ... }`
- 多个不同类型共享 `progressSummary()`

并且开始知道哪些默认实现值得写、哪些不值得写，那么这一章的核心目标就已经达到了。

## 接下来怎么读

下一章建议继续阅读：

- [28. 选读：ARC 进阶：weak、unowned 与循环引用](./28-arc-advanced-weak-unowned-and-capture-lists.md)

因为当你已经把对象、协议、扩展和闭包串起来之后，接下来一个非常现实的问题就是：

- 这些引用关系会怎样影响对象生命周期
- 什么时候会出现“谁也释放不掉谁”的情况
