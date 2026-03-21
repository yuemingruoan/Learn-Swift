# 21. 协议：比继承更灵活的抽象方式

## 阅读导航

- 前置章节：[19. 继承：is-a、has-a 与类型层次设计](./19-inheritance-is-a-has-a-modeling.md)、[20. 多态：用统一接口处理不同对象](./20-polymorphism-unified-interfaces.md)
- 上一章：[20. 多态：用统一接口处理不同对象](./20-polymorphism-unified-interfaces.md)
- 建议下一章：[22. 扩展：给已有类型补充能力](./22-extensions-adding-capabilities.md)
- 下一章：[22. 扩展：给已有类型补充能力](./22-extensions-adding-capabilities.md)
- 适合谁先读：已经理解继承和多态，准备学习“不是父子关系，也能统一抽象”的读者

## 本章目标

学完这一章后，你应该能够：

- 理解为什么有些场景不适合继续使用继承
- 看懂协议的最基础定义语法
- 让 `class` 和 `struct` 一起遵守同一个协议
- 使用协议类型统一处理多个不同对象
- 理解协议和继承在建模上的核心差异

## 本章对应目录

- 对应项目目录：`demos/projects/21-protocols-flexible-abstraction`
- 练习与课后作业：后续补充

建议你这样使用：

- 先看正文中协议的语法模板和通用调用形式
- 再运行 `demos/projects/21-protocols-flexible-abstraction`
- 重点观察 `class` 和 `struct` 怎样一起遵守同一个协议

## 为什么继续讲协议

前一章里，我们已经通过继承看到了统一调用的一种写法：

- 用父类类型接收多个不同子类
- 统一调用同一个方法
- 由各个子类提供不同实现

这条路很重要，但它不是唯一的路。

因为程序里经常会遇到一种情况：

- 几个类型都能做某件事
- 但它们并不是 `is-a` 关系

例如：

- 学生可以做学习汇报
- 老师也可以做学习汇报
- 学习机器人也可以做学习汇报

但你很难说：

- 机器人是一种老师
- 老师是一种学生

这时如果还想强行靠继承统一它们，建模就会开始变别扭。

所以这一章真正要解决的问题是：

- 如果几个类型没有合适的父子关系，但又需要统一抽象，该怎么办

Swift 给出的非常重要的一条路就是：

- `protocol`

## 先看协议最基础的语法外形

在进入概念之前，先把协议最常见的代码形状看清楚。

### 定义协议的通用模板

最基础的写法如下：

```swift
protocol 协议名 {
    属性要求
    方法要求
}
```

例如：

```swift
protocol DailyBriefPrintable {
    var name: String { get }
    func dailyBrief() -> String
}
```

这里可以先这样理解：

- `protocol DailyBriefPrintable`：定义一个协议
- `var name: String { get }`：表示遵守这个协议的类型，至少要能提供一个可读的 `name`
- `func dailyBrief() -> String`：表示它还必须提供一个返回 `String` 的方法

当前阶段最重要的认识是：

- 协议在描述“必须具备哪些能力”
- 它不是具体实现

### 类型遵守协议的通用写法

最常见的写法如下：

```swift
class 类型名: 协议名 {
    ...
}

struct 类型名: 协议名 {
    ...
}
```

例如：

```swift
class Student: DailyBriefPrintable {
    let name: String

    init(name: String) {
        self.name = name
    }

    func dailyBrief() -> String {
        return "完成今天的学习任务"
    }
}

struct StudyRobot: DailyBriefPrintable {
    let name: String

    func dailyBrief() -> String {
        return "自动整理今日学习进度"
    }
}
```

这里最值得先记住的是：

- `class` 可以遵守协议
- `struct` 也可以遵守协议
- 这正是协议和“只靠类继承”很不一样的地方

### 协议类型的通用调用形式

这一章最常见的几种调用形式如下：

