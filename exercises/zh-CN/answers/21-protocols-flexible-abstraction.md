# 21. 协议：比继承更灵活的抽象方式 练习草稿

对应章节：

- [21. 协议：比继承更灵活的抽象方式](../../../docs/zh-CN/chapters/21-protocols-flexible-abstraction.md)

起始工程：

- `exercises/zh-CN/projects/21-protocols-flexible-abstraction-starter`

说明：

- starter project 里的几个类型都能输出汇报。
- 但它们不是自然的父子关系，所以当前还只能分开处理。
- 这道题的重点是让你把“共同能力”抽出来，而不是强行继续造继承树。

## 当前问题

当前版本里：

- `Student` 是 `class`
- `Teacher` 是 `class`
- `StudyRobot` 是 `struct`

它们都能生成简报，但输出流程目前仍然按具体类型拆开写。

## 你需要完成的重构

1. 定义 `DailyBriefPrintable`。
2. 让 `Student`、`Teacher`、`StudyRobot` 一起遵守这个协议。
3. 把当前的分别输出函数改成统一遍历 `[DailyBriefPrintable]`。
4. 保持当前业务语义不变。

## 完成标准

完成后，你的代码至少应该表现出下面这些特征：

- `class` 和 `struct` 可以一起参与统一抽象。
- 输出流程不再需要分开写三段循环。
- 调用方主要依赖协议要求，而不是依赖具体类型细节。

## 参考重构方向

你可以优先把协议收得很小：

- 一个名字
- 一段汇报

然后再做两步：

1. 让三个具体类型分别遵守。
2. 把三个数组或三个分支，改成一个统一数组遍历。

如果你发现自己又想回到“让它们互相继承”，可以先停一下，重新问自己：

- 我现在关心的是它们是什么，还是它们能做什么？
