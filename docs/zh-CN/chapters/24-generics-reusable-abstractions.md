# 24. 泛型：让同一套逻辑适配更多类型

## 阅读导航

- 前置章节：[12. 函数与代码复用](./12-functions-and-code-reuse.md)、[13. 结构体与最基础的自定义类型](./13-structs-and-custom-types.md)、[21. 协议：比继承更灵活的抽象方式](./21-protocols-flexible-abstraction.md)、[23. 错误处理：让失败路径更清楚](./23-error-handling-clear-failure-paths.md)
- 上一章：[23. 错误处理：让失败路径更清楚](./23-error-handling-clear-failure-paths.md)
- 建议下一章：[25. 闭包：把函数当成值来传递](./25-closures-functions-as-values.md)
- 下一章：[25. 闭包：把函数当成值来传递](./25-closures-functions-as-values.md)
- 适合谁先读：已经理解函数、结构体和协议，准备继续学习“复用逻辑而不是复制代码”的读者

## 本章目标

学完这一章后，你应该能够：

- 理解泛型到底在解决什么重复问题
- 看懂泛型函数和泛型类型最基础的语法
- 区分“具体类型”“协议类型”“泛型参数”这三种写法在含义上的差别
- 理解函数重载和泛型分别适合解决什么问题
- 使用泛型把相同结构的逻辑统一到一套实现中
- 看懂最基础的泛型约束写法
- 对学过 C++ 的读者，建立 Swift 泛型和模板之间的基本对照直觉
- 知道什么时候该用泛型，什么时候不该强行泛型化

## 本章对应目录

- 对应项目目录：`demos/projects/24-generics-reusable-abstractions`
- 练习起始工程：`exercises/zh-CN/projects/24-generics-reusable-abstractions-starter`
- 练习答案文稿：`exercises/zh-CN/answers/24-generics-reusable-abstractions.md`
- 练习参考工程：`exercises/zh-CN/answers/24-generics-reusable-abstractions`

阅读引导：

- 先读正文，明确泛型不是“更高级的语法糖”，而是在解决复用边界问题
- 再运行 `demos/projects/24-generics-reusable-abstractions`
- 重点关注“为什么这里不只靠 `Any`，为什么这里也不再复制两份函数”

你可以这样配合使用：

- `demos/projects/24-generics-reusable-abstractions`：先看“正确组织后的概念演示”，理解泛型、重载和 `Any` 的边界。
- `exercises/zh-CN/projects/24-generics-reusable-abstractions-starter`：再看“能跑但很乱”的版本，判断哪些重复真的适合改成泛型。
- `exercises/zh-CN/answers/24-generics-reusable-abstractions.md`：做完后对照思路说明。
- `exercises/zh-CN/answers/24-generics-reusable-abstractions`：最后再运行完整参考实现。

导读建议：

- 先看 demo 里的“同名重载适合不同实现”，把重载和泛型的分工分清。
- 再看“Any 可以混装不同类型”和“泛型函数保留类型关系”，对照理解二者差异。
- 接着看“完整功能：学习资源调度中心”，观察同一个 `StudyQueue<Element>` 怎样服务不同资料类型。
- 最后看“泛型约束让查找规则更清楚”，把 `Equatable` 约束和正文中的约束小节连起来。

## 为什么错误处理之后适合学习泛型

在前面我们已经学了：

- 用函数收拢重复逻辑
- 用结构体和类组织数据
- 用协议表达共同能力
- 用错误类型把失败情况表达清楚

这时候你会发现还有一种重复还没得到处理：

- 逻辑结构完全一样
- 只是处理的数据类型不同

例如：

- 交换两个 `Int`
- 交换两个 `String`

或

- 暂存一组 `StudyTask`
- 暂存一组 `String`

如果你继续沿用前面的思路，很可能会写出：

```swift
func swapInts(_ a: inout Int, _ b: inout Int) {
    let temp = a
    a = b
    b = temp
}

func swapStrings(_ a: inout String, _ b: inout String) {
    let temp = a
    a = b
    b = temp
}
```

