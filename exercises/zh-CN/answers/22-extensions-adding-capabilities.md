# 22. 扩展：给已有类型补充能力 练习草稿

对应章节：

- [22. 扩展：给已有类型补充能力](../../../docs/zh-CN/chapters/22-extensions-adding-capabilities.md)

起始工程：

- `exercises/zh-CN/projects/22-extensions-adding-capabilities-starter`

说明：

- starter project 当前已经能运行。
- 但 `StudyTask` 相关的辅助逻辑仍然散落在顶层函数里。
- 这一题的重点是“按主题重新组织代码”，不是继续增加功能。

## 当前问题

当前版本里已经有：

- `StudyTask`
- `studyHoursText(_:)`
- `isLongTask(_:)`
- `summaryLine(_:)`
- `dailyBrief(_:)`

但这些能力现在并没有围绕类型组织起来。

## 你需要完成的重构

1. 把 `studyHoursText(_:)` 改成 `Int` 的扩展。
2. 把 `isLongTask(_:)` 和 `summaryLine(_:)` 收进 `StudyTask` 扩展。
3. 用扩展让 `StudyTask` 遵守 `DailyBriefPrintable`。
4. 让主流程调用新的扩展成员，而不是继续依赖顶层函数。

## 完成标准

完成后，你的代码至少应该表现出下面这些特征：

- `Int` 的时长文本转换不再依赖顶层函数。
- `StudyTask` 的摘要和“是否长任务”判断更靠近类型本身。
- 协议遵守可以单独放在一个扩展块里。
- `main.swift` 的主流程更像“调用能力”，而不是“拼装细节”。

## 参考重构方向

你可以按下面这个顺序进行：

1. 先移动标准库辅助方法。
2. 再移动 `StudyTask` 的业务辅助逻辑。
3. 最后再补协议遵守。

如果你愿意，还可以继续把这些扩展按主题拆成不同文件；但当前阶段先把“核心定义”和“补充能力”分开，就已经足够有价值。
