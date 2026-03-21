# 19. 继承：is-a、has-a 与类型层次设计 练习草稿

对应章节：

- [19. 继承：is-a、has-a 与类型层次设计](../../../docs/zh-CN/chapters/19-inheritance-is-a-has-a-modeling.md)

起始工程：

- `exercises/zh-CN/projects/19-inheritance-is-a-has-a-starter`

说明：

- 这一轮先提供统一题材练习草稿，重点是让你在同一个学习中心场景里练习建模。
- starter project 已经能运行，但 `StudentMember` 和 `TeacherMember` 之间存在明显重复。
- 本文档当前先给出练习目标和参考方向，完整答案后续再补。

## 当前问题

starter project 里已经有：

- `StudentMember`
- `TeacherMember`
- `Projector`
- `StudyCenter`

但当前结构还没有把下面几种关系分清：

- 哪些类型更像 `is-a`
- 哪些关系更像 `has-a`
- 哪些动作更像 `uses-a`

## 你需要完成的重构

1. 提取 `LearningMember`，把 `name` 和通用介绍逻辑收进去。
2. 让 `StudentMember` 和 `TeacherMember` 继承 `LearningMember`。
3. 保持 `StudyCenter has-a Projector` 这种组合关系。
4. 保持 `TeacherMember uses-a Projector` 这种使用关系。

## 完成标准

完成后，你的代码至少应该表现出下面这些特征：

- `StudentMember is-a LearningMember`。
- `TeacherMember is-a LearningMember`。
- `StudyCenter` 不是 `Projector` 的子类。
- `TeacherMember` 通过方法使用 `Projector`，而不是把它当成父类。

## 参考重构方向

你可以先问自己三句话：

- 学生是不是一种成员。
- 老师是不是一种成员。
- 学习中心是不是一种投影仪。

如果前两句说得通、最后一句说不通，那么当前阶段最自然的方向就是：

- `LearningMember` 做父类
- `StudyCenter` 继续通过属性持有 `Projector`
- `TeacherMember` 继续在动作里调用 `use(projector:)`