```swift
let 变量名: 协议名 = 某个遵守协议的实例
变量名.方法名()

let 数组名: [协议名] = [实例1, 实例2, 实例3]
for item in 数组名 {
    item.方法名()
}
```

例如：

```swift
let reporter: DailyBriefPrintable = Student(name: "小林", track: "iOS")
print(reporter.dailyBrief())

let reporters: [DailyBriefPrintable] = [
    Student(name: "小林", track: "iOS"),
    StudyRobot(name: "学习机器人", version: "R1")
]

for item in reporters {
    print(item.dailyBrief())
}
```

你可以先把它们记成：

- `协议类型变量 = 某个遵守协议的实例`
- `[协议类型]` 数组里装多个不同具体类型
- 统一调用协议里定义的方法

这里同样要立刻补一个非常重要的限制：

- 当你把实例放进协议类型变量后，当前就只能按协议要求来使用它

例如：

```swift
let reporter: DailyBriefPrintable = Student(name: "小林", track: "iOS")

print(reporter.name)
print(reporter.dailyBrief())
// print(reporter.track)
```

这里前两行成立，是因为：

- `name`
- `dailyBrief()`

都属于 `DailyBriefPrintable` 的要求。

而 `track` 虽然确实存在于 `Student` 里，但当前阶段你要先记住：

- `reporter` 现在只按协议视角工作
- 所以它看不见协议之外的具体成员

## 为什么有些场景不适合继续用继承

协议最有价值的地方，不是“多学一种语法”，而是它能解决继承不适合解决的问题。

例如，下面这些类型可能都需要做“每日汇报”：

- `Student`
- `Teacher`
- `StudyRobot`

它们的共同点是：

- 都能输出一段汇报内容

但它们的关系并不是：

- 学生是一种老师
- 机器人是一种学生

也就是说，这里虽然存在“共同能力”，但并不存在自然的 `is-a` 层次。

如果你硬要继续靠继承统一它们，就很容易把类型关系写乱。

这正是协议最适合介入的地方：

- 它不要求这些类型是父子关系
- 它只要求这些类型满足同一组能力约定

## 什么是协议

当前阶段，可以先把协议理解成：

- 对一组能力的约定

这里的重点是：

- 协议只说明“你至少要提供这些东西”
- 它不负责把具体逻辑替你写出来

例如：

```swift
protocol DailyBriefPrintable {
    var name: String { get }
    func dailyBrief() -> String
}
```

这段代码并没有告诉你：

- 汇报内容到底写什么

它只是在要求：

- 只要你想遵守这个协议，就必须能提供 `name`
- 并且必须能返回一段 `dailyBrief()`

这就是协议和普通类最不同的地方之一：

- 类可以直接带着状态和实现
- 协议更像一份“能力清单”

## 协议视角能看到什么，不能看到什么

这一点最好和上一章的“父类视角”放在一起理解。

先看这段代码：

```swift
let reporter: DailyBriefPrintable = Student(name: "小林", track: "iOS")

print(reporter.name)
print(reporter.dailyBrief())
// print(reporter.track)
```

这里最稳妥的理解是：

- 协议要求里写了什么，协议类型变量就能稳定使用什么
- 协议要求里没写的具体细节，当前这个抽象视角就不应该直接依赖

所以协议统一调用的代价和价值其实是同一件事：

- 你失去了一部分具体类型细节
- 但换来了更统一、更松耦合的调用方式

## 协议和继承的区别

你可以先把它们的区别压缩成下面这几句：

- 继承强调 `is-a`
- 协议强调“具备某种能力”
- 继承更像建立类型层次
- 协议更像定义接口约定

所以如果你问：

- 什么时候优先想到继承

答案通常是：

- 当你真的在表达父类和子类关系时

如果你问：

- 什么时候优先想到协议

答案通常是：

- 当几个类型没有合适父子关系，但需要共享同一组能力时

## 一个很重要的点：协议不只给 `class` 用

这也是 Swift 风格里非常关键的一点。