这两段代码能工作，但问题也很明显：

- 逻辑完全一样
- 只是类型不同

此时如果继续复制函数，代码很快会被“同一套结构 + 不同类型”占满。

泛型要解决的，就是这种重复。

## 先说结论：泛型不是“把类型去掉”

初学者第一次看到 `T` 时，很容易形成一个错误印象：

- 泛型就是先别管类型

这不准确。

更稳妥的理解是：

- 泛型不是不要类型
- 而是把“稍后再确定的类型”显式留成参数

也就是说，下面这段代码里的 `T`：

```swift
func swapValues<T>(_ a: inout T, _ b: inout T) {
    let temp = a
    a = b
    b = temp
}
```

并不是在说：

- 这里没有类型

而是在说：

- 这里有类型
- 只是这个类型由调用点来决定

这和“不关心类型”是两回事。

## 泛型到底在解决什么问题

当前阶段，可以先把泛型理解成：

- 让同一套代码结构适配多种类型的一种方式

注意这里的关键词是：

- 同一套代码结构

如果逻辑本身都不一样，那么泛型通常帮不上忙。

例如下面这种场景，就很适合泛型：

- 暂存一个值
- 交换两个值
- 维护一个先进先出的队列
- 从数组里查找满足某条件的元素

因为这些问题的“算法结构”并没有因为类型不同而改变。

## 先看泛型函数的最基础语法

最常见的入门写法如下：

```swift
func 函数名<类型参数>(参数) -> 返回值 {
    ...
}
```

例如：

```swift
func printTwice<T>(_ value: T) {
    print(value)
    print(value)
}
```

这里可以先这样理解：

- `T` 是一个类型参数
- `value` 的类型不是提前写死成 `Int` 或 `String`
- 调用时传入什么类型，当前这次调用里的 `T` 就是什么类型

调用时：

```swift
printTwice(12)
printTwice("Swift")
```

这两次调用都能成立，是因为：

- 第一行里，`T` 被当成 `Int`
- 第二行里，`T` 被当成 `String`

## 一个最典型的例子：交换两个值

前面提到的重复函数，可以直接收拢成一份：

```swift
func swapValues<T>(_ a: inout T, _ b: inout T) {
    let temp = a
    a = b
    b = temp
}
```

调用时：

```swift
var firstScore = 80
var secondScore = 95
swapValues(&firstScore, &secondScore)

var firstTitle = "第 1 章"
var secondTitle = "第 2 章"
swapValues(&firstTitle, &secondTitle)
```

这里最值得注意的是：

- `swapValues` 只有一份实现
- 它既能处理 `Int`
- 也能处理 `String`

这正是泛型最直观的价值：

- 不复制逻辑
- 又不丢掉类型信息

## 顺便区分一下：重载和泛型不是一回事

讲到这里，很多读者会自然想到另一种减少“类型不同”带来的写法：

- 重载

例如：

```swift
func printValue(_ value: Int) {
    print("整数：\(value)")
}

func printValue(_ value: String) {
    print("字符串：\(value)")
}
```

这也是合法而且常见的写法。

当前阶段可以先把重载理解成：

- 同一个名字
- 不同的参数列表或参数类型
- 让编译器根据调用方式选择具体版本

所以重载解决的问题更像是：

- 这些操作名字上是同一类事
- 但不同类型需要不同实现

而泛型解决的问题更像是：

- 这些操作连实现结构都一样
- 只是类型不同

## 什么时候更适合重载，什么时候更适合泛型

最稳妥的判断标准是：

- 如果不同类型对应的逻辑本来就不一样，优先考虑重载
- 如果不同类型对应的逻辑结构相同，只是类型不同，优先考虑泛型

例如，下面这种情况更像重载：

```swift
func display(_ value: Int) {
    print("整数值：\(value)")
}

func display(_ value: Double) {
    print(String(format: "%.2f", value))
}
```

这里虽然函数名相同，但两种类型的显示规则并不一样。

而下面这种情况更像泛型：

```swift
func duplicate<T>(_ value: T) -> [T] {
    return [value, value]
}
```

