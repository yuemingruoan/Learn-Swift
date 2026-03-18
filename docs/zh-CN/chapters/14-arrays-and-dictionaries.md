# 14. 数组与字典：列表与键值对

## 阅读导航

- 前置章节：[10. 表达式、条件判断与循环](./10-expressions-conditions-and-loops.md)、[12. 函数与代码复用](./12-functions-and-code-reuse.md)、[13. 结构体与最基础的自定义类型](./13-structs-and-custom-types.md)
- 上一章：[13. 结构体与最基础的自定义类型](./13-structs-and-custom-types.md)
- 建议下一章：15. 更完整的数据组织（待补充）
- 下一章：15. 更完整的数据组织（待补充）
- 适合谁先读：已经理解变量、循环和结构体，准备学习如何保存一组数据的读者

## 本章目标

学完这一章后，你应该能够：

- 理解数组和字典各自适合解决什么问题
- 使用 `[Int]` 和 `[String: Int]` 写出最基础的数组与字典
- 正确使用 `.count` 判断元素个数
- 使用 `append` 向数组追加元素
- 使用下标读取数组元素
- 使用键读取字典中的值，并理解它为什么会得到 Optional
- 根据数据特点判断该用数组还是字典

## 本章对应目录

- 对应项目目录：`demos/projects/14-arrays-and-dictionaries`
- 练习答案：`exercises/zh-CN/answers/14-arrays-and-dictionaries.md`

这里建议这样使用：

- `demos/projects/14-arrays-and-dictionaries`：只看成绩管理系统在第 14 章的迭代版本
- `exercises/zh-CN/answers/14-arrays-and-dictionaries.md`：查看数组和字典的基础小例子
- `exercises/zh-CN/answers/14-arrays-and-dictionaries`：运行课后作业参考工程

## 为什么把数组和字典放在一起讲

到了这一章，真正需要解决的问题已经不是：

- 怎么声明一个变量

而是：

- 怎么保存一组相关数据

例如，下面这两类需求看起来都像是在“保存很多东西”：

- 保存多次考试成绩
- 保存“科目 -> 分数”的对应关系

但它们其实不是同一种数据结构问题。

第一类更像：

- 第 1 次、第 2 次、第 3 次……

也就是：

- 按顺序保存一组值

第二类更像：

- 语文是多少分
- 数学是多少分

也就是：

- 通过名字去找对应的值

前者最适合数组，后者最适合字典。把它们放在同一章里看，对比会更直接。

## 什么是数组

在当前阶段，可以先把数组理解成：

- 按顺序保存多个同类型值的列表

例如：

```swift
let scores: [Int] = [80, 92, 75]
```

这表示：

- `scores` 是一个数组
- 数组里的元素类型是 `Int`
- 这 3 个分数按照顺序排好

数组最适合的场景通常是：

- 你关心先后顺序
- 你会按位置读取数据
- 你需要遍历整组数据

## 数组的最基础写法

先看两个最基础的例子：

```swift
let scores: [Int] = [80, 92, 75]
var names: [String] = ["Alice", "Bob"]
```

写法可以先记成：

```swift
var 数组名: [元素类型] = [元素1, 元素2, 元素3]
```

例如：

- `[Int]` 表示整数数组
- `[String]` 表示字符串数组

如果数组一开始还没有内容，也可以先写成空数组：

```swift
var scores: [Int] = []
```

## `.count` 是什么

这是这一章必须专门记住的一点。

在 Swift 里，数组和字典的元素个数都通过：

```swift
变量名.count
```

来获取。

例如：

```swift
let scores = [80, 92, 75]
print(scores.count)
```

输出通常是：

```text
3
```

这里要特别注意：

- 在 Swift 里写的是 `.count`
- 不是 `count()`

也就是说，它在当前阶段应该先被理解成：

- 一个直接拿来读取数量的属性

而不是：

- 需要额外调用的函数

如果只是想知道数组里有多少个元素，通常没有必要自己再手动维护一个：

```swift
var numberOfScores = 0
```

