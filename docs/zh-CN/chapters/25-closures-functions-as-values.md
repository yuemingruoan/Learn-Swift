# 25. 闭包：把函数当成值来传递

## 阅读导航

- 前置章节：[12. 函数与代码复用](./12-functions-and-code-reuse.md)、[14. 数组与字典：列表与键值对](./14-arrays-and-dictionaries.md)、[24. 泛型：让同一套逻辑适配更多类型](./24-generics-reusable-abstractions.md)
- 上一章：[24. 泛型：让同一套逻辑适配更多类型](./24-generics-reusable-abstractions.md)
- 建议下一章：[26. 集合高阶操作：用 map、filter、reduce 整理数据](./26-higher-order-collection-operations.md)
- 下一章：[26. 集合高阶操作：用 map、filter、reduce 整理数据](./26-higher-order-collection-operations.md)
- 适合谁先读：已经理解函数和数组，准备学习“把行为本身交给别处决定”的读者

## 本章目标

学完这一章后，你应该能够：

- 理解闭包和函数在角色上的关系
- 看懂闭包最基础的语法外形
- 把闭包赋值给变量并在后面调用
- 把闭包作为参数传给函数
- 看懂尾随闭包这种常见写法
- 理解闭包为什么能够捕获外部变量
- 知道什么时候闭包是在帮助解耦，什么时候只是在增加绕弯

## 本章对应目录

- 对应项目目录：`demos/projects/25-closures-functions-as-values`
- 练习起始工程：`exercises/zh-CN/projects/25-closures-functions-as-values-starter`
- 练习答案文稿：`exercises/zh-CN/answers/25-closures-functions-as-values.md`
- 练习参考工程：`exercises/zh-CN/answers/25-closures-functions-as-values`

建议你这样使用：

- 先把本章当成“函数复用的下一步”来读，而不是当成一套零散语法
- 重点关注同一个函数为什么可以接收不同闭包，从而表现出不同策略
- 阅读时不要只背参数列表，先问自己“这里到底是谁在决定行为”

你可以这样配合使用：

- `demos/projects/25-closures-functions-as-values`：先看“整理好的闭包用法”，理解闭包怎样承担规则本身。
- `exercises/zh-CN/projects/25-closures-functions-as-values-starter`：再看“重复函数堆在一起”的版本，练习把规则抽成闭包。
- `exercises/zh-CN/answers/25-closures-functions-as-values.md`：做完后对照重构思路。
- `exercises/zh-CN/answers/25-closures-functions-as-values`：最后再运行参考答案工程。

导读建议：

- 先看 demo 里的“闭包可以先存进变量里”，把“闭包首先也是值”这个认识建立起来。
- 再看“闭包作为参数时，外层流程保持不变”和“同一个函数可以接收不同闭包”，理解策略是怎样被外部传入的。
- 接着看“完整功能：学习任务调度中心”，观察 `filtered`、`sorted`、`summaries` 这三个固定流程如何因为闭包不同而表现不同。
- 最后看“闭包捕获会记住外部变量”，再回头读正文里的捕获小节，会更容易理解 `makeCounter()`。

## 为什么泛型之后适合学习闭包

上一章的泛型让你看到：

- 同一套逻辑结构，可以适配不同类型

但很多程序中的变化，并不只来自“类型不同”，还来自：

- 处理规则不同
- 判断标准不同
- 排序方式不同

例如：

- 按时长排序学习任务
- 按标题排序学习任务
- 只筛选未完成任务
- 只筛选长任务

如果你把这些规则都写死在函数内部，那么很快就会出现另一种重复：

- 函数结构一样
- 只是“怎么处理”这一步不同

这时，最自然的问题就是：

- 能不能把“行为本身”也当成参数传进去

Swift 的一个重要答案就是：

- 闭包

## 先说结论：闭包不是神秘语法

很多初学者第一次看到闭包时，会被下面这种写法吓住：

```swift
tasks.sorted { left, right in
    left.estimatedHours < right.estimatedHours
}
```

