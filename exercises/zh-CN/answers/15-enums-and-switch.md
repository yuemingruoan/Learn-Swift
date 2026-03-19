# 15. 枚举与 switch：用类型表示有限情况 练习答案

对应章节：

- [15. 枚举与 switch：用类型表示有限情况](../../../docs/zh-CN/chapters/15-enums-and-switch.md)

如果你想一边看答案一边运行示例，也可以打开对应工程：

- `demos/projects/15-enums-and-switch`

如果你想直接运行课后作业的参考工程，也可以打开：

- `exercises/zh-CN/answers/15-enums-and-switch`

说明：

- `demos/projects/15-enums-and-switch` 负责展示正文里的完整菜单示例
- 本文档保留更小、更基础的枚举和 `switch` 练习答案
- `exercises/zh-CN/answers/15-enums-and-switch` 则是课后作业“饮品点单程序”的参考工程

## 练习 1

题目：

- 定义一个 `TrafficLight` 枚举，包含 `red`、`yellow`、`green`

参考答案：

```swift
enum TrafficLight {
    case red
    case yellow
    case green
}
```

说明：

- `TrafficLight` 是类型名
- `red`、`yellow`、`green` 是这个类型中的合法情况

## 练习 2

题目：

- 写一个 `switch`，根据 `TrafficLight` 输出对应提示

参考答案：

```swift
enum TrafficLight {
    case red
    case yellow
    case green
}

let light: TrafficLight = .yellow

switch light {
case .red:
    print("停止通行")
case .yellow:
    print("减速并准备等待")
case .green:
    print("可以通行")
}
```

参考输出：

```text
减速并准备等待
```

## 练习 3

题目：

- 写一个函数，接收整数分数，返回 `ScoreLevel` 枚举值

参考答案：

```swift
enum ScoreLevel {
    case excellent
    case good
    case pass
    case fail
}

func scoreLevel(score: Int) -> ScoreLevel {
    switch score {
    case 90...100:
        return .excellent
    case 80..<90:
        return .good
    case 60..<80:
        return .pass
    default:
        return .fail
    }
}

print(scoreLevel(score: 95))
print(scoreLevel(score: 72))
```

说明：

- 这里先用 `switch` 判断分数区间
- 再把结果转换成一个更明确的枚举值

## 练习 4

题目：

- 定义一个 `BookCategory` 枚举，并根据不同分类输出书架位置提示

参考答案：

```swift
enum BookCategory {
    case language
    case programming
    case design
}

let category: BookCategory = .programming

switch category {
case .language:
    print("请去 A 书架")
case .programming:
    print("请去 B 书架")
case .design:
    print("请去 C 书架")
}
```

参考输出：

```text
请去 B 书架
```

说明：

- 这个例子的重点不是“书架业务”
- 而是理解“固定分类”非常适合用枚举表示
