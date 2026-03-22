# 22. 扩展：给已有类型补充能力

## 阅读导航

- 前置章节：[21. 协议：比继承更灵活的抽象方式](./21-protocols-flexible-abstraction.md)
- 上一章：[21. 协议：比继承更灵活的抽象方式](./21-protocols-flexible-abstraction.md)
- 建议下一章：[23. 错误处理：让失败路径更清楚](./23-error-handling-clear-failure-paths.md)
- 下一章：[23. 错误处理：让失败路径更清楚](./23-error-handling-clear-failure-paths.md)
- 适合谁先读：已经理解协议和基础类型设计，准备学习如何在不改原定义的情况下给类型补充能力的读者

## 本章目标

学完这一章后，你应该能够：

- 看懂 `extension` 的最基础语法
- 使用扩展给已有类型增加方法和计算属性
- 理解为什么扩展适合补充能力，而不是重写类型主体
- 知道扩展可以用来补协议遵守
- 理解扩展和直接修改原类型定义之间的差别

## 本章对应目录

- 对应项目目录：`demos/projects/22-extensions-adding-capabilities`
- 练习与课后作业：后续补充

建议你这样使用：

- 先看正文中的扩展语法模板和通用调用形式
- 再运行 `demos/projects/22-extensions-adding-capabilities`
- 重点观察“原类型定义不改，能力却变多了”这个效果

## 为什么协议之后适合继续讲扩展

上一章里，我们已经看到：

- 协议可以定义一组能力要求
- 多个不同类型可以一起遵守同一个协议

这时一个很自然的问题就会出现：

- 如果某个类型本来已经定义好了，我还能不能在不改原定义的前提下，给它补充新能力

Swift 给出的重要答案就是：

- `extension`

它最适合处理的场景是：

- 类型本体已经在那里
- 但你想把某些辅助方法、计算属性或协议遵守单独补上去

所以这一章要解决的问题不是：

- 如何重新定义一个类型

而是：

- 如何给已有类型补一层新的能力组织

## 先看 `extension` 最基础的语法外形

在进入概念之前，先把扩展最常见的代码形状看清楚。

### 定义扩展的通用模板

最基础的写法如下：

```swift
extension 类型名 {
    新增的方法
    新增的计算属性
}
```

例如：

```swift
extension Int {
    func doubled() -> Int {
        return self * 2
    }
}
```

这里可以先这样理解：

- `extension Int`：表示现在要给 `Int` 补充能力
- `doubled()`：这是通过扩展新增的方法

### 扩展后的通用调用形式

这一章最常见的几种使用方式如下：

```swift
值.扩展方法()
值.扩展计算属性
```

例如：

```swift
let number = 8
print(number.doubled())
```

如果扩展里加的是计算属性，也可以直接这样用：

```swift
print(task.isLongTask)
```

你可以先把扩展后的调用形式记成：

- 写法上和普通方法、普通属性没有区别
- 调用方通常不会关心它原本是不是在类型主体里定义的

## 扩展到底在做什么

当前阶段，可以先把扩展理解成：

- 在不改原类型主体结构的前提下，给它补充新的能力

例如，一个 `StudyTask` 结构体原来可能只保存这些数据：

```swift
struct StudyTask {
    let title: String
    let estimatedHours: Int
    var isFinished: Bool
}
```

它当然已经能用。

但如果你后面发现还需要：

- 一个格式化输出的方法
- 一个判断是不是“长任务”的计算属性

你就不一定要马上回到原定义里把所有东西继续往里堆。

你也可以写成：

```swift
extension StudyTask {
    func summaryLine() -> String {
        let status = isFinished ? "已完成" : "未完成"
        return "\(title) - \(estimatedHours) 小时 - \(status)"
    }

    var isLongTask: Bool {
        return estimatedHours >= 2
    }
}
```

这里最重要的感受是：

- 类型本体和补充能力被分开组织了

这正是扩展最常见的价值。

如果你暂时还没把代码拆成多个文件，也没关系。当前阶段先建立一个很实用的习惯就够了：

- 至少先按主题把“核心定义”“工具扩展”“协议遵守扩展”分块排开

这样读代码时，边界会比“所有内容混在一起”清楚很多。

## 扩展适合补什么，不适合补什么

当前阶段先抓最常见、最实用的边界。

### 扩展很适合补的方法

例如：

- 格式化输出
- 辅助计算
- 把一组和当前类型密切相关的小逻辑收拢起来