因为这里的核心逻辑始终都是：

- 接收一个值
- 返回装着两个相同值的数组

也就是说，重载和泛型都可能出现在“多个类型都能调用”的场景里，但它们的抽象方向不同：

- 重载：同名，不同实现
- 泛型：同名，同一套实现结构

## 一个很实用的判断顺序：先问“逻辑到底是不是同一份”

如果你看到下面两段代码：

```swift
func parse(_ text: String) -> Int? { ... }
func parse(_ text: String) -> Double? { ... }
```

此时不应该先机械地想：

- 能不能上泛型

而应该先问：

- 它们的解析逻辑是不是本来就完全一样

如果答案不是“完全一样”，那更可能属于：

- 应该分开实现
- 或者使用重载表达不同语义

只有当你确认：

- 差异几乎只在类型参数本身

泛型才会真正自然。

## 先补一个新概念：`Any` 是什么

前面的章节里，我们还没有正式讲过 `Any`。

所以这里先给一个当前阶段够用的理解：

- `Any` 表示“任意类型的值”

例如：

```swift
let values: [Any] = [12, "Swift", true]
```

这段代码表达的是：

- 这个数组里可以同时放 `Int`
- 也可以放 `String`
- 还可以放 `Bool`

也就是说，`Any` 更像是在说：

- 这里我允许不同具体类型混在一起

当前阶段先记住这一层就够了：

- `Any` 能承载很多不同类型的值
- 但它不会像泛型那样，自动帮你保留清楚的类型关系

## 泛型和 `Any` 的区别

很多读者在学到这里时会问：

- 如果只是想接收不同类型，为什么不用 `Any`

这个问题很重要，因为它直接关系到泛型的边界。

前面刚刚说过，`Any` 的核心特点是：

- 它允许不同具体类型放在一起

这在某些场景里确实有用。

但如果你把前面的交换函数写成 `Any` 风格，问题就会出现：

```swift
func printPair(_ first: Any, _ second: Any) {
    print(first, second)
}
```

它可以接收各种值，但它没有表达下面这层重要约束：

- 两个参数应该是同一种类型

而泛型版本：

```swift
func printPair<T>(_ first: T, _ second: T) {
    print(first, second)
}
```

表达的是：

- 这两个参数都属于同一个 `T`

所以泛型的关键优势之一是：

- 它不只是“能装更多类型”
- 它还能表达类型之间的关系

当前阶段你可以先把差别压缩成下面两句：

- `Any`：我先接受很多不同类型的值
- 泛型：我保留“这一次调用里它们是同一种具体类型”这层关系

## 泛型和协议的区别

前面学协议时，你已经知道：

- 协议适合表达共同能力

例如：

```swift
protocol DailyBriefPrintable {
    var name: String { get }
    func dailyBrief() -> String
}
```

如果你写：

```swift
func printBrief(_ item: DailyBriefPrintable) {
    print(item.dailyBrief())
}
```

这表示：

- 只要某个类型遵守 `DailyBriefPrintable`，就能传进来

这是协议的强项。

而泛型更关注的是：

- 当前这份逻辑对“任意某种类型”都成立
- 或者对“满足某种约束的任意类型”都成立

所以当前阶段可以先这样区分：

- 协议：描述能力要求
- 泛型：描述类型参数化

两者经常会一起使用，但它们不是一回事。

## 一个重要问题：泛型参数只是一个占位名字

你会在很多 Swift 代码里看到：

- `T`
- `Element`
- `Value`
- `Key`

这些名字看起来不同，但本质上都在做同一件事：

- 给“尚未确定的类型”起一个占位名

例如：

```swift
func printTwice<T>(_ value: T) { ... }
func printTwice<Value>(_ value: Value) { ... }
```

从语义上看，它们没有本质差别。

不过在真实代码里，命名是否清楚会直接影响可读性。

因此更稳妥的习惯是：

- 简单示例里可以用 `T`
- 一旦进入容器、数据结构或业务场景，尽量用更能说明含义的名字，例如 `Element`

## 泛型类型的最基础语法

