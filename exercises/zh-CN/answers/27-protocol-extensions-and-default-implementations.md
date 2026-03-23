# 27. 协议扩展与默认实现：把抽象和复用放在一起 练习答案

对应章节：

- [27. 协议扩展与默认实现：把抽象和复用放在一起](../../../docs/zh-CN/chapters/27-protocol-extensions-and-default-implementations.md)

如果你想一边看答案一边运行 starter project，可以打开：

- `exercises/zh-CN/projects/27-protocol-extensions-and-default-implementations-starter`

如果你想直接运行本章练习的参考工程，也可以打开：

- `exercises/zh-CN/answers/27-protocol-extensions-and-default-implementations`

说明：

- 本章作业围绕一个“统一进度展示系统”展开。
- starter project 已经能输出进度，但共享逻辑散落在每个具体类型里。
- 本章重点是让你判断：哪些东西应该进协议，哪些应该进协议扩展，哪些应该继续留在具体类型里。

## 当前问题

starter project 里最明显的问题是：

- `StudyTask`、`ChapterPlan`、`ReviewSession` 都各自实现了一套 `isFinished`
- `progressRateText`
- `progressSummary()`
- `nextSuggestion()`

这些逻辑高度重复，但目前没有被抽象到统一位置。

## 你需要完成的重构

1. 提炼出一个共同协议，例如 `ProgressTrackable`。
2. 把多个类型都需要的最小信息收进协议要求。
3. 把真正共享的行为收进协议扩展。
4. 保持当前业务语义不变。

## 完成标准

完成后，你的代码至少应该表现出下面这些特征：

- 多个类型可以一起遵守同一个协议。
- 完成判断和进度摘要不再复制粘贴。
- 共享逻辑集中在协议扩展里，而不是散落在每个类型里。
- 具体类型仍然只保留自己的核心数据。

## 参考重构方向

比较自然的顺序通常是：

1. 先观察三个类型到底有哪些字段完全一致。
2. 用这些共同字段定义协议要求。
3. 再把重复方法迁移到协议扩展。

参考答案会接近下面这种结构：

```swift
protocol ProgressTrackable {
    var title: String { get }
    var completedSteps: Int { get }
    var totalSteps: Int { get }
}

extension ProgressTrackable {
    var isFinished: Bool { ... }
    var progressRateText: String { ... }
    func progressSummary() -> String { ... }
    func nextSuggestion() -> String { ... }
}
```

## 这一题最值得反复确认的判断标准

如果你拿不准某个成员该放哪，可以先问：

- 这个成员是不是所有遵守者都需要？
- 这个逻辑是不是只依赖协议要求就能成立？

如果两个答案都偏向“是”，那么它通常就很适合进入协议扩展。

如果答案是“不是”，那它更可能应该继续留在具体类型里。

## 参考工程说明

如果你想直接运行参考实现，可以打开：

- `exercises/zh-CN/answers/27-protocol-extensions-and-default-implementations`

参考工程里最值得观察的地方是：

- 主流程怎样统一处理多种不同类型
- 协议扩展怎样减少重复
- 具体类型怎样只保留核心数据
