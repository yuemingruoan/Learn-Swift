# 20. 多态：用统一接口处理不同对象 练习草稿

对应章节：

- [20. 多态：用统一接口处理不同对象](../../../docs/zh-CN/chapters/20-polymorphism-unified-interfaces.md)

起始工程：

- `exercises/zh-CN/projects/20-polymorphism-unified-interfaces-starter`

说明：

- starter project 当前已经有父类和几个子类。
- 但“统一汇报”仍然依赖 `as?` 和 `if-else` 分支。
- 这一题的重点不是增加功能，而是让你亲手把“外部分支判断”重构成“统一接口调用”。

## 当前问题

当前版本里：

- `StudentMember`
- `TeacherMember`
- `MentorMember`

都能表达自己的每日重点，但这个能力还没有收敛成父类接口。

所以调用方只能写：

- 一连串 `if let ... as? ...`
- 或者一连串 `if-else`

## 你需要完成的重构

1. 在 `LearningMember` 中定义统一接口，例如 `dailyFocus()`。
2. 让不同子类分别给出自己的实现。
3. 把 `printFocusWithoutPolymorphism(member:)` 的分支逻辑改成统一调用。
4. 保持现有输出语义基本不变。

## 完成标准

完成后，你的代码至少应该表现出下面这些特征：

- 外部不再需要逐个判断 `StudentMember` / `TeacherMember` / `MentorMember`。
- `[LearningMember]` 可以统一遍历。
- 调用方只需要写类似 `member.dailyFocus()` 的代码。
- 新增一个子类时，外部汇报流程不需要继续补分支。

## 参考重构方向

你可以按这个顺序来：

1. 先定义父类接口。
2. 再让各个子类 override。
3. 最后回到顶层，把分支函数压缩成统一调用。

这道练习最值得观察的不是语法，而是重构前后的差别：

- 重构前：调用方知道太多细节。
- 重构后：调用方只要求统一接口。