因为数组本身已经能通过 `.count` 直接告诉你答案。

## 向数组追加元素

当数组不是一次性写死，而是后面逐步得到数据时，最基础的做法是 `append`。

例如：

```swift
var scores: [Int] = []

scores.append(88)
scores.append(91)
scores.append(76)

print(scores)
print(scores.count)
```

这段代码的重点是：

- `append(...)` 会把新元素加到数组末尾
- 每追加一次，`.count` 也会随之变化

因此，如果你是在不断录入一组同类数据，数组通常会很自然。

## 用下标读取数组元素

数组里的元素可以通过下标读取。

例如：

```swift
let scores = [80, 92, 75]

print(scores[0])
print(scores[1])
print(scores[2])
```

这里需要先建立一个很重要的习惯：

- 第一个元素的下标是 `0`
- 第二个元素的下标是 `1`
- 第三个元素的下标是 `2`

也就是说：

- “第几个元素”和“下标是多少”不能混在一起

## 遍历数组

如果要把数组中的每个元素都处理一遍，最常见的方式就是 `for-in`。

例如：

```swift
let scores = [80, 92, 75]

for score in scores {
    print(score)
}
```

如果你不仅想拿到值，还想知道它是第几项，可以结合范围和下标：

```swift
for index in 0..<scores.count {
    print("第 \(index + 1) 次成绩：", scores[index])
}
```

这里的关键点在于：

- `scores.count` 给出元素个数
- `0..<scores.count` 给出合法下标范围

## 什么是字典

在当前阶段，可以先把字典理解成：

- 一组“键和值”的对应关系

例如：

```swift
let subjectScores: [String: Int] = [
    "语文": 92,
    "数学": 88,
    "英语": 95
]
```

这里的含义是：

- 键是 `String`
- 值是 `Int`
- 每个科目对应一个分数

因此，字典更适合下面这类问题：

- 想通过某个名字找到对应值
- 不想靠位置找，而是想靠“标签”找

## 字典的最基础写法

字典最基础的写法是：

```swift
var 字典名: [键类型: 值类型] = [
    键1: 值1,
    键2: 值2
]
```

例如：

```swift
var subjectScores: [String: Int] = [
    "语文": 92,
    "数学": 88
]
```

空字典也可以先写出来：

```swift
var subjectScores: [String: Int] = [:]
```

这表示：

- 现在还没有任何键值对
- 但后面可以逐步加入

## 字典也可以用 `.count`

字典同样支持 `.count`。

例如：

```swift
let subjectScores: [String: Int] = [
    "语文": 92,
    "数学": 88,
    "英语": 95
]

print(subjectScores.count)
```

这里得到的是：

- 当前字典里一共有多少组键值对

也就是说：

- 数组的 `.count` 是元素个数
- 字典的 `.count` 是键值对个数

写法完全一致，意义略有不同，但都非常直接。

## 通过键读取字典的值

字典最常见的读取方式不是下标位置，而是键。

例如：

```swift
let subjectScores: [String: Int] = [
    "语文": 92,
    "数学": 88
]

print(subjectScores["数学"] as Any)
```

这里要特别注意：

- 字典取值时，结果是 Optional

原因很直接：

- 编译器不能保证这个键一定存在

例如：

```swift
if let mathScore = subjectScores["数学"] {
    print("数学成绩是：", mathScore)
}

if let chemistryScore = subjectScores["化学"] {
    print("化学成绩是：", chemistryScore)
} else {
    print("当前还没有化学成绩")
}
```

这一点和前面学过的 Optional 是连起来的。

## 更新和新增字典内容

字典可以通过键来更新值，也可以直接新增键值对。

例如：

```swift
var subjectScores: [String: Int] = [
    "语文": 92,
    "数学": 88
]

subjectScores["数学"] = 91
subjectScores["英语"] = 95
```

这里发生了两件事：

- 原来已有 `"数学"`，所以它被更新
- 原来没有 `"英语"`，所以它被新增

这也是字典和数组很不一样的地方：

