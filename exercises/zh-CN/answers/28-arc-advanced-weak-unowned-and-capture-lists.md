# 28. 选读：ARC 进阶：weak、unowned 与循环引用 练习答案

对应章节：

- [28. 选读：ARC 进阶：weak、unowned 与循环引用](../../../docs/zh-CN/chapters/28-arc-advanced-weak-unowned-and-capture-lists.md)

如果你想一边看答案一边运行 starter project，可以打开：

- `exercises/zh-CN/projects/28-arc-advanced-weak-unowned-and-capture-lists-starter`

如果你想直接运行本章练习的参考工程，也可以打开：

- `exercises/zh-CN/answers/28-arc-advanced-weak-unowned-and-capture-lists`

说明：

- 本章是选读，所以这道作业更像“分析并修复一个能跑但释放异常的项目”。
- starter project 已经把典型错误都放进去了：对象互相强持有、所属关系写成强引用、闭包强捕获 `self`。
- 这道题的核心不是背关键字，而是先画清关系，再决定写法。

## 当前问题

starter project 里主要有三类问题：

1. `Teacher` 和 `Classroom` 互相强持有。
2. `ChapterNote` 对 `Chapter` 的所属关系写成了普通强引用。
3. `StudySession` 的回调闭包强捕获了 `self`。

这些问题共同导致的现象是：

- 某些对象该释放时没有释放
- 或者它们的关系表达得不够准确

## 你需要完成的重构

1. 修复 `Teacher` 和 `Classroom` 之间的循环引用。
2. 判断 `ChapterNote` 对 `Chapter` 应该是 `weak` 还是 `unowned`。
3. 修复 `StudySession` 的闭包捕获问题。
4. 保留当前业务语义，并让释放顺序更容易被观察。

## 完成标准

完成后，你的代码至少应该表现出下面这些特征：

- `teacher = nil`、`classroom = nil` 后，两个对象都能释放。
- `Chapter` 释放时，它持有的 `notes` 也能一起结束生命周期。
- `session = nil` 后，`StudySession` 不会被闭包继续强留在内存里。
- 你能解释为什么这里分别用了 `weak`、`unowned`、`[weak self]`。

## 参考重构方向

这一题最好的做法通常不是直接改关键字，而是：

1. 先画清谁强持有谁。
2. 再找出哪条关系不该继续参与强引用计数。
3. 最后根据“是否允许变空”决定 `weak` 还是 `unowned`。

参考答案里会接近下面这三种处理：

- `Classroom.teacher` 改成 `weak var teacher: Teacher?`
- `ChapterNote.chapter` 改成 `unowned let chapter: Chapter`
- 回调里改成 `[weak self]`

## 为什么这里不是所有地方都用 `weak`

这是本题最容易犯的一个错误。

如果你只是把所有关系都改成 `weak`，表面上可能也能打破环，但语义会变得很乱。

例如 `ChapterNote` 和 `Chapter` 的关系，更自然的判断通常是：

- 笔记不应该处在“没有所属章节”的状态里

所以这里比起 `weak`，更适合用：

- `unowned`

而 `Teacher` 和 `Classroom` 的关系则不同：

- 教室可以暂时没有老师
- 老师也可以先离开

这种关系更自然地允许变成空，因此更适合：

- `weak`

## 参考工程说明

如果你想直接运行参考实现，可以打开：

- `exercises/zh-CN/answers/28-arc-advanced-weak-unowned-and-capture-lists`

参考工程里最值得重点观察的是：

- 当变量被设成 `nil` 之后，哪些对象先释放
- 哪些引用会自动清空
- 为什么闭包还能存在，但其中的 `self` 已经可能为 `nil`
