# 26. 集合高阶操作：用 map、filter、reduce 整理数据 练习答案

对应章节：

- [26. 集合高阶操作：用 map、filter、reduce 整理数据](../../../docs/zh-CN/chapters/26-higher-order-collection-operations.md)

如果你想一边看答案一边运行 starter project，可以打开：

- `exercises/zh-CN/projects/26-higher-order-collection-operations-starter`

如果你想直接运行本章练习的参考工程，也可以打开：

- `exercises/zh-CN/answers/26-higher-order-collection-operations`

说明：

- 本章作业不是让你从零造一个新系统，而是让你识别“哪些循环本质上已经在做高阶操作”。
- starter project 特意保留了大量循环写法。
- 重构时请优先保持可读性，而不是追求把所有代码都链成一行。

## 当前问题

starter project 里已经出现了很多非常典型的集合处理循环：

- 用循环筛出未完成任务
- 用循环提取标题
- 用循环生成摘要文本
- 用循环累加总时长和完成数量
- 用 `if let + append` 清洗合法整数

这些循环本身没有错。

但如果你已经学到了本章内容，那么你应该开始识别：

- 哪些循环更接近 `filter`
- 哪些更接近 `map`
- 哪些更接近 `reduce`
- 哪些更接近 `compactMap`

## 你需要完成的重构

1. 把“筛选未完成任务”的循环改成 `filter`。
2. 把“提取标题”和“生成摘要文本”的循环改成 `map`。
3. 把“统计总时长”和“统计完成数量”的循环改成 `reduce`。
4. 把“清洗有效时长”的 `if let + append` 改成 `compactMap`。
5. 保留那些改成高阶操作后反而更难读的地方。

## 完成标准

完成后，你的代码至少应该表现出下面这些特征：

- 每一段集合处理意图更直接。
- `filter` / `map` / `reduce` / `compactMap` 的使用边界更清楚。
- 读代码的人能看出“这段代码到底在筛选、转换、汇总还是清洗”。
- 代码不是为了炫技而链式调用，而是为了表达清楚。

## 参考重构方向

这一题最好的做法通常不是“闷头改”，而是：

1. 先给每段旧循环起一个语义名字。
2. 再找它最接近哪一种高阶操作。
3. 最后改写。

参考答案里，你会看到类似下面这种对应关系：

```swift
let unfinishedTasks = tasks.filter { task in
    task.isFinished == false
}

let titles = tasks.map { task in
    task.title
}

let totalHours = tasks.reduce(0) { partialResult, task in
    partialResult + task.estimatedHours
}

let validHours = rawHourTexts.compactMap { text in
    Int(text)
}
```

## 这一题最容易出的问题

### 1. 还没看懂循环在做什么，就直接硬改

这往往会让你得到一段“看起来更高级、其实更难读”的代码。

### 2. 把所有逻辑都链起来

高阶操作的重点是表达意图，不是把代码缩成一行。

### 3. 把 `map` 和 `compactMap` 混掉

如果你的旧循环里出现的是：

- 每个元素都要转换

更像 `map`。

如果出现的是：

- 只有转换成功时才追加结果

更像 `compactMap`。

## 参考工程说明

如果你想直接运行参考实现，可以打开：

- `exercises/zh-CN/answers/26-higher-order-collection-operations`

你会在里面看到两层线索：

- 哪些地方已经被高阶操作替代
- 哪些地方仍然保留了更直白的循环写法

这正是本章最重要的判断标准之一。