- 数组更像“按顺序追加”
- 字典更像“按名字存取”

## 数组和字典该怎么选

如果你分不清该用哪一个，可以先问自己一个问题：

- 我到底是想按位置取值，还是想按名字取值？

通常可以这样判断：

- 数组：适合“第几个、按顺序、整组遍历”
- 字典：适合“某个名字对应什么值”

例如：

- 多次考试成绩：更像数组
- 各科成绩：更像字典
- 学生姓名列表：更像数组
- 学号和姓名的对应关系：更像字典

## 完整示例：成绩管理系统的第 14 章版本

这一章的 `demo` 工程继续沿用前面的成绩管理系统，但 `main.swift` 里现在只保留系统本身的代码。

这一版和第 13 章相比，最关键的变化是：

- 不再只保存 `frequency`、`scoreSum`、`passCount`
- 而是直接保存 `scores: [Int]`

这样程序就真正保留了完整成绩列表，后续统计都围绕数组展开：

- 总分
- 平均分
- 最高分
- 最低分
- 及格率

这样安排的目的很明确：

- `demo` 工程负责展示“系统如何迭代”
- 基础数组/字典小例子单独放在答案文档里

## 常见错误

### 1. 把 `.count` 写成 `count()`

当前阶段最稳妥的记法就是：

```swift
scores.count
subjectScores.count
```

先不要把它写成函数调用形式。

### 2. 把数组和字典混成同一种结构

例如：

- 想保存“第 1 次、第 2 次、第 3 次”却用了字典
- 想保存“语文、数学、英语”却只用数组，不给出科目名

这会让代码本身变得不自然。

### 3. 误以为字典取值一定能成功

例如：

```swift
subjectScores["化学"]
```

这里并不能保证一定有值，所以需要按 Optional 的思路处理。

### 4. 数组下标越界

例如：

```swift
let scores = [80, 92, 75]
print(scores[3])
```

这里会出错，因为合法下标只有：

- `0`
- `1`
- `2`

## 本章练习

请你先完成下面这些基础练习：

1. 创建一个 `[Int]` 数组，保存 3 个成绩，输出整个数组和 `scores.count`
2. 创建一个空数组，用 `append` 加入 3 个成绩，再输出第 2 个成绩
3. 创建一个 `[String: Int]` 字典，保存 3 门课成绩，输出 `subjectScores.count`
4. 用 `if let` 读取 `"数学"` 对应的值，再尝试读取一个不存在的键

- 本章对应参考答案：

- [14. 数组与字典：列表与键值对 练习答案](../../../exercises/zh-CN/answers/14-arrays-and-dictionaries.md)

## 课后作业

请把前面章节中的成绩录入程序，作为本章课后作业继续改造：

1. 不再只保存 `scoreSum` 和 `passNum`，而是改成用 `[Int]` 保存所有成绩
2. 在数组版本基础上，重新计算总分、平均分、最高分和最低分
3. 如果以后程序不再录入“第几次考试”，而是录入“语文、数学、英语”等科目成绩，尝试设计一个 `[String: Int]` 字典版本

这一组作业不在正文里直接展开，目的就是让你自己体会：

- 合适的数据结构对代码的简洁性的帮助
- 数组适合“按顺序保存”
- 字典适合“按名字查找”

- 课后作业参考工程：`exercises/zh-CN/answers/14-arrays-and-dictionaries`

如果你想直接对比系统迭代过程，可以按这个顺序看：

1. 第 13 章项目：`demos/projects/13-structs-and-custom-types`
2. 第 14 章项目：`demos/projects/14-arrays-and-dictionaries`
3. 第 14 章课后作业参考工程：`exercises/zh-CN/answers/14-arrays-and-dictionaries`

## 本章小结

这一章最需要建立的认识可以概括为：

- 数组是列表，字典是键值对
- 两者都可以用 `.count` 获取当前数量
- 数组更适合按顺序、按位置处理数据
- 字典更适合按名字、按标签查找数据
- 如果一开始就把数组和字典对照着学，后面设计数据结构会轻松很多