前面继承那一套，核心都是围绕 `class` 展开的。

但协议不是。

在 Swift 里，下面这些都可以遵守协议：

- `class`
- `struct`
- 后面你还会看到，别的类型也可以和协议配合

这意味着：

- 统一抽象这件事，不必只靠类层次来完成

这也是为什么很多 Swift 代码会越来越强调：

- 面向协议编程

当前阶段你不需要先把这个词理解得很抽象，只需要先记住：

- 协议让抽象从“父类子类关系”扩展到了“能力约定”

## 如果你学过 C++：和虚函数/类的直觉有什么不同

这一节只做帮助理解的有限对比，不展开 C++ 的对象模型、vtable 或 ABI 细节。

如果你学过 C++，那么你很容易把“统一接口 + 运行时多态”先联想到：

- 基类
- 虚函数
- 派生类

这种联想有帮助，但在 Swift 里需要补一层新认识。

### 1. 协议不是“另一个普通类”

在 C++ 里，你很容易先想到：

- 定义一个基类
- 在里面放虚函数
- 让派生类重写

而 Swift 里的协议更像：

- 先定义一组能力要求

它不是普通父类，也不是具体实现本身。

### 2. 协议不要求类型之间有 `is-a` 关系

C++ 里如果你想靠虚函数做统一调用，很多时候会先建立一棵类继承树。

Swift 里的协议更常表达的是：

- 这些类型都能做某件事

也就是说，它更接近：

- 能力约定

而不一定是：

- 父子类型关系

### 3. 协议可以被 `struct` 和 `class` 一起遵守

这是最值得重点记住的一点。

C++ 里你对虚函数的最常见入门直觉，通常还是围绕类层次展开。

但 Swift 的协议不只给 `class` 用。

例如：

- 一个类可以遵守协议
- 一个结构体也可以遵守同一个协议

这也是 Swift 风格和传统 C++ OOP 直觉最不一样的地方之一。

### 4. 当前阶段可以怎样近似理解

如果只从入门直觉看，你可以先把协议近似理解成：

- 比抽象基类更轻的能力约定

但这里一定要补一句：

- 它不等于把 C++ 的抽象类原封不动搬到 Swift

因为 Swift 协议的使用范围更广，也更常和值类型一起工作。

## 一个完整示例：学习中心每日汇报系统

本章 demo 对应目录：

- `demos/projects/21-protocols-flexible-abstraction`

这一章的示例会出现 3 个具体类型：

- `Student`
- `Teacher`
- `StudyRobot`

它们都需要输出每日汇报，但它们并不是自然的父子关系。

所以这一章不会继续写一棵继承树，而是先定义一个协议：

```swift
protocol DailyBriefPrintable {
    var name: String { get }
    func dailyBrief() -> String
}
```

然后让不同类型分别遵守它：

```swift
class Student: DailyBriefPrintable {
    let name: String
    let track: String

    init(name: String, track: String) {
        self.name = name
        self.track = track
    }

    func dailyBrief() -> String {
        return "继续完成 \(track) 方向的练习"
    }
}

class Teacher: DailyBriefPrintable {
    let name: String
    let subject: String

    init(name: String, subject: String) {
        self.name = name
        self.subject = subject
    }

    func dailyBrief() -> String {
        return "准备 \(subject) 的讲解内容"
    }
}

struct StudyRobot: DailyBriefPrintable {
    let name: String
    let version: String

    func dailyBrief() -> String {
        return "使用 \(version) 模式整理学习进度"
    }
}
```

这里最值得注意的地方是：

- `Student` 是类
- `Teacher` 也是类
- `StudyRobot` 是结构体
- 但它们仍然可以一起遵守 `DailyBriefPrintable`

接下来就可以统一处理这些对象：