### 扩展很适合补的计算属性

例如：

- 某个状态判断
- 某个派生结果

### 扩展很适合补的协议遵守

这一点和上一章会直接连起来。

很多时候一个类型本体先写好，后面你才发现：

- 它其实也应该遵守某个协议

这时就可以把协议实现单独写进扩展。

### 当前阶段不该把扩展理解成“重新定义类型”

扩展的重点是：

- 补能力

不是：

- 把原类型推倒重来

当前阶段你尤其要先记住一个常见边界：

- 扩展可以添加计算属性
- 但不能随便添加新的存储属性

这一点如果先不记住，后面很容易混乱。

## 一个最常见的用途：给已有类型补方法

先看最简单的例子：

```swift
extension String {
    func trimmedCourseTitle() -> String {
        return self.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
```

调用时：

```swift
let rawTitle = "  Swift 协议入门  "
print(rawTitle.trimmedCourseTitle())
```

这里最值得注意的地方是：

- `String` 原本就存在
- 我们没有重新定义 `String`
- 只是通过扩展给它补了一个更贴合当前业务的辅助方法

## 另一个常见用途：给已有类型补计算属性

例如：

```swift
extension StudyTask {
    var isLongTask: Bool {
        return estimatedHours >= 2
    }
}
```

调用时：

```swift
print(task.isLongTask)
```

当前阶段可以先把这种写法理解成：

- 这个属性不是额外存了一份新数据
- 而是根据已有数据临时计算出来的结果

所以扩展和计算属性搭配时，往往会很自然。

## 一个非常重要的用途：用扩展补协议遵守

这一节是本章和上一章衔接最紧的地方。

先看一个协议：

```swift
protocol DailyBriefPrintable {
    var name: String { get }
    func dailyBrief() -> String
}
```

再看一个已经存在的类型：

```swift
struct StudyTask {
    let title: String
    let estimatedHours: Int
    var isFinished: Bool
}
```

如果你后面才意识到：

- `StudyTask` 也应该能输出简报

这时完全可以这样补：

```swift
extension StudyTask: DailyBriefPrintable {
    var name: String {
        return title
    }

    func dailyBrief() -> String {
        if isLongTask {
            return "今天优先完成这项长任务"
        } else {
            return "今天可以作为短任务快速完成"
        }
    }
}
```

这里最重要的不是语法花样，而是组织方式：

- 类型本体先负责核心数据
- 协议遵守可以按主题在扩展里补上

这样代码往往会更清楚。

## 一个完整示例：学习任务的扩展式组织

本章 demo 对应目录：

- `demos/projects/22-extensions-adding-capabilities`

这一章的示例会围绕两个类型展开：

- `StudyTask`
- `Int`

`StudyTask` 用来演示：

- 给自定义类型补方法
- 给自定义类型补计算属性
- 给自定义类型补协议遵守

`Int` 用来演示：

- 标准库类型也可以通过扩展补辅助能力

先看 `StudyTask` 的原始定义：

```swift
struct StudyTask {
    let title: String
    let estimatedHours: Int
    var isFinished: Bool
}
```

然后先补一个标准库辅助扩展：

```swift
extension Int {
    func studyHoursText() -> String {
        return "\(self) 小时"
    }
}
```

再通过扩展补 `StudyTask` 自己的方法和计算属性：

```swift
extension StudyTask {
    func summaryLine() -> String {
        let status = isFinished ? "已完成" : "未完成"
        return "\(title) - \(estimatedHours.studyHoursText()) - \(status)"
    }

    var isLongTask: Bool {
        return estimatedHours >= 2
    }
}
```

再补协议遵守：

```swift
protocol DailyBriefPrintable {
    var name: String { get }
    func dailyBrief() -> String
}

extension StudyTask: DailyBriefPrintable {
    var name: String {
        return title
    }

    func dailyBrief() -> String {
        return summaryLine()
    }
}
```

这几段组合起来之后，你会很直观地看到：

- 类型主体还是原来的样子
- 但外围能力已经被按主题补全了

如果再往前走一步，你还可以把这些主题继续拆到不同文件里，例如：

- `StudyTask.swift`：只放核心定义
- `StudyTask+Helpers.swift`：放格式化和计算属性
- `StudyTask+DailyBriefPrintable.swift`：放协议遵守

本章当前 demo 先不强制把文件拆开，但会先把这种“按主题分块”的组织方式明确表现出来。