泛型不只可以写在函数上，也可以写在类型上。

最常见的入门写法如下：

```swift
struct 类型名<类型参数> {
    ...
}
```

例如：

```swift
struct StudyBox<Item> {
    let item: Item

    func printItem() {
        print(item)
    }
}
```

这里的含义是：

- `StudyBox` 不是某一种具体盒子
- 它是一种“可以装任意某种类型”的盒子

调用时：

```swift
let intBox = StudyBox(item: 100)
let textBox = StudyBox(item: "泛型入门")
```

这两次创建出来的盒子，底层使用的是同一套定义，但装的内容类型不同。

## 一个完整示例：泛型学习队列

这一章如果只停留在 `swapValues<T>`，读者通常还感觉不到泛型真正的组织价值。

所以我们把它放进一个更完整的场景：

- 保存一组待处理内容
- 按进入顺序依次取出

这个结构和具体装的是：

- 学习任务
- 章节标题
- 分数

并没有本质关系。

先看最基础的泛型队列：

```swift
struct StudyQueue<Element> {
    private var items: [Element] = []

    var count: Int {
        return items.count
    }

    var isEmpty: Bool {
        return items.isEmpty
    }

    mutating func enqueue(_ item: Element) {
        items.append(item)
    }

    mutating func dequeue() -> Element? {
        if items.isEmpty {
            return nil
        }

        return items.removeFirst()
    }

    func peek() -> Element? {
        return items.first
    }
}
```

这里最值得关注的是：

- 队列逻辑完全围绕 `Element` 展开
- 但 `Element` 还没有被写死成某个具体类型

所以它可以这样用：

```swift
var chapterQueue = StudyQueue<String>()
chapterQueue.enqueue("第 24 章")
chapterQueue.enqueue("第 25 章")

var scoreQueue = StudyQueue<Int>()
scoreQueue.enqueue(88)
scoreQueue.enqueue(93)
```

这时你会很清楚地看到：

- 队列是一种数据结构
- 它的行为不依赖于具体存什么

这正是泛型类型最适合发挥作用的地方。

## 为什么这里不写两个队列

你当然也可以写：

- `ChapterQueue`
- `ScoreQueue`

但如果这两个类型的行为完全一样，只有元素类型不同，那么这样做通常只是把重复从“函数级别”放大到了“类型级别”。

泛型的意义就在于：

- 把相同结构收拢到一份定义中

于是调用方只需要在使用时说明：

- 这次队列装的是 `String`
- 那次队列装的是 `Int`

## 泛型约束是什么

到目前为止，我们一直在说：

- 泛型可以适配任意类型

但真实代码里常常不是“任意类型都可以”。

例如，如果你想判断两个值是否相等，那么类型至少要支持相等比较。

这时就需要约束。

最基础的写法如下：

```swift
func 函数名<T: 某个协议>(...) {
    ...
}
```

例如：

```swift
func containsMatch<T: Equatable>(_ items: [T], target: T) -> Bool {
    for item in items {
        if item == target {
            return true
        }
    }

    return false
}
```

这里的 `T: Equatable` 表示：

- `T` 必须遵守 `Equatable`

为什么要加这一句？

因为函数内部写了：

```swift
item == target
```

而不是所有类型都能直接用 `==`。

所以约束的本质不是“语法负担”，而是：

- 把这段泛型代码真正依赖的能力说清楚

## 如果你学过 C++：Swift 泛型和模板该怎么建立直觉

这一节只做帮助理解的有限对照，不展开模板元编程、特化、SFINAE 或概念约束这些更深层主题。

如果你学过 C++，那么你看到：

```swift
func swapValues<T>(_ a: inout T, _ b: inout T) { ... }
```

很容易立刻联想到：

```cpp
template <typename T>
void swapValues(T& a, T& b) { ... }
```

这种联想是有帮助的，因为两者都在表达：

- 有一个类型参数
- 同一套逻辑可以适配不同类型

所以在入门直觉上，你完全可以先把 Swift 泛型近似理解成：

- 和 C++ 模板有相似目标的类型参数化工具

但这里一定要补几层关键边界。

