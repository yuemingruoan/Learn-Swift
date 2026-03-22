# 23. 错误处理：让失败路径更清楚

## 阅读导航

- 前置章节：[08. Optional 入门](./08-optional-basics.md)、[12. 函数与代码复用](./12-functions-and-code-reuse.md)、[22. 扩展：给已有类型补充能力](./22-extensions-adding-capabilities.md)
- 上一章：[22. 扩展：给已有类型补充能力](./22-extensions-adding-capabilities.md)
- 建议下一章：24. 泛型：让同一套逻辑适配更多类型（待补充）
- 下一章：24. 泛型：让同一套逻辑适配更多类型（待补充）
- 适合谁先读：已经能够编写较完整程序，并希望更清楚地区分成功路径与失败路径的读者

## 本章目标

学完这一章后，你应该能够：

- 理解失败路径同样需要清楚表达
- 区分 `Optional`、`Bool` 与 `throw` 的适用场景
- 看懂 `Error`、`throws`、`throw`、`do-catch` 的基础写法
- 使用自定义错误类型表达不同失败原因
- 理解 `try?` 与 `try!` 的基本边界
- 将输入校验逻辑整理为更清晰的错误处理流程

## 本章对应目录

- 对应项目目录：`demos/projects/23-error-handling-clear-failure-paths`
- 练习与课后作业：`exercises/zh-CN/answers/23-error-handling-clear-failure-paths.md`

建议你这样使用：

- 先阅读正文，建立错误处理的基本语义边界
- 再运行 `demos/projects/23-error-handling-clear-failure-paths`
- 对照输出结果，观察不同失败原因如何被分别处理

## 为什么现在学习错误处理

前面几章中，你已经接触过多种可能失败的操作，例如：

- 读取输入
- 字符串转数字
- 数据范围校验
- 按约定格式解析文本

在入门阶段，这类情况通常会先写成：

```swift
if let score = Int(text) {
    if score >= 0 && score <= 100 {
        print("输入有效")
    } else {
        print("输入无效")
    }
} else {
    print("输入无效")
}
```

这种写法可以工作，但有一个明显问题：

- 不同失败原因被压缩成了同一种结果

例如，空输入、格式错误、数值越界，都会落到“输入无效”。这样做虽然简化了流程，却削弱了代码的表达力。

因此，本章关注的不是“如何避免失败”，而是：

- 当失败发生时，如何准确表达失败原因

## `Optional`、`Bool` 与 `throw` 的边界

这三种写法都可能与“失败”相关，但语义并不相同。

## `Optional`：适合表达“可能没有值”

例如：

```swift
let text = readLine()
```

这里更关心的是：

- 是否读取到了一个值

因此，`Optional` 适合表达“有值 / 无值”，但通常不负责解释“为什么没有值”。

## `Bool`：适合表达“判断结果”

例如：

```swift
func isValidScore(_ score: Int) -> Bool {
    return score >= 0 && score <= 100
}
```

这里 `Bool` 表示的是：

- 合法
- 不合法

它适合快速判断，但不适合承载详细失败信息。

## `throw`：适合表达“失败，且失败原因重要”

如果程序不仅需要知道“失败了”，还需要知道“为何失败”，就应当考虑错误处理。

例如：

```swift
enum ScoreInputError: Error {
    case emptyText
    case notANumber
    case outOfRange
}
```

这样，失败原因便成为了类型系统中的一部分。调用方可以据此分别处理不同情况，而不必统一落入同一个分支。

## 先看错误处理的基本语法

### 定义错误类型

最常见的入门写法如下：

```swift
enum 错误类型名: Error {
    case 错误情况一
    case 错误情况二
}
```

例如：

```swift
enum InputError: Error {
    case emptyText
    case notANumber
}
```

这里的要点是：

- `Error` 用来标记“这是一个错误类型”
- `enum` 适合枚举有限且明确的失败情况

### 声明可能抛错的函数

```swift
func 函数名(参数) throws -> 返回类型 {
    ...
}
```

例如：

```swift
func parseScore(_ text: String) throws -> Int {
    ...
}
```

`throws` 表示：

- 该函数在执行过程中可能失败

### 抛出错误

```swift
throw 某个错误值
```

例如：

```swift
if text.isEmpty {
    throw InputError.emptyText
}
```

这里的 `throw` 并不是打印提示，而是将失败原因交给外部调用方。

### 接住错误

```swift
do {
    let value = try 可能失败的函数()
    print(value)
} catch {
    print(error)
}
```

可以先这样理解：

- `try` 表示调用一个可能抛错的函数
- `do` 表示准备接收其结果
- `catch` 表示在失败时处理错误

## 与 Java `try-catch` 的对照

对有 Java 基础的读者来说，Swift 这一组写法最容易困惑的地方，通常不在“错误处理是什么”，而在“语法为什么这样分布”。

可以先抓住下面几条对应关系。

### 1. Swift 的 `do-catch`，大体对应 Java 的 `try-catch`

Java 常见写法如下：

```java
try {
    int score = parseScore(text);
    System.out.println(score);
} catch (InputException e) {
    System.out.println(e.getMessage());
}
```

