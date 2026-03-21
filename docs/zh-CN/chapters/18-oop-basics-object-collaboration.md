# 18. 面向对象入门：封装、职责与对象协作

## 阅读导航

- 前置章节：[12. 函数与代码复用](./12-functions-and-code-reuse.md)、[13. 结构体与最基础的自定义类型](./13-structs-and-custom-types.md)、[15. 枚举与 switch：用类型表示有限情况](./15-enums-and-switch.md)、[16. class 与引用语义：为什么改一个地方，另一个地方也会变](./16-class-and-reference-semantics.md)
- 上一章：[17. 选读：从 Optional 到 ARC，理解 Swift 代码背后的运行规则](./17-optional-to-arc-runtime-rules.md)
- 建议下一章：[19. 继承：is-a、has-a 与类型层次设计](./19-inheritance-is-a-has-a-modeling.md)
- 下一章：[19. 继承：is-a、has-a 与类型层次设计](./19-inheritance-is-a-has-a-modeling.md)
- 适合谁先读：已经会写基础类型、函数和自定义类型，准备把程序从“能运行”推进到“更像系统”的读者

## 本章目标

学完这一章后，你应该能够：

- 理解为什么程序继续变大后，需要用对象组织状态和行为
- 理解封装、职责划分、对象协作这三个最基础的 OOP 视角
- 知道 OOP 不是“多写几个 `class`”，而是更清楚地组织代码
- 看懂一个小型对象系统里，不同类型各自负责什么
- 能判断哪些数据和行为应该收进同一个类型里

## 本章对应目录

- 对应项目目录：`demos/projects/18-oop-basics-object-collaboration`
- 练习与课后作业：无

建议你这样使用：

- `demos/projects/18-oop-basics-object-collaboration`：直接运行本章完整示例，先观察不同对象怎样分工，再回来看正文
- 正文中的代码片段：重点看“谁负责保存数据”“谁负责执行动作”“谁负责协调多个对象”

## 先看最基础的语法外形

在进入 OOP 概念之前，最好先把这一章最常见的语法形式看清楚。

### 定义一个最基础的类

最常见的写法如下：

```swift
class 类型名 {
    属性定义

    init(参数列表) {
        初始化逻辑
    }

    func 方法名(参数列表) -> 返回值类型 {
        方法逻辑
    }
}
```

例如：

```swift
class StudyPlan {
    var name: String
    var finishedCount: Int

    init(name: String, finishedCount: Int) {
        self.name = name
        self.finishedCount = finishedCount
    }

    func printSummary() {
        print(name, finishedCount)
    }
}
```

这里最基础的阅读方式是：

- `class StudyPlan`：定义一个类
- `var name`、`var finishedCount`：这是属性
- `init(...)`：这是创建实例时使用的初始化器
- `func printSummary()`：这是方法

### 通用的创建与调用形式

当前阶段，这一章最常见的几种调用形式如下：

```swift
let 实例名 = 类型名(参数)
实例名.属性名
实例名.属性名 = 新值
实例名.方法名()
实例名.方法名(参数)
```

例如：

```swift
let plan = StudyPlan(name: "Swift 入门计划", finishedCount: 0)
print(plan.name)
plan.finishedCount = 1
plan.printSummary()
```

你可以先把它们直接记成：

- `类型名(...)`：创建实例
- `实例.属性`：读取属性
- `实例.属性 = ...`：修改属性
- `实例.方法(...)`：调用方法

## 为什么现在开始讲 OOP

到前面几章为止，你已经掌握了不少很关键的基础能力：

- 能声明变量和常量
- 能进行条件判断和循环
- 能把重复逻辑提炼成函数
- 能用 `struct`、`enum`、`class` 定义自己的类型

这时你已经不再只是“刚接触 Swift 语法”的阶段了，而是开始进入另一个真实问题：

- 当程序越来越长时，代码该怎么组织