### 1. Swift 泛型更像语言主线的一部分，不只是“高级技巧”

在很多 C++ 学习路径里，模板常常会被感知成：

- 泛型容器
- 通用算法
- 再往后是更硬核的模板技巧

而在 Swift 里，泛型并不是特别边缘的一块。

你会很早就在：

- `Array<Element>`
- `Dictionary<Key, Value>`
- `Optional<Wrapped>`

这类标准库类型里不断遇到它。

也就是说，在 Swift 里，泛型是日常语法主线的一部分。

### 2. Swift 泛型通常比 C++ 模板更强调“约束写清楚”

前面你已经看到：

```swift
func containsMatch<T: Equatable>(_ items: [T], target: T) -> Bool
```

这类写法会很直接地把依赖能力写在类型参数旁边。

如果你有 C++ 背景，可以先把它近似联想到：

- 这个模板参数至少得满足某种可比较要求

但 Swift 在入门阶段给人的感受通常会更直接：

- 需要什么能力，就把约束写出来

这种风格和 Swift 整体“把意图写清楚”的路线是一致的。

### 3. 当前阶段不要把 Swift 泛型理解成“模板元编程入口”

这是最容易带偏的地方。

如果你带着 C++ 的经验来学，很容易下意识联想到：

- 偏特化
- 编译期递归
- 各种模板技巧

但当前这条 Swift 教程主线里，泛型首先在解决的是：

- 如何把同一套逻辑安全地复用到不同类型上

所以这里更好的学习顺序不是：

- 先把 Swift 泛型往 C++ 模板的所有高级玩法上类比

而是：

- 先抓住“类型参数化 + 约束 + 标准库容器”这条主线

### 4. Swift 的协议和泛型经常一起出现，这一点要特别注意

如果你学过 C++，很容易先把“抽象”主要联想到：

- 继承
- 虚函数
- 模板

而 Swift 的一个非常鲜明的特点是：

- 协议和泛型经常配合使用

例如：

```swift
func containsMatch<T: Equatable>(...)
```

这里的 `Equatable` 不是在建立父类层次，而是在表达：

- 泛型参数必须具备某种能力

所以更稳妥的理解是：

- C++ 模板常让你首先联想到“按类型生成通用代码”
- Swift 泛型则经常和协议一起，用“能力约束 + 类型参数”组织抽象

### 5. 当前阶段可以怎样近似记忆

如果你已经有 C++ 基础，可以先用一句话建立最实用的映射：

- Swift 泛型在直觉上可以先近似理解成“更强调约束和可读性的模板式类型参数化”

但我在这里一定要补充一句：

- 它不等于把 C++ 模板原封不动搬到 Swift

因为 Swift 里这套能力会更频繁地和：

- 协议
- 标准库泛型容器
- 日常 API 设计

连在一起。

## 一个很实用的判断标准：什么时候该加约束

你可以先问自己一个问题：

- 这段泛型代码在内部到底需要对 `T` 做什么

如果只是：

- 存起来
- 传出去
- 原样返回

那通常不需要额外约束。

如果需要：

- 比较相等
- 调用某个协议方法
- 读取某个协议属性

那就应该把对应约束写出来。

也就是说：

- 约束不是装饰
- 约束是在声明依赖

## 泛型不是越早用越好

很多读者学完这一章后，容易立刻进入另一个误区：

- 只要看到重复，就先上泛型

这也不对。

更稳妥的顺序通常是：

1. 先确认逻辑结构是否真的一样。
2. 再确认差异是否主要只在类型上。
3. 最后再决定是否用泛型统一。

例如下面这种情况，通常就不该强行泛型化：

- 一个函数负责计算平均分
- 另一个函数负责格式化章节标题

它们看起来都“接收参数并返回结果”，但业务逻辑根本不是一回事。

此时真正应该做的是：

- 分开写清楚

而不是为了追求“高级感”把它们抽成一层莫名其妙的泛型外壳。

## 一个常见误区：把泛型理解成运行时随便混类型

当前阶段最需要建立的边界是：

