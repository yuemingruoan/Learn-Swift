# 15. 枚举与 switch：用类型表示有限情况

## 阅读导航

- 前置章节：[08. Optional 入门](./08-optional-basics.md)、[10. 表达式、条件判断与循环](./10-expressions-conditions-and-loops.md)、[13. 结构体与最基础的自定义类型](./13-structs-and-custom-types.md)、[14. 数组与字典：列表与键值对](./14-arrays-and-dictionaries.md)
- 上一章：[14. 数组与字典：列表与键值对](./14-arrays-and-dictionaries.md)
- 建议下一章：[16. class 与引用语义：为什么改一个地方，另一个地方也会变](./16-class-and-reference-semantics.md)
- 下一章：[16. class 与引用语义：为什么改一个地方，另一个地方也会变](./16-class-and-reference-semantics.md)
- 适合谁先读：已经理解基础类型、结构体和条件判断，准备学习如何表示“固定几种状态”的读者

## 本章目标

学完这一章后，你应该能够：

- 理解什么叫“有限且明确的几种情况”
- 使用 `enum` 定义一组固定取值
- 理解为什么有些场景更适合用枚举，而不是字符串
- 使用 `switch` 对不同情况做分支处理
- 把枚举和 `switch` 组合起来写出更清楚的命令行程序

## 本章对应目录

- 对应项目目录：`demos/projects/15-enums-and-switch`
- 练习答案：`exercises/zh-CN/answers/15-enums-and-switch.md`
- 课后作业参考工程：`exercises/zh-CN/answers/15-enums-and-switch`

这里建议这样使用：

- `demos/projects/15-enums-and-switch`：看本章完整示例，理解枚举和 `switch` 如何一起工作
- `exercises/zh-CN/answers/15-enums-and-switch.md`：看基础练习的小答案
- `exercises/zh-CN/answers/15-enums-and-switch`：运行课后作业参考工程

这一章先不继续扩写前面那条成绩管理系统主线，而是换成一个更独立、更轻量的例子。这样做的目的很明确：

- 把注意力集中在 `enum` 和 `switch` 本身
- 避免旧项目越写越长，影响当前知识点的进入

## 为什么这一章要学枚举

到前面几章为止，你已经会了很多“保存数据”的方式：

- 用变量保存一个值
- 用结构体把多个字段组织起来
- 用数组保存一组同类型值
- 用字典保存键和值的对应关系

但还有一种常见需求，这些结构都没有直接解决：

- 有些值不是“任意内容”
- 而是“只能是这几个之一”

例如：

- 红灯、黄灯、绿灯
- 未开始、进行中、已完成
- 初级、中级、高级
- 阅读教程、运行示例、做练习、退出程序

这类数据的重点不在于“数量很多”，而在于：

- 取值范围很小
- 每一种值都有明确含义
- 程序希望你只能从这些合法情况里选

这正是枚举最适合处理的问题。

## 什么叫“有限情况”

如果你想表示“学习任务的类型”，你可能最先想到的是：

```swift
let action = "read"
```

看起来能用，但很快就会遇到几个问题：

- `"read"`、`"run"`、`"exercise"` 这些字符串，只能靠人自己记
- 一旦拼错，例如写成 `"raed"`，程序本身不一定能提前帮你发现
- 读代码的人也不知道到底哪些字符串才算合法

也就是说，字符串虽然能“装下这些字”，却不能天然表达：

- 这里本来就只能取固定几种值

枚举就是为了解决这个问题。

## 什么是枚举

在当前阶段，可以先把枚举理解成：

- 一种专门用来表示“固定几种情况”的类型

最基础的写法如下：

```swift
enum StudyAction {
    case readChapter
    case runDemo
    case doExercise
    case exit
}
```

这段代码表达的是：

- `StudyAction` 是一个新类型
- 这个类型里一共有 4 种合法情况
- 它们分别是 `readChapter`、`runDemo`、`doExercise` 和 `exit`

这里最重要的不是语法本身，而是这种建模方式：

- 以后凡是“学习任务类型”，就应该从这 4 个合法值里选
- 而不是随手写一个任意字符串

## 如何使用枚举值

创建枚举值时，最基础的写法如下：

```swift
let action: StudyAction = .readChapter
```

这里可以这样理解：

- 变量 `action` 的类型是 `StudyAction`
- 它当前的值是 `.readChapter`

如果想写完整，也可以写成：

```swift
let action = StudyAction.readChapter
```

当类型已经很明确时，点号写法通常会更简洁。

## 为什么这里不用字符串

再对比一次：

```swift
let action = "runDemo"
```

和：

```swift
let action: StudyAction = .runDemo
```

它们的区别不只是“写法不同”，而是表达能力不同。

字符串版本的问题在于：

- 拼错时不容易第一时间发现
- 看代码的人不知道合法范围
- 后面分支判断时，容易到处散落着相同的字符串字面量

枚举版本的好处在于：

- 合法情况被集中写在一个地方
- 类型本身就说明了当前变量的含义
- 后续做分支判断时，代码会更清晰