前面很多示例都还能靠一个 `main.swift` 顶住，是因为：

- 场景还比较小
- 变量还不算多
- 逻辑链路也不算长

但只要程序再复杂一点，就会很快暴露这些问题：

- 数据分散在很多变量里，不容易看出它们属于同一件事
- 函数越来越多，但读代码时不容易看出它们服务的是谁
- `main.swift` 像一个“总控台”，什么都在里面做
- 某段逻辑该改到哪里，边界越来越模糊

这就是面向对象思想真正开始发挥作用的地方。

## OOP 不是“只会写 class”

很多初学者一听到 OOP，会马上想到：

- 类
- 对象
- 继承
- 多态

这些当然都和 OOP 有关，但如果一开始只记成术语表，很容易把重点搞反。

当前阶段更稳妥的理解应该是：

- OOP 首先是一种组织程序的视角
- 它关心的是“谁拥有哪些状态”“谁负责哪些行为”“不同对象如何协作”

也就是说，OOP 的重点不是：

- 语法看起来像不像教材

而是：

- 程序中的职责划分是不是更清楚

在 Swift 里，这一点尤其需要说清。因为 Swift 不是那种“只有 `class` 才算类型设计”的语言。

前面我们已经学过：

- `struct` 可以组织数据
- `enum` 可以表达有限状态
- `class` 可以表达共享实例和引用语义

所以更准确的说法是：

- Swift 里可以用很多类型做设计
- 但从这一章开始，我们借助 `class` 来建立最直观的“对象协作”感觉

## 先把一个误区提前说清：OOP 不是 `class` 崇拜

这里最好先把第 16 章学过的判断标准重新接上。

前面我们已经知道：

- `struct` 更偏值语义
- `class` 更偏引用语义

所以进入 OOP 之后，真正应该新增的不是：

- “以后看到设计题就先写 `class`”

而是：

- “先想清楚谁负责什么，再决定它更适合值语义还是引用语义”

也就是说，当前这一章真正要讲的是：

- 怎样把状态和行为组织回合理的边界里
- 怎样让多个类型自然协作

至于 `struct` 还是 `class`，仍然要回到语义判断。

例如，在本章的学习中心示例里：

- `StudyTask` 更像一份任务数据，适合优先按 `struct` 理解
- `StudyPlan` 需要统一管理一组任务进度，更适合先按一个协作主体来设计
- `Student` 和 `LearningCenter` 更强调“谁负责发起动作、谁负责汇总结果”

你现在可以先记住这个顺序：

1. 先判断职责和边界
2. 再判断值语义还是引用语义

## 什么叫“对象”

当前阶段，不需要先把“对象”想得太玄。

你可以先把对象理解成：
- 一个有自身状态与行为的具体实例

例如，一个学习计划对象，可能会有：

- 计划名
- 任务列表
- 当前完成进度

同时它也可能会做：

- 添加任务
- 完成任务
- 输出进度摘要

这时它就不再只是几项零散数据，而是一个“拥有且能够管理自身状态”的对象。

## 从“零散变量 + 零散函数”到“对象负责自己的事”

先看一种很容易在入门程序里出现的写法：

```swift
var planName = "Swift 入门计划"
var taskTitles = ["读正文", "运行示例", "整理笔记"]
var finishedCount = 0

func finishTask() {
    finishedCount += 1
}

func printSummary() {
    print(planName, finishedCount, taskTitles.count)
}
```

这段代码当然可以运行，但它有几个明显问题：

- `planName`、`taskTitles`、`finishedCount` 明明都在描述同一个计划，却分散在外面
- `finishTask()` 和 `printSummary()` 虽然服务于计划，但函数本身没有明确挂靠对象
- 如果后面再出现第二个学习计划，代码会立刻变得很 awkward

更自然的做法通常是把这些东西收回同一个类型里：