Swift 对应写法如下：

```swift
do {
    let score = try parseScore(text)
    print(score)
} catch {
    print(error)
}
```

两者在职责上基本一致：

- 正常代码放在主块中执行
- 失败后转入 `catch`

区别在于，Swift 用 `do` 作为主块关键字，而不是继续使用 `try` 开头整个代码块。

### 2. Swift 要求在“调用点”显式写 `try`

这是和 Java 最容易产生直觉冲突的一点。

在 Java 中，只要代码位于 `try { ... }` 块内部，调用可能抛异常的方法时通常不需要额外标记：

```java
try {
    parseScore(text);
}
```

而在 Swift 中，即使已经位于 `do` 块中，调用可能抛错的函数时仍然要显式写 `try`：

```swift
do {
    try parseScore(text)
}
```

也就是说，Swift 会把“这里可能失败”明确标在具体表达式前，而不是只交给外层代码块去暗示。

### 3. Swift 的 `throws` 只表示“可能抛错”，不在函数签名中列出错误类型

例如：

```swift
func parseScore(_ text: String) throws -> Int
```

Java 中常见的是：

```java
int parseScore(String text) throws InputException
```

这里有一个重要差异：

- Java 会在函数签名中写出抛出的异常类型
- Swift 只写 `throws`，不在签名层列出具体错误类型

因此，Swift 当前阶段更适合理解为：

- 这个函数可能失败
- 至于具体失败成什么，由函数实现和调用方的 `catch` 一起决定

### 4. Swift 的错误通常不是继承一棵异常类树来组织

Java 初学者往往习惯于：

- `Throwable`
- `Exception`
- `RuntimeException`

这一套继承层次。

Swift 的入门写法通常更直接：

- 让某个 `enum` 遵守 `Error`
- 用不同 `case` 表达不同失败原因

例如：

```swift
enum InputError: Error {
    case emptyText
    case notANumber
    case outOfRange
}
```

这种写法的重点是：

- 按业务语义列出失败情况

而不是先建立一棵复杂的异常类型层次。

### 5. Swift 的 `catch` 不仅能按类型接，还能直接按错误模式区分

例如：

```swift
do {
    let score = try parseScore(text)
    print(score)
} catch InputError.emptyText {
    print("请输入内容")
} catch InputError.notANumber {
    print("请输入整数")
} catch InputError.outOfRange {
    print("请输入 0 到 100 之间的数字")
}
```

这里的思路更接近：

- 直接根据错误值本身进行匹配

这和前面章节里讲过的 `enum` 与 `switch` 的思路是连贯的。

如果你已经有 Java 基础，可以先用一句话建立映射：

- Java 更像是“在 `try-catch` 结构里处理异常对象”
- Swift 更像是“在 `do-catch` 结构里，对显式标记了 `try` 的抛错表达式进行处理”

## 一个最小示例：解析分数输入

```swift
enum ScoreInputError: Error {
    case emptyText
    case notANumber
    case outOfRange
}

func parseScore(_ text: String) throws -> Int {
    let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)

    if trimmed.isEmpty {
        throw ScoreInputError.emptyText
    }

    guard let score = Int(trimmed) else {
        throw ScoreInputError.notANumber
    }

    guard score >= 0 && score <= 100 else {
        throw ScoreInputError.outOfRange
    }

    return score
}
```

这段代码有两个特点：

- 成功路径只负责返回合法结果
- 失败路径通过不同错误分别表达

于是调用方可以写成：

```swift
do {
    let score = try parseScore("105")
    print(score)
} catch ScoreInputError.emptyText {
    print("请输入内容")
} catch ScoreInputError.notANumber {
    print("请输入整数")
} catch ScoreInputError.outOfRange {
    print("请输入 0 到 100 之间的数字")
}
```

此时，失败原因与处理方式之间的对应关系就比较清楚了。

## `do-catch` 的职责

`do-catch` 的核心作用不是增加语法层次，而是分离职责：

- throwing 函数负责定义失败方式
- 调用方负责决定失败后的处理方式

这种分工可以避免把所有校验、提示与分支都堆在同一个函数中。

## 一个完整示例：解析学习任务文本

本章 demo 对应目录：

- `demos/projects/23-error-handling-clear-failure-paths`

示例场景是将一行文本解析为 `StudyTask`：

```text
标题,时长,完成状态
```

例如：

```text
阅读错误处理章节,2,false
```

目标类型如下：

```swift
struct StudyTask {
    let title: String
    let estimatedHours: Int
    var isFinished: Bool
}
```

这个过程可能出现多种失败：

- 字段数量不对
- 标题为空
- 时长不是整数
- 时长小于 0
- 完成状态不是 `true` 或 `false`

因此，demo 将错误单独建模为：

```swift
enum StudyTaskParseError: Error {
    case wrongFieldCount(expected: Int, actual: Int)
    case emptyTitle
    case invalidEstimatedHours(text: String)
    case negativeEstimatedHours(Int)
    case invalidFinishedFlag(text: String)
}
```

