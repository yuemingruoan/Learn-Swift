# 14. 数组与字典：列表与键值对 练习答案

对应章节：

- [14. 数组与字典：列表与键值对](../../../docs/zh-CN/chapters/14-arrays-and-dictionaries.md)

如果你想一边看答案一边运行示例，也可以打开对应工程：

- `demos/projects/14-arrays-and-dictionaries`

如果你想直接运行课后作业的参考工程，也可以打开：

- `exercises/zh-CN/answers/14-arrays-and-dictionaries`

说明：

- `demos/projects/14-arrays-and-dictionaries` 里的 `main.swift` 现在只保留成绩管理系统的数组版迭代
- 本文档负责保留数组和字典的基础小例子，避免把不同用途的代码混在同一个可运行入口里

## 练习 1

题目：

- 创建一个 `[Int]` 数组，保存 3 个成绩，输出整个数组和 `scores.count`

参考答案：

```swift
let scores: [Int] = [80, 92, 75]

print(scores)
print(scores.count)
```

参考输出：

```text
[80, 92, 75]
3
```

说明：

- 在 Swift 里这里写的是 `.count`
- 不是 `count()`

## 练习 2

题目：

- 创建一个空数组，用 `append` 加入 3 个成绩，再输出第 2 个成绩

参考答案：

```swift
var scores: [Int] = []

scores.append(88)
scores.append(91)
scores.append(76)

print(scores[1])
print(scores.count)
```

参考输出：

```text
91
3
```

## 练习 3

题目：

- 创建一个 `[String: Int]` 字典，保存 3 门课成绩，输出 `subjectScores.count`

参考答案：

```swift
let subjectScores: [String: Int] = [
    "语文": 92,
    "数学": 88,
    "英语": 95
]

print(subjectScores)
print(subjectScores.count)
```

参考输出：

```text
["语文": 92, "数学": 88, "英语": 95]
3
```

说明：

- 字典打印出来的顺序不应该当成重点
- 当前阶段更重要的是理解“键和值的对应关系”

## 练习 4

题目：

- 用 `if let` 读取 `"数学"` 对应的值，再尝试读取一个不存在的键

参考答案：

```swift
let subjectScores: [String: Int] = [
    "语文": 92,
    "数学": 88,
    "英语": 95
]

if let mathScore = subjectScores["数学"] {
    print("数学成绩是：", mathScore)
}

if let chemistryScore = subjectScores["化学"] {
    print("化学成绩是：", chemistryScore)
} else {
    print("当前还没有化学成绩")
}
```

参考输出：

```text
数学成绩是： 88
当前还没有化学成绩
```

说明：

- 字典通过键取值时，结果是 Optional
- 因为编译器不能保证这个键一定存在