所以你可以把这一章的重点先记成一句话：

- 如果一个值本来就只能是固定几种情况之一，那么它通常更适合用枚举表示

## 什么是 switch

前面你已经学过 `if`、`else if` 和 `else`。

它们仍然非常重要。

但有些分支问题，如果继续写成一长串 `if-else`，结构会越来越像“重复比较同一个对象”。

例如：

```swift
if action == "read" {
    print("开始阅读教程")
} else if action == "run" {
    print("去运行示例工程")
} else if action == "exercise" {
    print("开始做练习")
} else {
    print("退出")
}
```

这种时候，`switch` 通常更直接。

## switch 的最基础写法

先看一个简单例子：

```swift
let number = 2

switch number {
case 1:
    print("你输入了 1")
case 2:
    print("你输入了 2")
default:
    print("你输入了其他数字")
}
```

你可以先这样读它：

- 先看 `switch` 后面要检查哪个值
- 再看每个 `case` 对应什么情况
- 如果前面的 `case` 都不匹配，就走 `default`

## switch 也可以处理范围

`switch` 不只能匹配一个固定值，也可以匹配一个范围。

例如，如果想根据分数先判断等级区间，可以写成：

```swift
let score = 86

switch score {
case 90...100:
    print("优秀")
case 80..<90:
    print("良好")
case 60..<80:
    print("及格")
default:
    print("不及格")
}
```

这类写法在“按分数段、按年龄段、按数量范围”做判断时都很实用。

## switch 和枚举为什么很适合一起用

前面我们已经知道：

- 枚举负责表达“有哪些合法情况”
- `switch` 负责根据“当前是哪一种情况”执行不同逻辑

它们组合起来时，代码会非常自然。

例如：

```swift
enum StudyAction {
    case readChapter
    case runDemo
    case doExercise
    case exit
}

let action: StudyAction = .runDemo

switch action {
case .readChapter:
    print("开始阅读教程")
case .runDemo:
    print("打开示例工程并运行")
case .doExercise:
    print("开始完成练习")
case .exit:
    print("结束本次学习")
}
```

这一版代码比字符串版更直接，因为：

- 类型已经说明 `action` 本来就只有这 4 种可能
- `switch` 则把这 4 种情况一一展开

## default 一定要写吗

当前阶段可以先这样理解：

- 如果前面的 `case` 不能覆盖所有情况，就需要 `default`
- 如果你对枚举已经把所有情况都列全了，那么通常可以不写 `default`

例如，对 `Int` 做判断时：

```swift
switch score {
case 90...100:
    print("优秀")
case 80..<90:
    print("良好")
default:
    print("其他情况")
}
```

这里需要 `default`，因为整数的可能性远不止前面写出来的几种。

但对一个只有固定几个 `case` 的枚举来说，如果已经把所有情况列出来，结构就会更明确。

## 一个完整示例：学习任务菜单

这一章的完整示例不再继续扩写前面的成绩系统，而是单独起一个命令行小项目：

- `demos/projects/15-enums-and-switch`

这个示例要解决的问题非常简单：

- 用户输入一个菜单编号
- 程序把编号转换成某种学习任务
- 再根据任务类型输出对应提示

它背后的两个核心步骤是：

1. 用枚举表示“任务类型”
2. 用 `switch` 处理“当前任务是什么”

例如，任务类型可以先定义成：

```swift
enum StudyAction {
    case readChapter
    case runDemo
    case doExercise
    case reviewNotes
    case exit
}
```

再写一个函数，把输入的字符串转成枚举值：

```swift
func actionFromInput(input: String) -> StudyAction? {
    switch input {
    case "1":
        return .readChapter
    case "2":
        return .runDemo
    case "3":
        return .doExercise
    case "4":
        return .reviewNotes
    case "0":
        return .exit
    default:
        return nil
    }
}
```

这里的重点是：

- 原始输入仍然是字符串
- 但程序不会一直拿字符串往后传
- 它会尽快把字符串转换成更明确的枚举值

接下来，拿到枚举值之后，就可以继续用 `switch` 做分支：

```swift
switch action {
case .readChapter:
    print("先读正文，再看关键代码片段。")
case .runDemo:
    print("打开示例工程，先运行一次，再回来看 main.swift。")
case .doExercise:
    print("先自己做，再回头看答案。")
case .reviewNotes:
    print("把今天卡住的点重新整理一遍。")
case .exit:
    print("本次学习结束。")
}
```

这一版代码很适合作为第一次系统理解 `enum + switch` 的起点，因为它同时满足：

- 结构简单
- 分支明确
- 不依赖旧项目上下文
- 和命令行输入输出能自然接上

## 本章最需要建立的判断标准

### 1. 当前值是不是只能是固定几种情况

如果答案是“是”，就应该优先想到：

- 能不能用枚举表达

例如：

- 用户角色
- 订单状态
- 菜单选项
- 难度等级

这些都比裸字符串更适合用枚举。

