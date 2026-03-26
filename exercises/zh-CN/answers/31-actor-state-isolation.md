# 31. Actor：隔离共享可变状态 练习答案

对应章节：

- [31. Actor：隔离共享可变状态](../../../docs/zh-CN/chapters/31-actor-state-isolation.md)

如果你想一边看答案一边运行 starter project，可以打开：

- `exercises/zh-CN/projects/31-actor-state-isolation-starter`

如果你想直接运行本章练习的参考工程，也可以打开：

- `exercises/zh-CN/answers/31-actor-state-isolation`

说明：

- 这道题直接承接上一章的冲突案例。
- starter project 里不是没有功能，而是“共享状态组织得不安全”。
- 本题的核心不是把 `class` 机械改成 `actor`，而是把真正要保持一致的状态修改收进 actor 边界里。

## 当前问题

starter project 里有两类典型问题：

1. `StudyProgressStore` 的完成数更新仍然会丢失。
2. `WorkshopCenter` 的名额检查和扣减仍然会被并发破坏。

这两个问题共同说明：

- 共享状态还没有被隔离好
- 或者虽然开始隔离了，但关键业务动作仍然跨过了等待点

## 你需要完成的重构

1. 把 `StudyProgressStore` 改成 `actor`。
2. 把 `WorkshopCenter` 改成 `actor`。
3. 把“检查名额”和“真正扣减名额”收进同一个不等待的关键动作。
4. 调整调用点，补上需要的 `await`。

## 完成标准

完成后，你的代码至少应该表现出下面这些特征：

- 两个并发任务同时更新完成数后，最终结果稳定是 `2`。
- 两个人并发报名只有一个会成功。
- `acceptedNames` 里只有一个名字。
- `seatsLeft` 不会变成负数。

## 参考重构方向

这一题比较稳妥的做法通常是：

1. 让共享状态容器本身变成 `actor`。
2. 把真正的关键状态变更放进一个不跨 `await` 的 actor 方法。
3. 把等待通知、打印结果这类不影响一致性的动作放到关键修改之后。

参考答案里接近下面这种结构：

```swift
actor StudyProgressStore {
    private var finishedCount = 0

    func markFinished() {
        finishedCount += 1
    }

    func currentCount() -> Int {
        return finishedCount
    }
}

actor WorkshopCenter {
    private var seatsLeft = 1
    private var acceptedNames: [String] = []

    func reserveSeat(for name: String) -> Bool {
        guard seatsLeft > 0 else { return false }
        seatsLeft -= 1
        acceptedNames.append(name)
        return true
    }
}
```

## 为什么不是“改成 actor 就自动万事大吉”

这是本题最容易误解的地方。

`actor` 解决的是：

- 外部代码不能再像碰普通共享对象那样，随手并发乱改内部状态

但它不会自动替你修好下面这种业务结构：

- 前半段先检查状态
- 中间等待
- 后半段再基于旧检查结果去修改状态

所以这题真正要学会的是：

- 不只是“状态放进 actor”
- 还要“把必须保持一致的那一小段业务动作收进不等待的边界里”

## 参考工程说明

如果你想直接运行参考实现，可以打开：

- `exercises/zh-CN/answers/31-actor-state-isolation`

你最应该重点观察的是：

- 完成数为什么变得稳定
- 为什么最后只会有一个人报名成功
- 为什么等待通知这件事可以放在关键状态修改之后