```swift
class StudyPlan {
    var name: String
    var taskTitles: [String]
    var finishedCount: Int

    init(name: String, taskTitles: [String], finishedCount: Int = 0) {
        self.name = name
        self.taskTitles = taskTitles
        self.finishedCount = finishedCount
    }

    func finishTask() {
        finishedCount += 1
    }

    func printSummary() {
        print(name, finishedCount, taskTitles.count)
    }
}
```

这样做之后，代码表达的含义会清楚很多：

- 这些数据属于 `StudyPlan`
- 这些动作也是 `StudyPlan` 自己负责

这就是 OOP 里最重要的起点之一：

- 让相关状态和行为回到它们真正所属的对象里

## 什么是封装

在当前阶段，可以先把封装理解成：

- 把同一件事相关的数据和操作收进同一个类型里

这里的重点不是“把所有细节都藏起来”，而是先做到：

- 谁的数据归谁管
- 谁的行为归谁实现

例如，学习计划的进度统计，本质上就是学习计划自己的事。

那更自然的写法就应该是：

- `StudyPlan` 自己知道一共有多少任务
- `StudyPlan` 自己知道已经完成了多少任务
- `StudyPlan` 自己输出进度信息

而不是：

- `main.swift` 到处拼命读它的属性，再自己做一堆计算

所以封装带来的第一个好处并不是“高级”，而是：

- 边界清楚

在本章 demo 里，你还会看到一种很轻量的做法：

- 外部对象不直接伸手进去改另一个对象的内部状态

例如：

- `Student` 不会把 `StudyPlan` 的任务数组直接暴露给外部
- `LearningCenter` 只读取学生对外提供的进度结果

如果你在示例代码里看到 `private` 或 `private(set)`，当前阶段先把它理解成：

- 这个内部状态应该由类型自己管
- 外部可以拿结果，但不应该随便直接改

## 什么是职责划分

OOP 的第二个核心视角，是职责划分。

也就是说，你不只要问：

- 程序要做什么

还要继续追问：

- 这件事应该由哪个对象负责

例如，在一个学习中心示例里：

- `StudyTask` 负责表示单个任务数据
- `StudyPlan` 负责管理一组任务和进度
- `Student` 负责执行自己的学习动作
- `LearningCenter` 负责观察多个学生的整体情况

这时你会发现，程序虽然功能更多了，但反而更容易读。因为它已经不是：

- 一堆没有边界的变量和函数

而是：

- 多个对象各自处理自己那一块

## 什么是对象协作

光有单个对象还不够，程序真正变得像系统，是从对象协作开始的。

所谓对象协作，你可以先把它理解成：

- 一个对象在需要时，调用另一个对象提供的能力，共同完成任务

例如：

- 学生对象想完成一项任务
- 它不会自己重新实现“查找任务、修改状态、计算进度”这整套逻辑
- 它会把这件事交给自己的学习计划对象处理

这时程序结构就会更自然：

- `Student` 负责发起动作
- `StudyPlan` 负责管理任务
- `StudyTask` 负责提供单个任务的数据表示

这就是“对象之间协作完成事情”的最基础样子。

## 一个不够好的信号：`main.swift` 什么都在管

从当前教程的视角看，有一个非常实用的判断标准：

- 如果你发现 `main.swift` 正在亲自管理所有变量、所有流程、所有计算，那通常说明职责还没有拆开

当然，小程序里这样写完全可以。

但一旦你开始遇到下面这些现象，就要开始考虑 OOP 的组织方式：

- 某个功能需要读写很多相关变量
- 相同的一组数据，总是一起出现
- 某段逻辑只服务于某一类对象
- 增加第二个“同类对象”时，原有代码会明显变乱

## 一个完整示例：学习中心中的对象协作

本章 demo 对应目录：

- `demos/projects/18-oop-basics-object-collaboration`

这一章的示例会出现 4 个主要类型：

- `StudyTask`
- `StudyPlan`
- `Student`
- `LearningCenter`