看起来像是：

- 函数里突然塞进了一段没有名字的函数

这个直觉并不完全错。

当前阶段最稳妥的理解就是：

- 闭包可以先近似理解成“没有单独命名的函数值”

这里要注意两个点：

- 它仍然是一段可以执行的逻辑
- 它也可以像普通值一样被保存、传递、调用

所以闭包真正让很多人不适应的地方，不是“它做不到函数的事”，而是：

- 它把“行为也是值”这件事放到了台面上

## 闭包到底在解决什么问题

当前阶段，可以先把闭包理解成：

- 当函数需要把一段行为交给外部决定时，用来承载这段行为的写法

例如，一个“筛选学习任务”的函数，可能并不想写死：

- 只筛选未完成任务

它更可能想表达：

- 具体筛选条件由调用方给我

这时调用方传进来的那段“判断逻辑”，就非常适合用闭包表达。

## 先看闭包最基础的语法外形

最常见的入门写法如下：

```swift
{ (参数列表) -> 返回类型 in
    逻辑
}
```

例如：

```swift
let greet: (String) -> String = { (name: String) -> String in
    return "你好，\(name)"
}
```

这里可以先这样理解：

- 左边的 `(String) -> String` 表示这是一个“接收 `String`，返回 `String`”的函数类型
- 右边的大括号里，才是闭包本体
- `in` 前面写参数和返回类型
- `in` 后面写真正执行的逻辑

调用时：

```swift
print(greet("Swift"))
```

所以闭包并不是“只能传给别人用”，它自己也可以先存进变量里。

## 闭包和普通函数的关系

这一点非常重要。

前面你已经学过普通函数：

```swift
func greet(name: String) -> String {
    return "你好，\(name)"
}
```

而刚才的闭包写法是：

```swift
let greet: (String) -> String = { name in
    return "你好，\(name)"
}
```

它们都能表达：

- 接收一个名字
- 返回一段问候语

所以当前阶段可以先记住一句非常实用的话：

- 闭包和函数都能表示“可执行的行为”

那它们的差别主要体现在哪？

- 普通函数更适合被命名、长期复用
- 闭包更适合就地传入、临时定制行为

也就是说：

- 闭包不是来取代函数的
- 它是在补“函数作为值使用”这块能力

## 一个最简单的场景：把闭包赋值给变量

先看一个非常直接的例子：

```swift
let isLongTask: (Int) -> Bool = { hours in
    return hours >= 2
}
```

这里的含义是：

- `isLongTask` 不是一个 `Bool`
- 它是一段逻辑
- 这段逻辑接收 `Int`
- 返回 `Bool`

调用时：

```swift
print(isLongTask(1))
print(isLongTask(3))
```

如果你能稳定地把这一点看懂，那么后面“闭包作为参数”就会顺很多。

因为本质上只是：

- 先把一段行为当成值保存起来
- 再把这个值传给别的地方

## 闭包作为参数是什么意思

这一章真正的核心，不是把闭包存进变量，而是：

- 让函数接收一个闭包参数

先看一个最基础的例子：

```swift
func applyToHours(_ hours: Int, using rule: (Int) -> String) -> String {
    return rule(hours)
}
```

这里的关键点是：

- `rule` 不是普通数据参数
- 它是一个函数类型参数

更具体地说：

- `rule` 必须是一段“接收 `Int`，返回 `String`”的行为

调用时：

```swift
let text = applyToHours(3) { hours in
    return "\(hours) 小时"
}
```

你可以先这样理解这次调用：

- `applyToHours` 负责搭好整体流程
- 具体怎么把小时数转成文本，由外部传入的闭包决定

## 为什么这比写死逻辑更灵活

如果不使用闭包，你很可能会写成：

```swift
func hoursText(_ hours: Int) -> String {
    return "\(hours) 小时"
}
```

这本身没有问题。

但如果后面又需要：

- 英文格式
- 简洁格式
- 带优先级标记的格式

你就会开始复制很多几乎一样的函数。

