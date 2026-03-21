# 18. 面向对象入门：封装、职责与对象协作 练习草稿

对应章节：

- [18. 面向对象入门：封装、职责与对象协作](../../../docs/zh-CN/chapters/18-oop-basics-object-collaboration.md)

起始工程：

- `exercises/zh-CN/projects/18-oop-basics-object-collaboration-starter`

说明：

- 这一轮先提供统一题材的练习草稿，帮助你在真实一点的场景里练习重构。
- starter project 当前已经可以运行，但结构故意保持在“还不够好管理”的状态。
- 本文档先给出练习目标和参考重构方向，完整标准答案后续再补。

## 当前问题

starter project 里已经有：

- 学习中心名称
- 学生名称
- 计划名称
- 任务标题、时长、完成状态
- 输出进度和整体概览的流程

但这些内容现在仍然：

- 分散在顶层变量里
- 依赖顶层函数推进逻辑
- 由 `main.swift` 亲自管理所有状态

## 你需要完成的重构

1. 提取 `StudyPlan`，让任务和进度统计回到计划对象内部。
2. 提取 `Student`，让学生对象负责发起“完成任务”的动作。
3. 提取 `LearningCenter`，让学习中心对象负责输出整体概览。
4. 减少 `main.swift` 对内部状态的直接读写。

## 完成标准

完成后，你的代码至少应该表现出下面这些特征：

- `progressText()` 不再依赖顶层数组和顶层变量。
- `finishTask(at:)` 不再是顶层函数。
- `main.swift` 不再直接修改任务完成状态。
- 输出结果仍然和 starter project 大体一致。

## 参考重构方向

你可以按下面这个顺序进行：

1. 先把任务数组和进度统计收进 `StudyPlan`。
2. 再让 `Student` 持有自己的 `StudyPlan`。
3. 最后让 `LearningCenter` 统一输出学生进度。

当前阶段最重要的不是“类写得多漂亮”，而是：

- 这件事归谁管
- 这段逻辑该挂在哪个对象上
- `main.swift` 有没有从“总控台”退回到只负责串联流程
