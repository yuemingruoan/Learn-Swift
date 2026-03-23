# 25. 闭包：把函数当成值来传递 练习答案

对应章节：

- [25. 闭包：把函数当成值来传递](../../../docs/zh-CN/chapters/25-closures-functions-as-values.md)

如果你想一边看答案一边运行 starter project，可以打开：

- `exercises/zh-CN/projects/25-closures-functions-as-values-starter`

如果你想直接运行本章练习的参考工程，也可以打开：

- `exercises/zh-CN/answers/25-closures-functions-as-values`

说明：

- 本章作业围绕一个“任务筛选与排序面板”展开。
- starter project 已经能输出结果，但各种规则都被写死在不同函数里。
- 本章重点不是继续增加业务，而是把“固定流程”和“可变规则”拆开。

## 当前问题

starter project 里主要有下面几类重复：

- `filterUnfinishedTasks(_:)` 和 `filterLongTasks(_:)`
- `sortTasksByHours(_:)` 和 `sortTasksByTitle(_:)`
- `makeDailySummaries(_:)` 和 `makeReviewSummaries(_:)`

这些函数的问题并不是完全不同，而是：

- 流程结构一样
- 只是判断条件、比较规则或格式化规则不同

这正是闭包最适合介入的地方。

## 你需要完成的重构

1. 把重复的筛选函数改成一个接收闭包的统一版本。
2. 把重复的排序函数改成一个接收比较闭包的统一版本。
3. 把重复的摘要生成函数改成一个接收格式化闭包的统一版本。
4. 至少补一个“返回闭包”的小例子，建立闭包捕获的直觉。
5. 保持当前业务语义不变。

## 完成标准

完成后，你的代码至少应该表现出下面这些特征：

- `filtered` 这类固定流程只保留一份。
- 排序规则不再因为字段不同而复制函数。
- 摘要文案的变化来自外部传入的行为，而不是复制函数体。
- 读者能从代码里直观看到“闭包就是规则本身”。

## 参考重构方向

比较稳妥的顺序通常是：

1. 先把筛选收拢。
2. 再把排序收拢。
3. 最后处理摘要格式化，并加一个返回闭包的例子。

参考答案会接近下面这种结构：

```swift
struct StudyTaskCenter {
    let tasks: [StudyTask]

    func filtered(by rule: (StudyTask) -> Bool) -> [StudyTask] { ... }
    func sorted(by areInIncreasingOrder: (StudyTask, StudyTask) -> Bool) -> [StudyTask] { ... }
    func summaries(using formatter: (StudyTask) -> String) -> [String] { ... }
}

func makeStatusFormatter(prefix: String) -> (StudyTask) -> String { ... }
```

## 这一题最值得你反复确认的点

当你准备重构时，可以反复问自己：

- 这段代码的流程是不是固定的？
- 真正变化的，到底是“做法”还是“规则”？

如果变化的只是规则，那么闭包通常就很合适。

如果你发现自己只是把一个很长很复杂的函数体直接塞进闭包里，那通常说明：

- 你只是换了写法
- 还没有真正完成“拆规则”的重构

## 参考工程说明

如果你想直接运行参考实现，可以打开：

- `exercises/zh-CN/answers/25-closures-functions-as-values`

你会在里面看到三类核心重构：

- 用闭包参数统一筛选。
- 用闭包参数统一排序。
- 用返回闭包的方式生成不同摘要格式。
