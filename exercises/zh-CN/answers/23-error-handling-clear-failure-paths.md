# 23. 错误处理：让失败路径更清楚 练习答案

对应章节：

- [23. 错误处理：让失败路径更清楚](../../../docs/zh-CN/chapters/23-error-handling-clear-failure-paths.md)

如果你想一边看答案一边运行 starter project，可以打开：

- `exercises/zh-CN/projects/23-error-handling-clear-failure-paths-starter`

如果你想直接运行本章练习的参考工程，也可以打开：

- `exercises/zh-CN/answers/23-error-handling-clear-failure-paths`

说明：

- 本章两道题使用同一业务场景：解析一行学习任务文本
- starter project 已经提供了可运行骨架
- 本文档给出推荐实现与思路说明
- `exercises/zh-CN/answers/23-error-handling-clear-failure-paths` 则提供可直接运行的参考工程

## 练习 1：把一行文本解析为 `StudyTask`

题目：

- 基于 starter project 继续修改当前代码
- 不要求你从零重新搭建 `StudyTask` 或主流程
- 请把当前“粗粒度错误处理”改造成“细粒度错误处理”

```text
标题,时长,完成状态
```

例如：

```text
阅读错误处理章节,2,false
```

目标类型可以定义为：

```swift
struct StudyTask {
    let title: String
    let estimatedHours: Int
    var isFinished: Bool
}
```

你至少需要区分下面几类错误：

- 字段数量不正确
- 标题为空
- 时长不是整数
- 时长小于 0
- 完成状态不是 `true` 或 `false`

参考答案的核心思路是：

1. 把单一 `invalidLine` 拆成多个具体错误。
2. 在解析函数内部分别抛出这些错误。
3. 在调用方使用 `do-catch` 按错误原因分别处理。

参考答案示例：

```swift
struct StudyTask {
    let title: String
    let estimatedHours: Int
    var isFinished: Bool
}

enum StudyTaskParseError: Error {
    case wrongFieldCount(expected: Int, actual: Int)
    case emptyTitle
    case invalidEstimatedHours(text: String)
    case negativeEstimatedHours(Int)
    case invalidFinishedFlag(text: String)
}
```

如果还需要把错误转换成人类可读的提示，可以继续补一个方法：

```swift
extension StudyTaskParseError {
    func userMessage() -> String {
        switch self {
        case .wrongFieldCount(let expected, let actual):
            return "字段数量不对。期望 \(expected) 段，实际拿到 \(actual) 段。"
        case .emptyTitle:
            return "标题不能为空。"
        case .invalidEstimatedHours(let text):
            return "时长必须是整数，当前拿到的是：\(text)"
        case .negativeEstimatedHours(let value):
            return "时长不能是负数，当前拿到的是：\(value)"
        case .invalidFinishedFlag(let text):
            return "完成状态只能是 true 或 false，当前拿到的是：\(text)"
        }
    }
}
```

解析函数可以写成：

```swift
func parseFinishedFlag(_ text: String) throws -> Bool {
    let normalizedText = text.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

    switch normalizedText {
    case "true":
        return true
    case "false":
        return false
    default:
        throw StudyTaskParseError.invalidFinishedFlag(text: text)
    }
}

func parseStudyTask(from line: String) throws -> StudyTask {
    let parts = line
        .split(separator: ",", omittingEmptySubsequences: false)
        .map { String($0).trimmingCharacters(in: .whitespacesAndNewlines) }

    guard parts.count == 3 else {
        throw StudyTaskParseError.wrongFieldCount(expected: 3, actual: parts.count)
    }

    let title = parts[0]
    let estimatedHoursText = parts[1]
    let finishedFlagText = parts[2]

    guard !title.isEmpty else {
        throw StudyTaskParseError.emptyTitle
    }

    guard let estimatedHours = Int(estimatedHoursText) else {
        throw StudyTaskParseError.invalidEstimatedHours(text: estimatedHoursText)
    }

    guard estimatedHours >= 0 else {
        throw StudyTaskParseError.negativeEstimatedHours(estimatedHours)
    }

    let isFinished = try parseFinishedFlag(finishedFlagText)

    return StudyTask(title: title, estimatedHours: estimatedHours, isFinished: isFinished)
}
```

调用方可以写成：

```swift
do {
    let task = try parseStudyTask(from: line)
    print(task)
} catch let error as StudyTaskParseError {
    print(error.userMessage())
}
```

说明：

- 这一版的重点不是“抛出了错误”这一事实本身，而是失败原因被保留下来了。
- 一旦错误原因被区分，调用方就可以决定是提示用户、跳过记录，还是继续上抛。
- 这也是错误处理相对于 `Bool` 或统一提示语更有表达力的地方。

## 思考题：什么时候可以使用 `try!`？

题目：

- starter project 里已经保留了一份写死的可信示例数据 `trustedDemoLine`
- 请在练习 1 的基础上继续思考：这类数据在什么前提下可以使用 `try!`
- 本题不要求你把整份工程都改成 `try!`
- 重点是判断：什么场景下可以使用 `try!`，以及它为什么会让代码更简洁

请围绕下面两类输入场景进行思考：

- 场景一：输入来自用户在控制台中的实时输入
- 场景二：输入来自程序中写死的演示数据或测试数据

这一题的核心不是鼓励滥用 `try!`，而是帮助你建立更准确的边界判断。

参考结论如下：

1. 用户输入更适合 `do-catch`。  
原因是这类数据来自外部环境，失败是业务中的正常情况，因此应保留失败原因。

2. 写死的演示数据或测试数据，在前提明确时可以使用 `try!`。  
因为这些数据由当前代码完全控制，调用方可以主动保证其合法性。

3. `try!` 的简洁，主要体现在可以省略常规错误处理样板。  
例如：

```swift
let task = try! parseStudyTask(from: trustedDemoLine)
print(task)
```

这比下面这段更紧凑：

```swift
do {
    let task = try parseStudyTask(from: trustedDemoLine)
    print(task)
} catch {
    print(error)
}
```

4. 但 `try!` 的前提非常强。  
一旦调用方写下 `try!`，就等于在声明：

- 这里在逻辑上不应失败
- 如果失败，说明是程序员自己破坏了前提

5. 如果这个前提不成立，程序会在运行时直接出问题。  
因此，`try!` 并不是“更省事的通用写法”，而是只适用于少数高度可控场景的写法。

## 参考工程说明

如果你想直接运行参考实现，可以打开：

- `exercises/zh-CN/answers/23-error-handling-clear-failure-paths`

其中你会看到两部分内容：

- 练习 1 的完成版：细粒度错误建模与 `do-catch` 分类处理
- 思考题的对照版：同一份可信示例数据分别用 `do-catch` 与 `try!` 调用