## 扩展和直接修改原类型定义有什么区别

这两种方式都能让类型变得更强。

但它们在组织上有明显区别。

直接修改原类型定义，更像是：

- 把所有内容都写进一个地方

而扩展更像是：

- 先保留核心定义
- 再按功能分块补能力

所以当前阶段最稳妥的理解不是：

- 扩展一定比原定义更高级

而是：

- 当你希望代码按主题分块时，扩展会很有帮助

## 什么时候优先想到扩展

如果你以后写代码时拿不准要不要用扩展，可以先问自己下面几个问题。

### 1. 这个类型本体是不是已经很清楚了

如果核心定义已经清楚，而你只是想补一些辅助能力，扩展通常很合适。

### 2. 这些新增能力是不是围绕某个明确主题

例如：

- 格式化输出
- 简报能力
- 工具辅助方法

如果答案是“是”，那么把它们收进扩展通常会比继续往原定义里堆更清楚。

在真实项目里，这种“按主题分块”还经常会继续发展成：

- 同一个类型的不同扩展放在不同文件里

这样团队协作和后续维护通常都会更轻松。

### 3. 我是不是想给现有类型补协议遵守

这是扩展最自然的应用之一。

## 常见误区

### 1. 以为扩展是在“重新定义”类型

不是。

更稳妥的理解是：

- 扩展是在已有类型基础上补能力

### 2. 以为扩展只能给自己写的类型用

不是。

标准库类型也可以扩展，例如：

- `String`
- `Int`

### 3. 以为扩展里什么都能加

当前阶段最好先记住：

- 扩展常用于方法、计算属性、协议遵守
- 不要把它理解成“可以像类主体一样随便加所有东西”

### 4. 把本来属于核心定义的内容全都后移到扩展里

如果一个成员本来就是类型最核心的组成部分，那仍然应该先放在主体定义里。

## 本章练习与课后作业

如果你想把这一章“扩展到底帮你整理了什么”真正练一遍，建议直接从下面这个起始工程开始：

- 起始工程：`exercises/zh-CN/projects/22-extensions-adding-capabilities-starter`
- 练习草稿：`exercises/zh-CN/answers/22-extensions-adding-capabilities.md`

这个工程当前已经能运行，但不少辅助逻辑还散落在顶层函数里。你会看到：

- `studyHoursText(_:)` 还是顶层函数
- `isLongTask(_:)` 和 `summaryLine(_:)` 还没有围绕 `StudyTask` 组织
- `StudyTask` 也还没有按主题拆出协议遵守

这一章建议你完成下面这些重构：

1. 把 `studyHoursText(_:)` 改成 `Int` 的扩展。
2. 把 `isLongTask(_:)` 和 `summaryLine(_:)` 收进 `StudyTask` 扩展。
3. 用扩展让 `StudyTask` 遵守 `DailyBriefPrintable`。
4. 让主流程调用新的扩展成员，而不是继续依赖顶层函数。

完成后，你的代码至少应该表现出下面这些特征：

- `Int` 的时长文本转换不再依赖顶层函数
- `StudyTask` 的摘要和“是否长任务”判断更靠近类型本身
- 协议遵守可以单独放在一个扩展块里
- `main.swift` 的主流程更像“调用能力”，而不是“拼装细节”

这道练习最重要的不是让代码“变高级”，而是开始建立一种更清楚的组织方式：

- 核心定义放在主体里
- 补充能力放在扩展里
- 协议遵守可以按主题单独整理

## 本章小结

这一章最需要记住的是下面这组关系：

- `extension` 用来给已有类型补充能力
- 调用形式上，扩展方法和普通方法没有区别
- 扩展很适合补方法、计算属性和协议遵守
- 扩展不等于重新定义类型
- 当你想按主题组织能力时，扩展会非常有用

如果你现在已经能比较稳定地看懂下面这类代码：

- `extension 类型名 { ... }`
- 给已有类型补一个方法
- 给已有类型补一个计算属性
- 用扩展补一个协议遵守

那么这一章最重要的目标就已经完成了。

## 接下来怎么读

如果继续扩展这条主线，下一步很自然会进入：

- 错误处理

因为当前面这些类型和能力都逐渐变多之后，接下来一个非常现实的问题就是：

- 如果某个操作失败了，代码该怎样更清楚地表达

这通常会把主线带到：

- [23. 错误处理：让失败路径更清楚](./23-error-handling-clear-failure-paths.md)