而闭包参数的思路是：

- 保留外层流程
- 把变化的规则交给调用方

所以闭包常见的价值之一就是：

- 把“固定流程”和“可变策略”拆开

## 什么是尾随闭包

刚才的写法里，你可能已经注意到了这一点：

```swift
let text = applyToHours(3) { hours in
    return "\(hours) 小时"
}
```

看起来像是：

- 闭包被写在了小括号外面

这就是尾随闭包。

当函数的最后一个参数是闭包时，Swift 允许这样写。

它的好处主要是：

- 结构更清楚
- 阅读时更像“主函数 + 一段补充行为”

如果不用尾随闭包，同一段代码通常会写成：

```swift
let text = applyToHours(3, using: { hours in
    return "\(hours) 小时"
})
```

两种写法在含义上没有本质差别。

当前阶段你只需要先记住：

- 尾随闭包不是新能力
- 它只是闭包参数的一种更常见的书写形式

## 一个完整示例：把排序和筛选规则交给外部

本章最适合放进完整场景里的，是“学习任务列表处理器”。

先定义数据：

```swift
struct StudyTask {
    let title: String
    let estimatedHours: Int
    var isFinished: Bool
}
```

再定义一个工具类型：

```swift
struct StudyTaskProcessor {
    let tasks: [StudyTask]

    func filtered(by rule: (StudyTask) -> Bool) -> [StudyTask] {
        var result: [StudyTask] = []

        for task in tasks {
            if rule(task) {
                result.append(task)
            }
        }

        return result
    }

    func sorted(by areInIncreasingOrder: (StudyTask, StudyTask) -> Bool) -> [StudyTask] {
        var result = tasks

        for i in 0..<result.count {
            for j in (i + 1)..<result.count {
                if areInIncreasingOrder(result[j], result[i]) {
                    let temp = result[i]
                    result[i] = result[j]
                    result[j] = temp
                }
            }
        }

        return result
    }
}
```

这里最值得注意的地方不是排序算法本身，而是：

- `filtered(by:)` 并没有写死“什么样的任务算符合条件”
- `sorted(by:)` 也没有写死“按什么规则比较前后”

于是调用方可以自由选择策略：

```swift
let processor = StudyTaskProcessor(tasks: tasks)

let unfinishedTasks = processor.filtered { task in
    task.isFinished == false
}

let longTasks = processor.filtered { task in
    task.estimatedHours >= 2
}

let tasksByHours = processor.sorted { left, right in
    left.estimatedHours < right.estimatedHours
}

let tasksByTitle = processor.sorted { left, right in
    left.title < right.title
}
```

这正是闭包真正让代码变灵活的地方：

- 同一个外层函数
- 因为闭包不同，行为就不同

## 这不是“把逻辑藏起来”，而是在分职责

有些读者刚接触闭包时，会担心：

- 把规则塞进闭包，是不是反而让逻辑更散了

这个担心是合理的，但要看你怎么用。

如果闭包只是把本来应该写在一个清晰函数里的复杂流程硬塞进去，那确实会变乱。

但如果闭包的职责非常明确，例如：

- 判断一个任务是否符合条件
- 比较两个任务的先后顺序
- 决定一个值怎么格式化

那它其实是在做一件很清楚的事：

- 把变化点单独交给外部

所以闭包是否有价值，不看“写法是不是更短”，而看：

- 这段行为是不是本来就应该由调用方决定

## 什么叫“闭包捕获外部变量”

这一点是后续章节会反复遇到的关键概念。

先看一个例子：

```swift
func makeProgressPrinter(prefix: String) -> (Int) -> Void {
    return { count in
        print("\(prefix)：已完成 \(count) 项")
    }
}
```

调用时：

```swift
let printDailyProgress = makeProgressPrinter(prefix: "今日进度")
printDailyProgress(3)
printDailyProgress(5)
```

这里最值得注意的是：

- 返回的闭包里并没有重新声明 `prefix`
- 但它仍然能使用 `prefix`