它们的分工分别是：

- `StudyTask`：表示一项具体任务数据，例如“阅读第 18 章”
- `StudyPlan`：管理任务列表和完成进度
- `Student`：持有自己的学习计划，并执行学习动作
- `LearningCenter`：观察多个学生的总体学习情况

先看最基础的任务数据：

```swift
struct StudyTask {
    let title: String
    let estimatedHours: Int
    var isFinished: Bool
}
```

这时你可以先建立一个很朴素的直觉：

- 单个任务更像一份值数据
- 它先不承担“协调整个系统”的责任

然后是学习计划：

```swift
class StudyPlan {
    let name: String
    private(set) var tasks: [StudyTask]

    init(name: String, tasks: [StudyTask]) {
        self.name = name
        self.tasks = tasks
    }

    func finishTask(at index: Int) {
        tasks[index].isFinished = true
    }

    func progressText() -> String {
        var finished = 0

        for task in tasks {
            if task.isFinished {
                finished += 1
            }
        }

        return "已完成 \(finished)/\(tasks.count)"
    }
}
```

这里最关键的不是语法，而是职责：

- `StudyPlan` 不负责“学生今天有没有心情学习”
- 它只负责管理自己的任务和进度

这里你也可以顺手注意一下：

- `tasks` 没有继续完全暴露给外部随便改
- 这更符合“进度由 `StudyPlan` 自己维护”的封装边界

再看学生：

```swift
class Student {
    let name: String
    private let plan: StudyPlan

    init(name: String, plan: StudyPlan) {
        self.name = name
        self.plan = plan
    }

    func completeTask(at index: Int) {
        plan.finishTask(at: index)
    }

    func progressText() -> String {
        return plan.progressText()
    }
}
```

这时你会发现，协作关系已经出现了：

- `Student` 知道自己有一个 `StudyPlan`
- 当学生想完成任务时，它不是自己乱改所有状态
- 它是把动作转交给 `StudyPlan`

最后，学习中心对象再把多个学生组织起来：

```swift
class LearningCenter {
    let name: String
    var students: [Student]

    init(name: String, students: [Student]) {
        self.name = name
        self.students = students
    }

    func printOverview() {
        print("当前学习中心：\(name)")

        for student in students {
            print("\(student.name)：\(student.progressText())")
        }
    }
}
```

这个例子最值得观察的地方是：

- 没有哪个对象在“偷偷管一切”
- 每个对象都只负责自己那部分最自然的工作

这就是 OOP 在入门阶段最有价值的地方。

## 这一章不急着讲继承

你可能已经注意到：

- 这一章确实在讲对象
- 但还没有讲继承

这是刻意安排的。

因为继承不是 OOP 的起点。

在很多初学者那里，一上来就讲继承会带来一个误解：

- 似乎只要学了“父类子类”，就算学会了 OOP

但真正更基础的问题其实是：

- 你会不会拆职责
- 你知不知道哪些状态和行为应该放在一起
- 你能不能让对象之间用自然的方式协作

如果这层还不稳，就直接进入继承，后面很容易变成：

- 为了复用一点代码就随便继承

所以这一章先把对象协作讲稳，下一章再讨论什么时候真的适合引入继承。

## Swift 里要不要把所有东西都写成 class

不要。

这一点最好现在就先建立明确认识。

虽然本章用 `class` 来建立对象直觉，但并不意味着：

- 以后做设计时，所有类型都应该优先写成 `class`

前面第 16 章已经讲过：

- `struct` 更偏值语义
- `class` 更偏引用语义

所以更稳妥的思路仍然是：

- 先看建模和职责
- 再看值语义还是引用语义更合适

当前这一章的重点只是：

- 先建立“对象负责自己的状态和行为”这层思维方式
- 不是把所有东西机械地改写成 `class`

## 本章最需要建立的判断标准