```swift
let reporters: [DailyBriefPrintable] = [
    Student(name: "小林", track: "iOS"),
    Teacher(name: "周老师", subject: "Swift"),
    StudyRobot(name: "学习机器人", version: "R1")
]

for reporter in reporters {
    print("\(reporter.name)：\(reporter.dailyBrief())")
}
```

这正是协议在当前阶段最重要的价值：

- 不要求父子关系
- 仍然可以统一调用

与此同时，你也要继续保留一个边界意识：

- 调用方现在依赖的是 `DailyBriefPrintable`
- 所以它应该优先只使用 `name` 和 `dailyBrief()` 这组协议能力

## 什么时候优先想到协议

如果你以后写代码时拿不准该继承还是该协议，可以先问自己下面几个问题。

### 1. 这些类型之间真的有自然的 `is-a` 关系吗

如果没有，就不要为了统一调用硬造一棵继承树。

### 2. 我关心的是“它是什么”，还是“它能做什么”

如果你更关心的是：

- 它能不能输出汇报
- 它能不能被统一调用

那协议通常会更自然。

### 3. 我是不是想让 `struct` 和 `class` 一起参与抽象

如果答案是“是”，协议通常会比继承更灵活。

## 常见误区

### 1. 以为协议只是“没有实现的类”

不是。

更稳妥的理解是：

- 协议是在定义能力要求

### 2. 以为协议只能给 `class` 用

不是。

这一章的 demo 里就会看到：

- `struct` 也可以遵守协议

### 3. 以为只要想统一调用，就必须先建立继承树

不是。

很多时候协议才是更自然的统一抽象入口。

### 4. 把太多具体业务细节塞进协议

当前阶段更稳妥的做法是：

- 协议只保留真正通用的能力要求

## 本章练习与课后作业

如果你想把这一章“协议在什么地方比继承更自然”真正练一遍，建议直接从下面这个起始工程开始：

- 起始工程：`exercises/zh-CN/projects/21-protocols-flexible-abstraction-starter`
- 练习草稿：`exercises/zh-CN/answers/21-protocols-flexible-abstraction.md`

这个工程当前已经能输出汇报，但统一方式还不够自然。你会看到：

- `Student` 是 `class`
- `Teacher` 是 `class`
- `StudyRobot` 是 `struct`
- 它们都能生成简报，但输出流程仍然按具体类型拆开写

这一章建议你完成下面这些重构：

1. 定义 `DailyBriefPrintable`。
2. 让 `Student`、`Teacher`、`StudyRobot` 一起遵守这个协议。
3. 把当前分别输出的流程改成统一遍历 `[DailyBriefPrintable]`。
4. 保持当前业务语义不变。

完成后，你的代码至少应该表现出下面这些特征：

- `class` 和 `struct` 可以一起参与统一抽象
- 输出流程不再需要分开写三段循环
- 调用方主要依赖协议要求，而不是依赖具体类型细节

这道练习最值得你反复确认的是：

- 我现在关心的是它们是什么
- 还是它们能做什么

如果答案偏向后者，这一章通常就更适合优先想到协议

## 本章小结

这一章最需要记住的是下面这组关系：

- 协议描述的是一组能力要求
- 继承强调 `is-a`，协议强调“具备某种能力”
- `class` 和 `struct` 都可以遵守同一个协议
- 协议让没有父子关系的类型也能被统一调用
- 在 Swift 里，协议是非常重要的抽象方式

如果你现在已经能比较稳定地看懂下面这类代码：

- 定义一个 `protocol`
- 让多个不同类型去遵守它
- 用 `[协议类型]` 统一遍历和调用

那么这一章最重要的目标就已经完成了。

## 接下来怎么读

下一章建议继续阅读：

- [22. 扩展：给已有类型补充能力](./22-extensions-adding-capabilities.md)

因为当你已经会定义协议后，接下来一个很自然的问题就是：

- 能不能在不改原类型定义的情况下，给它补充能力
- 能不能把协议遵守和辅助能力按主题拆开组织

第 22 章会专门解决这个问题。