这就是捕获。

当前阶段可以先把它理解成：

- 闭包会把自己需要用到的外部上下文一起带走

也正因为如此，闭包才不只是“临时匿名函数”，它还可以：

- 保留一部分创建时的环境

## 一个更直观的例子：累加器



```swift
func makeCounter() -> () -> Int
```

先不说之后的代码，相信大家第一次看到这行声明都会感到困惑，所以我们先来解析这行声明：

它之所以看起来绕，是因为这里同时出现了：

- 第一层 `()`：`makeCounter` 自己不接收参数
- 第一层 `->`：表示 `makeCounter` 会返回一个结果
- 第二层 `() -> Int`：这个“结果”本身不是普通值，而是一个函数类型

也就是说，这一行不要读成：

- “返回一个 `Int`”

而要读成：

- `makeCounter` 不接收参数
- `makeCounter` 返回“另一个函数”
- 这个被返回的函数也不接收参数
- 这个被返回的函数调用后会得到一个 `Int`

如果把它拆成更口语化的话，就是：

- `makeCounter` 是一个“专门用来制造计数器函数”的工厂函数

所以当前阶段你可以先把这行声明近似记成：

```swift
func makeCounter() -> 一个“调用后返回 Int 的函数”
```

如果还是觉得难读，可以先对照下面两个更简单的声明：

```swift
func makeTitle() -> String
func makeChecker() -> () -> Bool
```

第一行表示：

- 函数返回一个 `String`

第二行表示：

- 函数返回另一个函数
- 而这个被返回的函数调用后会得到 `Bool`

那么：

```swift
func makeCounter() -> () -> Int
```

自然就是：

- 函数返回另一个函数
- 而这个被返回的函数调用后会得到 `Int`

把这一层读顺之后，再看下面的代码就容易很多了：

```swift
func makeCounter() -> () -> Int {
    var total = 0

    return {
        total += 1
        return total
    }
}
```

调用时：

```swift
let counter = makeCounter()
print(counter())
print(counter())
print(counter())
```

输出通常会是：

```text
1
2
3
```

这里可以一步一步理解。

### 第一步：执行 `makeCounter()`

```swift
let counter = makeCounter()
```

这一步并不是直接得到某个数字。

它真正做的事情是：

- 创建一个局部变量 `total`
- 让 `total` 初始值为 `0`
- 返回一个闭包
- 并把这个闭包赋值给 `counter`

所以此时的 `counter` 不是整数，而是：

- 一段以后可以反复调用的函数值

### 第二步：第一次调用 `counter()`

```swift
print(counter())
```

此时会执行闭包内部逻辑：

```swift
total += 1
return total
```

于是：

- 原来的 `total` 是 `0`
- 先加 `1`
- 再返回 `1`

所以第一次输出是：

```text
1
```

### 第三步：第二次调用 `counter()`

同一个闭包再次执行。

关键点在于：

- 这里用的不是一个全新的 `total`
- 而是前面那个已经被闭包捕获下来的 `total`

所以这一次：

- `total` 上次已经变成了 `1`
- 再加 `1`
- 返回 `2`

### 第四步：第三次调用 `counter()`

同理：

- `total` 此时已经是 `2`
- 再加 `1`
- 返回 `3`

所以最终输出才会是：

```text
1
2
3
```

这说明：

- 闭包没有忘掉外面的 `total`
- 它持续地在使用并修改这份状态

如果你想把这个例子理解得更朴素一点，可以先把它看成：

- `makeCounter()` 负责“生产一个带着自己计数状态的小函数”
- `counter()` 每调用一次，就把这个小函数内部记住的数字加一

当前阶段最重要的不是一次记住所有术语，而是先把下面这句话读顺：

- 一个函数的返回值，也可以是另一个函数
- 而这个被返回的函数，还可以记住创建它时周围的变量

这一点很重要，因为后面讲到 ARC 进阶和闭包引用 `self` 时，你会再次遇到它。

## 闭包简写为什么会越来越短