这一章最重要的，不是背下“OOP”这个缩写，而是开始习惯问下面这些问题：

### 1. 这些数据是不是本来就在描述同一件事

如果答案是“是”，就要开始想：

- 它们是不是应该被收进同一个类型

### 2. 这段逻辑是不是天然只服务于某个对象

如果答案是“是”，就要开始想：

- 这段逻辑是不是更适合变成这个对象的方法

### 3. 当前流程是不是可以拆成多个对象协作完成

如果答案是“是”，程序通常会比“一个大函数全包办”更清楚。

## 常见误区

### 1. 以为 OOP 就是“把函数改成方法”

方法当然是对象的一部分，但这还不够。

真正的重点是：

- 数据和行为有没有回到它们真正所属的对象里

### 2. 以为只要用了 `class` 就已经是 OOP

如果一个类里只是在机械地堆属性和方法，没有清楚职责边界，那仍然可能很乱。

反过来也是一样：

- 一个 `struct` 只要边界清楚、职责合理，也完全可以出现在 OOP 风格的设计里

### 3. 一个对象负责太多事

比如既负责输入、又负责统计、又负责显示、又负责管理别的对象。

这种写法虽然看起来“封装进类里了”，但职责其实仍然混乱。

### 4. 什么都留在 `main.swift`

如果对象已经存在，但 `main.swift` 仍然亲自改所有内部状态，那说明对象的边界还没真正建立起来。

## 本章练习与课后作业

如果你想把这一章的“封装、职责划分、对象协作”真正练一遍，建议直接从下面这个起始工程开始：

- 起始工程：`exercises/zh-CN/projects/18-oop-basics-object-collaboration-starter`
- 练习草稿：`exercises/zh-CN/answers/18-oop-basics-object-collaboration.md`

这个工程当前已经可以运行，但结构保持在“还比较散”的状态。你会看到：

- 同一件事的数据仍然散落在顶层变量里
- 进度统计和完成任务逻辑还留在顶层函数中
- `main.swift` 仍然亲自管理所有状态

这一章建议你完成下面这些重构：

1. 提取 `StudyPlan`，让任务和进度统计回到计划对象内部。
2. 提取 `Student`，让学生对象负责发起“完成任务”的动作。
3. 提取 `LearningCenter`，让学习中心对象负责输出整体概览。
4. 减少 `main.swift` 对内部状态的直接读写。

完成后，你的代码至少应该表现出下面这些特征：

- `progressText()` 不再依赖顶层数组和顶层变量
- `finishTask(at:)` 不再是顶层函数
- `main.swift` 不再直接修改任务完成状态
- 输出结果仍然和起始工程大体一致

这道练习最重要的不是“多写几个类”，而是开始稳定地回答下面这类问题：

- 这件事归谁管
- 这段逻辑该挂在哪个对象上
- `main.swift` 有没有从“总控台”退回到只负责串联流程

## 本章小结

这一章最需要记住的不是抽象术语，而是下面这组关系：

- OOP 首先是一种组织程序的方式
- 封装强调把相关状态和行为放回同一个对象里
- 职责划分强调不同对象各自负责最自然的那部分工作
- 对象协作强调多个对象通过调用彼此能力共同完成任务
- “会写 `class`” 不等于“已经把程序组织清楚”

如果你现在已经开始主动问自己：

- 这组数据属于谁
- 这段逻辑该挂在哪个对象上
- 这件事该由哪个对象负责

那么这一章最重要的目标就已经达到了。

## 接下来怎么读

下一章建议继续阅读：

- [19. 继承：is-a、has-a 与类型层次设计](./19-inheritance-is-a-has-a-modeling.md)

因为当你已经开始用对象组织程序后，接下来最自然的问题就是：

- 如果几个类型有共同部分，什么时候应该抽成父类
- 什么时候真的适合继承
- 什么时候看起来相似，但其实不该继承

下一章会专门围绕这个判断标准展开。