- 泛型不是为了在一个位置里乱装不同类型

那更接近：

- `Any`
- 协议类型

泛型更常表达的是：

- 这一次调用使用某一种具体类型
- 但这份定义可以在不同调用中适配不同类型

所以当你看到：

```swift
StudyQueue<String>
StudyQueue<Int>
```

更好的理解不是：

- 一个队列里同时放字符串和整数

而是：

- 同一个泛型定义，分别生成了两种具体使用方式

## 常见误区

### 1. 以为泛型就是把类型写成 `Any`

不是。

泛型仍然保留类型关系，而 `Any` 更像是把具体类型信息抹平。

### 2. 以为泛型参数 `T` 只是语法占位，没实际意义

不是。

`T` 表示的是一类在调用点被确定的真实类型。

### 3. 以为泛型一定比复制两份代码更好

不是。

如果抽象之后让代码更难读，那么这层泛型通常就没有帮上忙。

### 4. 以为有了泛型就不需要协议

不是。

协议负责表达能力，泛型负责表达类型参数化；它们经常是配合关系。

### 5. 以为重载和泛型可以互相随便替代

不是。

重载更适合同名但实现不同的情况，泛型更适合同一套实现结构只是在类型上变化。

### 6. 以为 Swift 泛型就是 C++ 模板的直接翻版

不是。

它们目标有相似之处，但 Swift 泛型在入门阶段更强调约束、可读性和与协议的配合。

## 本章练习与课后作业

如果你想把这一章的内容真正落实到一个“能跑但很乱”的项目里，可以继续完成下面这道重构作业：

- 作业答案：`exercises/zh-CN/answers/24-generics-reusable-abstractions.md`
- 起始工程：`exercises/zh-CN/projects/24-generics-reusable-abstractions-starter`
- 参考答案工程：`exercises/zh-CN/answers/24-generics-reusable-abstractions`

这一题的重点不是从零写一个新系统，而是清理当前 starter project 里这些典型问题：

- 同结构、不同类型的重复队列
- 只差类型的重复函数
- 不该滥用的 `[Any]`
- 本该保留重载却被混在重复里的位置

更稳妥的做法通常是：

1. 先找出“逻辑结构真的一样”的地方。
2. 再用泛型把这些重复收拢起来。
3. 最后再判断哪些地方其实更适合保留重载。

要求：

- 使用“泛型类型”的形式，重构两套重复队列逻辑。
- 使用“泛型函数”的形式，重构两个重复的复制函数。
- 使用“带 `Equatable` 约束的泛型函数”的形式，重构两个重复的查找函数。
- 保留 `describe(_:)` 这类“同名但实现不同”的重载，不要把它们硬改成泛型。
- 如果愿意，可以`[Any]` 相关代码可以保留为对比例子，但不要再让主流程依赖它组织核心数据。

## 本章小结

这一章最需要记住的是下面这组关系：

- 泛型用于让同一套逻辑适配多种类型
- 重载适合同名但不同实现，泛型适合同一套实现结构参数化
- 泛型不是去掉类型，而是把类型留成参数
- 泛型函数和泛型类型都很常见
- `Any` 适合承载不同类型，泛型更适合表达类型之间的关系
- 协议负责表达能力，泛型负责表达“对某种类型参数成立”
- 对有 C++ 背景的读者，可以把 Swift 泛型先近似理解成带有更清晰约束表达的模板式类型参数化
- 当泛型代码依赖某种能力时，应通过约束把要求写清楚

如果你现在已经能比较稳定地看懂下面这类代码：

- `func swapValues<T>(...)`
- `struct StudyQueue<Element> { ... }`
- `func containsMatch<T: Equatable>(...)`

并且开始知道什么时候不必强行泛型化，那么这一章的核心目标就已经达到了。

## 接下来怎么读

下一章建议继续阅读：

- [25. 闭包：把函数当成值来传递](./25-closures-functions-as-values.md)

因为当你已经能把“类型”留成参数后，下一步一个很自然的问题就是：

- 能不能把“行为本身”也作为参数传进去

这会把主线带到闭包。