你在真实 Swift 代码里常见到的闭包，通常不会每次都写全参数类型和返回类型。

例如：

```swift
let sortedTasks = tasks.sorted { left, right in
    left.estimatedHours < right.estimatedHours
}
```

这比完整写法短很多，是因为：

- 上下文已经能推断参数和返回值类型

当前阶段你不需要急着把所有简写规则一口气背完。

先建立一个更重要的认识：

- 闭包写短了，不等于闭包本质变了

无论是完整写法还是简写，本质上都还是：

- 一段可执行逻辑
- 被当成值传给了别的地方

## 什么时候优先想到闭包

如果你拿不准某段逻辑是否适合写成闭包，可以先问自己下面几个问题。

### 1. 外层流程是否固定，而内部规则是否变化

如果答案是“是”，闭包通常很自然。

例如：

- 过滤流程固定，过滤条件变化
- 排序流程固定，比较规则变化

### 2. 这段行为是否只在局部使用一次

如果某段逻辑只服务于当前调用点，而且非常贴近上下文，那么用闭包就地传入通常比单独起一个函数更自然。

### 3. 这段行为是否已经复杂到需要独立命名

如果闭包已经写成十几行，甚至开始有多层分支，那么通常应该先考虑：

- 把它提成普通函数

因为可读性往往比“写成一块”更重要。

## 常见误区

### 1. 以为闭包和函数完全是两套无关东西

不是。

它们都能表示行为，只是使用场景不同。

### 2. 以为闭包只能作为参数传给系统 API

不是。

你自己写的函数同样可以接收闭包，也可以返回闭包。

### 3. 以为闭包越短越高级

不是。

如果简写之后看不清参数含义，那通常不如写得稍微完整一点。

## 本章练习与课后作业

如果你想把这一章的内容真正落实到一个“能跑但很乱”的项目里，可以继续完成下面这道重构作业：

- 作业答案：`exercises/zh-CN/answers/25-closures-functions-as-values.md`
- 起始工程：`exercises/zh-CN/projects/25-closures-functions-as-values-starter`
- 参考答案工程：`exercises/zh-CN/answers/25-closures-functions-as-values`

这一题的重点是把 starter project 里这些重复逻辑拆成“固定流程 + 可变规则”：

- 重复的筛选函数
- 重复的排序函数
- 重复的摘要生成函数

做题时最值得反复确认的一点是：

- 这里变化的到底是业务流程，还是判断规则

如果变化的只是规则，那么闭包通常就是最自然的重构入口。

要求：

- 使用“接收闭包参数的统一筛选函数”重构重复的筛选逻辑。
- 使用“接收比较闭包的统一排序函数”重构重复的排序逻辑。
- 使用“接收格式化闭包的统一摘要函数”重构重复的摘要生成逻辑。
- 至少使用一次“返回闭包”的形式，重构 starter project 里重复的前缀/文案生成部分。
- 不要把规则继续写死在多个函数体里，主流程应当体现“传入规则，再执行流程”。

## 本章小结

这一章最需要记住的是下面这组关系：

- 闭包可以先近似理解成“没有单独命名的函数值”
- 闭包和普通函数都能表示行为
- 闭包可以被赋值、传递和调用
- 当函数需要把局部策略交给外部决定时，闭包非常有用
- 尾随闭包只是更常见的写法，不是新能力
- 闭包可以捕获外部变量，这会影响后续状态管理和内存管理

如果你现在已经能比较稳定地看懂下面这类代码：

- `let formatter = { ... }`
- `func filtered(by rule: ...)`
- `tasks.sorted { ... }`
- `func makeCounter() -> () -> Int`

那么这一章最重要的目标就已经达到了。

## 接下来怎么读

下一章建议继续阅读：

- [26. 集合高阶操作：用 map、filter、reduce 整理数据](./26-higher-order-collection-operations.md)

因为当你已经知道“行为也能当参数”之后，Swift 集合里那些最常见的高阶操作就终于有了清楚的语义基础。