再由解析函数抛出这些错误：

```swift
func parseStudyTask(from line: String) throws -> StudyTask {
    ...
}
```

这样，调用方可以明确区分：

- 需要重新输入
- 需要修正格式
- 需要修正数据范围

这正是“失败路径更清楚”的具体体现。

## 为什么自定义错误类型有价值

如果所有失败都写成：

```swift
throw SomeError.failed
```

虽然也能表示失败，但信息仍然过于粗糙。

自定义错误类型的价值在于：

- 失败原因可以被拆分
- 调用方更容易写出正确处理逻辑
- 代码含义更清楚，后续维护成本更低

当你看到 `.emptyTitle`、`.invalidEstimatedHours(text: ...)` 这类成员时，通常不需要额外阅读注释，就能理解代码正在防御什么问题。

## `try?` 与 `try!`

### `try?`：将失败折叠为 `nil`

例如：

```swift
let task = try? parseStudyTask(from: text)
```

它的含义是：

- 成功时得到结果
- 失败时得到 `nil`

因此，`try?` 适合以下场景：

- 当前只关心成功或失败
- 不需要保留具体错误原因

但如果业务需要区分失败原因，就不应过早写成 `try?`。

### `try!`：断言此处不会失败

例如：

```swift
let task = try! parseStudyTask(from: "阅读章节,2,false")
```

它表示：

- 调用方确信这里不会抛错 (**不建议在代码中使用!**)

如果使用`try!` 判断错误，若代码抛出错误，程序会在运行时直接崩溃。因此，本章不把 `try!` 作为常规输入处理方案推荐。

更稳妥的结论是：

- `try!` 只适用于极少数你能够严格保证成功的场景

## 常见误区

### 1. 以为错误处理只是多写一个提示语

错误处理的重点不在提示语本身，而在于：

- 失败原因是否被清楚建模

### 2. 以为有 `Optional` 就不需要错误处理

`Optional` 适合表达“有没有值”，但不一定适合表达“为什么失败”。

### 3. 以为 `throw` 之后函数仍会沿成功路径继续执行

不会。一旦执行到 `throw`，当前函数的成功返回路径就结束了。

### 4. 以为错误处理只是“高级语法”

错误处理首先是一种表达方式，用来区分不同失败路径，而不是为了增加语言特性数量。

## 本章练习与课后作业

如果你希望把本章内容真正落到代码中，可以继续完成下面两道作业：

- 作业答案：`exercises/zh-CN/answers/23-error-handling-clear-failure-paths.md`
- 起始工程：`exercises/zh-CN/projects/23-error-handling-clear-failure-paths-starter`
- 参考答案工程：`exercises/zh-CN/answers/23-error-handling-clear-failure-paths`

### 练习 1：把一行文本解析为 `StudyTask`

这一题延续本章 demo 的场景。

这一题不要求你从零开始搭骨架。

starter project 已经具备：

- `StudyTask`
- 一个可以运行的 `parseStudyTask(from:)`
- 一个可以运行的主流程

但当前版本仍然把多种失败原因压缩成同一个错误。

你需要在现有代码基础上继续修改：

```swift
func parseStudyTask(from line: String) throws -> StudyTask
```

输入格式如下：

```text
标题,时长,完成状态
```

你至少需要区分下面几类错误：

- 字段数量不正确
- 标题为空
- 时长不是整数
- 时长小于 0
- 完成状态不是 `true` 或 `false`

这一题的重点是：

- 把失败原因建模成明确的错误类型
- 用 `throw` 抛出不同失败原因
- 用 `do-catch` 在主流程中分别处理这些错误

### 思考题：什么时候可以使用 `try!`？

starter project 中已经保留了一份写死的可信示例数据 `trustedDemoLine`。

这一题不是让你把主流程全部改成 `try!`，而是要求你判断：

- 什么场景下可以使用 `try!`
- 它为什么会让代码更简洁

建议你对比下面两类场景：

- 输入来自用户在控制台中的实时输入
- 输入来自程序中写死的演示数据或测试数据

这一题的重点不是“会不会写 `try!`”，而是：

- 理解 `try!` 只适合前提极强的少数场景
- 理解它的简洁，来自于省略错误处理样板，而不是来自于更强的容错能力

如果你发现自己拿不准某处能不能写 `try!`，可以先问自己：

- 这里的失败是业务中的正常情况，还是程序员自己破坏了前提？

## 本章小结

这一章最需要记住的是：

- `Optional` 更适合表达“可能没有值”
- `Bool` 更适合表达“判断结果”
- `throw` 更适合表达“失败，且失败原因重要”
- `throws` 表示函数可能失败
- `throw` 表示将失败原因交给外部
- `do-catch` 表示由调用方接住并处理错误
- 自定义错误类型可以显著提升失败路径的清晰度

如果你已经能够理解下面这类代码：

- `enum SomeError: Error { ... }`
- `func xxx() throws -> ...`
- `throw SomeError.xxx`
- `do { try ... } catch { ... }`

并且开始知道何时应当保留失败原因，那么本章的核心目标就已经达到。
