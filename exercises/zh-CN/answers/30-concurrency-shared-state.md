# 30. 并发中的共享状态：当多个任务同时改数据时会发生什么 练习答案

对应章节：

- [30. 并发中的共享状态：当多个任务同时改数据时会发生什么](../../../docs/zh-CN/chapters/30-concurrency-shared-state.md)

如果你想一边看答案一边运行 starter project，可以打开：

- `exercises/zh-CN/projects/30-concurrency-shared-state-starter`

如果你想直接运行本章练习的参考工程，也可以打开：

- `exercises/zh-CN/answers/30-concurrency-shared-state`

说明：

- 本章作业不是修复题，而是识别题。
- starter project 里故意混合了几种不同外形：有些真的存在共享状态风险，有些只是并发推进但并不危险。
- 这道题的核心不是先想“怎么修”，而是先判断“哪里共享、哪里依赖旧状态、哪里依赖条件检查”。

## 当前问题

starter project 里一共放了 5 个案例：

- `IndependentLoads`
- `FinishedCountStore.markFinished`
- `NotesStore.append`
- `ProgressCache.update`
- `WorkshopCenter.register`

你需要先判断的是：

1. 哪些案例共享了同一份可变状态。
2. 哪些案例属于“先读后写”。
3. 哪些案例属于“先检查再修改”。
4. 哪些案例虽然并发推进，但没有共享状态风险。

## 参考答案

这道题比较稳妥的分类结果如下：

```swift
let answers = ExerciseAnswers(
    sharedStateCases: [
        "FinishedCountStore.markFinished",
        "NotesStore.append",
        "ProgressCache.update",
        "WorkshopCenter.register",
    ],
    readThenWriteCases: [
        "FinishedCountStore.markFinished",
        "NotesStore.append",
        "ProgressCache.update",
    ],
    checkThenActCases: [
        "WorkshopCenter.register",
    ],
    independentCases: [
        "IndependentLoads",
    ]
)
```

## 为什么这几类案例要这样分

### 1. `IndependentLoads`

这一段虽然是并发的，但它只是：

- 一项去取标题
- 一项去取提醒文本

它们之间没有共同修改同一份可变状态，所以它不属于共享状态风险案例。

### 2. `FinishedCountStore.markFinished`

它是最典型的“先读后写”：

- 先读 `finishedCount`
- 等一会儿
- 再基于旧值写回新值

如果两个任务都读到同一个旧值，就会丢失更新。

### 3. `NotesStore.append`

它表面上看是在“追加数组”，但代码实际做的是：

- 先拿一份旧数组快照
- 等一会儿
- 再基于旧数组生成新数组并整体写回

本质上仍然是“先读后写”。

### 4. `ProgressCache.update`

字典缓存写入也和上面一样：

- 先拿旧字典
- 等一会儿
- 再写回包含新键值的新字典

所以它同样属于共享状态里的“先读后写”。

### 5. `WorkshopCenter.register`

这一段最值得先认出来的是：

- 先检查 `seatsLeft > 0`
- 再在稍后的时间点真正扣减

这正是“先检查再修改”的经典并发表现。

## 这一题最重要的收获

这道题的真正目的不是让你记住 4 个字符串，而是建立一个更稳妥的判断顺序：

1. 先找是不是共享了同一份可变状态。
2. 再看代码有没有依赖“刚刚读到的旧值”。
3. 再看代码有没有依赖“刚刚检查过的条件”。
4. 最后才去想：应该怎样隔离、重构或修复。

这也是为什么下一章会自然接着讲 `actor`。