### 2. 当前分支是不是一直在围绕同一个值展开

如果你发现代码长这样：

- 反复比较同一个变量
- 每个比较分支都互斥

那就应该想一想：

- 这里是不是更适合改成 `switch`

### 3. 输入是不是应该尽早转换成更明确的类型

很多程序都会先拿到：

- 字符串输入
- 数字输入
- 外部传入值

更稳妥的方式通常是：

1. 先读取输入
2. 再做校验
3. 再尽快转换成更清楚的类型

这一章里，这个“更清楚的类型”就是枚举。

## 常见错误

### 1. 以为枚举只是另一种字符串

当前阶段最重要的是先建立这个认识：

- 枚举是类型
- `case` 是这个类型里的合法情况

### 2. 枚举定义好了，后面还是一直用字符串做判断

更合理的做法是：

- 先把输入转成枚举
- 后面都围绕枚举做判断

### 3. `switch` 写到一半漏掉某个情况

所以当你写 `switch` 时，最好总是主动问自己：

- 这个值一共有几种可能
- 我现在是不是已经全部处理到了

## 本章练习

请先完成下面这些基础练习：

1. 定义一个 `TrafficLight` 枚举，包含 `red`、`yellow`、`green`
2. 写一个 `switch`，根据 `TrafficLight` 输出对应提示
3. 写一个函数，接收整数分数，返回 `ScoreLevel` 枚举值
4. 定义一个 `BookCategory` 枚举，并根据不同分类输出书架位置提示

- 本章对应参考答案：

- [15. 枚举与 switch：用类型表示有限情况 练习答案](../../../exercises/zh-CN/answers/15-enums-and-switch.md)

## 思考题

本章思考题不再延续前面的成绩管理系统，而是单独做一个新项目：

- 命令行饮品点单程序

建议你按下面这些明确条件完成：

1. 定义一个 `DrinkType` 枚举，包含 `coffee`、`tea`、`juice`
2. 定义一个 `CupSize` 枚举，包含 `small`、`medium`、`large`
3. 程序启动后，先输出饮品菜单：
   - `1. 咖啡`
   - `2. 茶`
   - `3. 果汁`
4. 用户必须输入饮品编号，只允许输入 `1`、`2`、`3`
5. 选完饮品后，再输出杯型菜单：
   - `1. 小杯`
   - `2. 中杯`
   - `3. 大杯`
6. 用户必须输入杯型编号，只允许输入 `1`、`2`、`3`
7. 饮品基础价格固定如下：
   - 咖啡：`18` 元
   - 茶：`14` 元
   - 果汁：`16` 元
8. 杯型加价固定如下：
   - 小杯：`+0` 元
   - 中杯：`+2` 元
   - 大杯：`+4` 元
9. 最终输出至少包含：
   - 饮品名称
   - 杯型名称
   - 最终价格
10. 如果用户输入了非法编号，程序要输出明确提示，并结束本次运行；不要悄悄忽略错误

这道作业的重点不是“业务复杂”，而是让你尝试去编写完整的调用链路：

1. 输入原始文本
2. 转成枚举
3. 再用 `switch` 处理枚举

### 样例输入

```text
请输入饮品编号：1
请输入杯型编号：3
```

### 样例输出

```text
欢迎使用饮品点单程序
请选择饮品：
1. 咖啡
2. 茶
3. 果汁
请输入饮品编号：1

请选择杯型：
1. 小杯
2. 中杯
3. 大杯
请输入杯型编号：3

你选择的饮品： 咖啡
你选择的杯型： 大杯
价格：22 元
```

- 课后作业参考工程：`exercises/zh-CN/answers/15-enums-and-switch`

## 本章小结

这一章最需要记住的不是零散语法，而是下面这组关系：

- 枚举负责定义“有哪些合法情况”
- `switch` 负责根据“当前是哪一种情况”分支处理
- 如果一个值本来就只能在固定几种情况里选择，它通常更适合用枚举
- 如果一段逻辑一直在围绕同一个值做多路分支，它通常更适合用 `switch`
- 程序越早把原始输入转换成更明确的类型，后面的结构通常就越清楚

## 接下来怎么读

如果你想继续主线，建议下一步直接阅读：

- [16. class 与引用语义：为什么改一个地方，另一个地方也会变](./16-class-and-reference-semantics.md)

因为前面我们已经讲了：

- 怎么用 `struct` 组织数据
- 怎么用 `enum` 表示有限情况

接下来最自然的问题就是：

- 为什么有些自定义类型赋值后互不影响
- 为什么有些类型改一个地方，另一个地方也会变

第 16 章会专门解决这个问题。

如果你有一定编程基础，而且总会继续追问：

- `if let` 底层到底在做什么
- `class` 的引用和实例释放到底是怎样运行的

那么你在读完第 16 章之后，还可以继续阅读这一章选读：

- [17. 选读：从 Optional 到 ARC，理解 Swift 代码背后的运行规则](./17-optional-to-arc-runtime-rules.md)
