# 24. 泛型：让同一套逻辑适配更多类型 练习答案

对应章节：

- [24. 泛型：让同一套逻辑适配更多类型](../../../docs/zh-CN/chapters/24-generics-reusable-abstractions.md)

如果你想一边看答案一边运行 starter project，可以打开：

- `exercises/zh-CN/projects/24-generics-reusable-abstractions-starter`

如果你想直接运行本章练习的参考工程，也可以打开：

- `exercises/zh-CN/answers/24-generics-reusable-abstractions`

说明：

- 本章作业围绕一个“学习资源调度中心”展开。
- starter project 当前已经能运行，但里面充满了“同结构、不同类型”的重复。
- 本章的重点不是继续堆业务功能，而是判断哪些地方应该用泛型，哪些地方应当保留重载。

## 当前问题

starter project 里主要有下面几类坏味道：

- `StudyTaskQueue` 和 `ChapterPlanQueue` 几乎完全一样。
- `duplicateTask(_:)` 和 `duplicateChapterPlan(_:)` 只有类型不同。
- `findTask(in:title:)` 和 `findChapterPlan(in:title:)` 也只是查找对象不同。
- `[Any]` 能运行，但它把类型关系抹平了。
- `describe(_:)` 这种真正“同名但实现不同”的地方，反而和前面的重复混在一起，不容易分清边界。

## 你需要完成的重构

1. 把两个重复队列收拢成一个泛型队列，例如 `StudyQueue<Element>`。
2. 把两个重复的复制函数收拢成一个泛型函数。
3. 把两个重复的查找函数收拢成一个带约束的泛型函数。
4. 保留 `describe(_:)` 这种真正适合用重载的地方。
5. 不改变当前输出的核心业务语义。

## 完成标准

完成后，你的代码至少应该表现出下面这些特征：

- “同结构、不同类型”的重复明显减少。
- 队列逻辑只保留一份定义。
- 查找函数通过约束清楚表达“为什么这里可以比较”。
- `Any` 只作为对比例子存在，而不是主流程核心结构。
- 重载和泛型的边界比 starter project 更清楚。

## 参考重构方向

最自然的重构顺序通常是：

1. 先把两个队列统一成一个泛型类型。
2. 再把 `duplicateXxx` 这类函数收拢成泛型函数。
3. 最后再处理“查找为什么能通用”，为它补上 `Equatable` 约束。

参考答案里，一个比较稳妥的结果会接近下面这样：

```swift
struct StudyQueue<Element> {
    var items: [Element] = []

    mutating func enqueue(_ item: Element) {
        items.append(item)
    }

    mutating func dequeue() -> Element? { ... }
    func peek() -> Element? { ... }
}

func duplicate<T>(_ value: T) -> [T] {
    return [value, value]
}

func findFirstMatch<T: Equatable>(in items: [T], target: T) -> T? { ... }
```

## 为什么这里不该把所有东西都改成泛型

这一题最容易出现的误区是：

- 只要看到两个函数名字一样，就强行抽成泛型

例如：

```swift
func describe(_ value: Int) { ... }
func describe(_ value: String) { ... }
```

这类写法其实更适合保留重载。

因为这里的问题不是：

- 同一套实现结构重复了

而是：

- 同一个动作名称，需要针对不同类型做不同展示

所以这道题真正要练的是判断标准：

- 逻辑结构相同，用泛型。
- 同名但实现不同，保留重载。

## 参考工程说明

如果你想直接运行参考实现，可以打开：

- `exercises/zh-CN/answers/24-generics-reusable-abstractions`

你会在里面看到三件最核心的重构结果：

- 泛型队列替代了两套重复容器。
- 泛型函数替代了重复的复制与查找逻辑。
- `Any` 与重载仍然存在，但它们只出现在真正合理的位置上。
