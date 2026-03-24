# 28. 选读：ARC 进阶：weak、unowned 与循环引用

## 阅读导航

- 前置章节：[16. class 与引用语义：为什么改一个地方，另一个地方也会变](./16-class-and-reference-semantics.md)、[17. 选读：从 Optional 到 ARC，理解 Swift 代码背后的运行规则](./17-optional-to-arc-runtime-rules.md)、[25. 闭包：把函数当成值来传递](./25-closures-functions-as-values.md)
- 上一章：[27. 协议扩展与默认实现：把抽象和复用放在一起](./27-protocol-extensions-and-default-implementations.md)
- 建议下一章：[29. 并发入门：async/await 与 Task](./29-concurrency-basics-async-await-and-task.md)
- 下一章：[29. 并发入门：async/await 与 Task](./29-concurrency-basics-async-await-and-task.md)
- 适合谁先读：已经理解 `class`、引用语义和闭包捕获，并且愿意进一步追问对象生命周期细节的读者

## 本章目标

学完这一章后，你应该能够：

- 知道 ARC 到底是什么，以及它在管理什么
- 理解强引用循环为什么会发生
- 看懂 `weak` 和 `unowned` 的最基础写法
- 区分什么时候更适合 `weak`，什么时候更适合 `unowned`
- 理解为什么 `weak` 通常要配合 Optional 使用
- 看懂闭包捕获 `self` 时可能出现的问题
- 使用捕获列表写出最基础的 `[weak self]`
- 建立“先判断生命周期关系，再选写法”的思维顺序

## 本章对应目录

- 对应项目目录：`demos/projects/28-arc-advanced-weak-unowned-and-capture-lists`
- 练习起始工程：`exercises/zh-CN/projects/28-arc-advanced-weak-unowned-and-capture-lists-starter`
- 练习答案文稿：`exercises/zh-CN/answers/28-arc-advanced-weak-unowned-and-capture-lists.md`
- 练习参考工程：`exercises/zh-CN/answers/28-arc-advanced-weak-unowned-and-capture-lists`

建议你这样使用：

- 先把本章当成“帮助你建立内存管理直觉的选读”来读，而不是当成必须立刻掌握的主线章节
- 阅读时重点跟踪每个对象之间到底是谁持有谁
- 尤其注意闭包部分，它和前面的“闭包会捕获外部变量”是同一条主线的延伸

你可以这样配合使用：

- `demos/projects/28-arc-advanced-weak-unowned-and-capture-lists`：先看“整理好的释放观察示例”，建立 `weak`、`unowned`、`[weak self]` 的直觉。
- `exercises/zh-CN/projects/28-arc-advanced-weak-unowned-and-capture-lists-starter`：再打开“关系写错但还能跑”的版本，自己分析哪里把对象留住了。
- `exercises/zh-CN/answers/28-arc-advanced-weak-unowned-and-capture-lists.md`：做完后对照每条关系为什么这样改。
- `exercises/zh-CN/answers/28-arc-advanced-weak-unowned-and-capture-lists`：最后运行参考答案工程，观察释放顺序。

导读建议：

- 先看 demo 里的“完整功能：课程对象关系管理”，把 `Teacher` 和 `Classroom` 的持有关系画出来，再对应正文里的强引用循环。
- 再看“unowned 适合始终存在的所属关系”，体会为什么 `ChapterNote` 不该强持有 `Chapter`。
- 接着看“闭包也可能形成循环引用”，把 `StudySession` 和 `onFinish` 之间的关系和正文中的闭包捕获小节对照起来。
- 最后看“这一章最想演示的差别”，重新确认 `weak`、`unowned`、`[weak self]` 分别在解决哪一段关系。

## 这篇选读适合谁

这一章不是主线必读章。

它更适合下面这类读者：

- 已经能稳定理解 `class`、引用语义和闭包
- 对“对象什么时候释放、为什么没有释放”这种问题比较敏感
- 愿意花一点时间建立更稳的内存管理直觉
- 有`C/C++` 或 `java` 基础的学生

如果你当前更关心的是：

- 先把 Swift 主线语法走通
- 先把泛型、闭包、集合操作这些常用能力用起来

那么这一章完全可以暂时跳过，等后面真的遇到：

- 循环引用
- 回调里捕获 `self`
- 某个对象为什么一直不释放

这类问题时再回来看。

## 阅读前说明：这一章会明显比主线更难

这一章的难点不在于关键字数量，而在于它要求你同时追踪：

- 谁在强持有谁
- 谁只是弱引用
- 哪个对象应该先释放
- 闭包为什么也会形成引用环

也就是说，本章更多是在训练一种判断方式：

- 先画清关系
- 再决定该不该用 `weak` 或 `unowned`

所以你如果第一次读的时候觉得它比前几章难很多，这是正常现象。

更稳妥的阅读方式不是一口气死记所有写法，而是：

1. 先看对象之间的关系图。
2. 再看哪条关系不该是强引用。
3. 最后再看 `weak`、`unowned`、`[weak self]` 分别落在什么位置。

## 为什么现在学习 `weak`、`unowned` 和循环引用

前面你已经知道：

- `class` 具有引用语义
- 多个变量可能同时引用同一个实例
- 闭包会捕获外部变量

但前面的主线里，我们其实还没有专门把 ARC 从头讲清楚。

也就是说，你可能已经见过这些现象：

- 一个对象明明看起来该结束了，却还没有释放
- 两个对象互相记着对方后，`deinit` 没有触发
- 闭包里用了 `self` 之后，生命周期开始变复杂

却还没有系统建立下面这个最基础的问题：

- ARC 到底是什么

这一章就是从这里开始补。

在这个基础上，一个非常现实的问题才会出现：

- 如果两个对象互相强持有，会发生什么
- 如果一个对象强持有闭包，而闭包又强持有这个对象，会发生什么

如果不继续往下学，很多人都会停留在一种模糊理解：

- ARC 会自动管理内存，所以我不用想太多

这句话只说对了一半。

更完整的事实是：

- ARC 会管理引用计数
- 但它不会替你猜测哪些强引用关系是多余的

所以本章真正要解决的问题是：

- 当对象之间形成环时，应该怎样表达“这里不该继续强持有”

## 先从最基础的问题开始：ARC 是什么

ARC 是：

- Automatic Reference Counting

当前阶段不需要先死记英文全称，只要先记住它的中文含义就够了：

- 自动引用计数

这里最关键的词是：

- 引用计数

也就是说，ARC 做的事情不是：

- 神秘地扫描整个程序，判断哪些对象“看起来没用了”

而是更具体的一件事：

- 记录一个对象当前还被多少个强引用持有

如果一个对象的强引用计数还大于 0，那么它通常就不能被释放。

如果一个对象的强引用计数降到 0，那么它才有机会被释放。

所以当前阶段可以先把 ARC 近似理解成：

- Swift 用来管理 `class` 实例生命周期的一套自动计数机制

## 为什么这一章主要围绕 `class` 展开

这一点最好在最前面就说清。

这一章反复谈到的：

- 强引用
- 弱引用
- 循环引用
- `deinit`

核心几乎都围绕 `class`。

原因不是：

- 只有 `class` 才重要

而是：

- ARC 当前最直接关心的，是类实例之间的引用关系

前面你已经学过：

- `struct` 更强调值语义
- `class` 更强调引用语义

这正是为什么 ARC 章节必须主要围绕 `class` 来讲。

所以当前阶段你可以先建立一个很实用的入口直觉：

- 一旦问题开始变成“这个对象为什么还活着”
- 你就应该优先想到：是不是某些 `class` 实例之间还在互相引用

## 什么叫“引用计数”

先看一个最简单的例子：

```swift
class StudyRoom {
    let name: String

    init(name: String) {
        self.name = name
    }

    deinit {
        print("\(name) 被释放")
    }
}

var roomA: StudyRoom? = StudyRoom(name: "Swift 教室")
var roomB = roomA
```

当前阶段你可以先这样理解：

- `roomA` 引用了这个 `StudyRoom` 实例
- `roomB` 现在也引用了同一个实例

所以这个对象并不是“只被一个变量记住”。

如果这时只写：

```swift
roomA = nil
```

通常还不会释放，因为：

- `roomB` 还在引用它

只有当：

```swift
roomB = nil
```

也发生之后，这个对象才更有可能真正结束生命周期。

这里最重要的不是把计数过程想得多底层，而是先建立一个判断标准：

- 只要还有强引用存在，对象就不能释放

## ARC 到底在管什么

现在再回到 ARC 本身，就更容易读顺了。

当前阶段可以先把 ARC 再压缩成一句话：

- 只要一个 `class` 实例还有强引用，它通常就不会被释放

反过来说：

- 当强引用计数降到 0 时，实例才有机会离开内存

所以一切问题的核心都在：

- 哪些地方算强引用
- 谁在持续持有谁

## 如果你学过 C++：对象生命周期管理该怎么对照理解

这一节只做帮助理解的有限对照，不展开 C++ 的完整对象模型、拷贝控制、移动语义或分配器设计。

如果你有 C++ 背景，那么读到 ARC 时，最容易下意识想到的就是：

- 构造函数什么时候执行
- 析构函数什么时候执行
- `unique_ptr`、`shared_ptr`、`weak_ptr` 分别在做什么

这种联想是有帮助的，因为 Swift 这里讨论的也确实是：

- 对象什么时候创建
- 对象什么时候结束
- 谁在拥有对象

但 Swift 和 C++ 的进入方式并不完全一样。

### 1. 构造函数：Swift 的 `init` 和 C++ 的构造函数可以建立近似直觉

例如这段 Swift 代码：

```swift
class StudyRoom {
    let name: String

    init(name: String) {
        self.name = name
    }
}
```

如果你学过 C++，可以先把 `init` 近似理解成：

- 构造函数负责把对象初始化好

这一层直觉是成立的。

所以当前阶段可以先这样记：

- C++ 的构造函数和 Swift 的 `init`，都在负责对象初始建立时的准备工作

### 2. 析构函数：Swift 的 `deinit` 和 C++ 的析构函数也有相似职责

前面你已经看到：

```swift
deinit {
    print("\(name) 被释放")
}
```

如果你学过 C++，可以自然联想到：

- 析构函数在对象结束生命周期时执行

这层对应同样是有帮助的。

所以在入门直觉上，你可以把：

- Swift 的 `deinit`

近似理解成：

- C++ 析构函数在 Swift 里的对应位置

但这里一定要补一个很关键的差别：

- C++ 里很多对象的销毁时机，初学阶段常常和作用域结束、栈对象离开作用域直接绑定
- Swift 这里讨论的 `class` 实例，则更直接地和“强引用计数是否归零”绑定

也就是说，在这一章的语境里，更重要的问题不是：

- 这个对象是不是离开了当前花括号

而是：

- 这个对象是不是还被某些强引用继续持有

### 3. ARC 和智能指针的对照，最值得抓住“所有权”这个词

如果你学过 C++，那么 Swift 这套机制最容易建立直觉的地方，往往不是析构函数本身，而是：

- 智能指针到底在表达谁拥有对象

这里可以先做一个非常粗略但足够入门的近似对照：

- Swift 的强引用，直觉上有点像 `shared_ptr` 持有对象
- Swift 的 `weak`，直觉上有点像 `weak_ptr`

这层类比为什么有帮助？

因为它们都在表达：

- 有的引用会参与“对象还要不要继续活着”的判断
- 有的引用只是“知道对象在哪里”，但不负责把对象留住

不过这里一定要补一句非常重要的话：

- 不要把 Swift 引用和 C++ 智能指针逐一机械对号入座

因为 Swift 的 ARC 是语言层的默认生命周期管理机制，而不是你像 C++ 那样在每个地方显式选择：

- 裸指针
- 栈对象
- `unique_ptr`
- `shared_ptr`
- `weak_ptr`

当前阶段更稳妥的理解是：

- Swift 在 `class` 这条线上，默认就帮你采用了“引用计数式”的管理思路

### 4. 为什么这里最不像 C++ 初学阶段的，是“你不会总先想到栈对象”

很多 C++ 初学者一谈生命周期，第一反应是：

- 对象定义在作用域里
- 作用域结束就析构

这条直觉在 C++ 里很常见，也很重要。

但在 Swift 当前这条主线里，当你讨论 `class` 时，更应该先想到的是：

- 这个实例当前还被谁引用着

因为这里最常见的问题不是：

- 花括号结束了没有

而是：

- 某两个对象是不是还在互相强持有
- 某个闭包是不是还在强持有 `self`

### 5. 当前阶段可以怎样近似记忆

如果你已经有 C++ 基础，可以先用下面这几句帮助自己建立最稳的直觉：

- `init` 可以先近似理解成构造函数
- `deinit` 可以先近似理解成析构函数
- 强引用计数的味道，和 `shared_ptr` / `weak_ptr` 这套“谁拥有对象”思路更接近
- 但 Swift 的 ARC 是语言默认机制，不等于把 C++ 智能指针原封不动搬过来

这样理解之后，再去看后面的：

- 强引用循环
- `weak`
- `unowned`
- `[weak self]`

通常就会顺很多。

## 什么叫强引用循环

最基础的场景如下：

- `Teacher` 对象强引用 `Classroom`对象
- `Classroom` 对象又强引用 `Teacher`对象

代码可能长这样：

```swift
class Teacher {
    let name: String
    var classroom: Classroom?

    init(name: String) {
        self.name = name
    }

    deinit {
        print("Teacher \(name) 被释放")
    }
}

class Classroom {
    let roomID: String
    var teacher: Teacher?

    init(roomID: String) {
        self.roomID = roomID
    }

    deinit {
        print("Classroom \(roomID) 被释放")
    }
}
```

如果这样建立关系：

```swift
var teacher: Teacher? = Teacher(name: "周老师")
var classroom: Classroom? = Classroom(roomID: "A101")

teacher?.classroom = classroom
classroom?.teacher = teacher

teacher = nil
classroom = nil
```

很多初学者会本能地期待：

- 两个变量都设成 `nil`
- 对象就应该被释放

但实际问题在于：

- `teacher` 变量虽然没了
- `Teacher` 实例仍被 `Classroom` 实例强持有
- `classroom` 变量虽然没了
- `Classroom` 实例仍被 `Teacher` 实例强持有

于是这两个对象就互相拽住了对方。

这就是强引用循环。

## 为什么这不是“ARC 失效”

这个误区非常常见。

ARC 并没有失效。

ARC 的规则一直都很一致：

- 只要还有强引用，实例就不能释放

而在强引用循环里，问题恰恰在于：

- 强引用确实还存在

所以更稳妥的理解不是：

- ARC 没发现垃圾

而是：

- 你把一段本来不该是强持有的关系写成了强持有

本章后面的 `weak` 和 `unowned`，本质上就是在解决这个问题。

## `weak` 的最基础写法

最常见的写法如下：

```swift
weak var 属性名: 某个类类型?
```

例如：

```swift
class Classroom {
    let roomID: String
    weak var teacher: Teacher?

    init(roomID: String) {
        self.roomID = roomID
    }
}
```

这里的含义是：

- `Classroom` 知道自己的老师是谁
- 但这种“知道”不应该被计入引用

也就是说：

- `weak` 表示弱引用
- 弱引用不会增加强引用计数

于是前面的环就被打破了。

如果继续沿用前面那组 `Teacher` 和 `Classroom` 的变量：

```swift
var teacher: Teacher? = Teacher(name: "周老师")
var classroom: Classroom? = Classroom(roomID: "A101")

teacher?.classroom = classroom
classroom?.teacher = teacher
```

并且这里的 `teacher` 已经改成了 `weak`，那么释放过程就会变成这样：

1. `teacher = nil`
   `Teacher` 实例少掉了一个强引用。
   如果这时没有别的强引用，它就会被释放。
2. `Teacher` 释放后，`Classroom.teacher` 这条弱引用会自动变成 `nil`。
3. `classroom = nil`
   `Classroom` 实例自己的最后一个强引用也消失，于是 `Classroom` 也会被释放。

这里最值得你抓住的一点不是“谁先打印 `deinit`”，而是：

- `Classroom.teacher` 只是弱引用
- 所以它不会把 `Teacher` 留住
- 当 `Teacher` 离开后，这条关系会自动清空

## 为什么 `weak` 通常要写成 Optional

这是一个必须先建立的稳定认识。

你会发现 `weak` 最常见的写法是：

```swift
weak var teacher: Teacher?
```

而不是：

```swift
weak var teacher: Teacher
```

原因在于：

- 当被引用对象释放后
- 弱引用需要自动变成 `nil`

所以它必须能表示“现在已经没有对象了”。

当前阶段可以先简单记成：

- `weak` 总是和 `Optional` 一起出现

## 什么时候适合用 `weak`

最稳妥的判断标准是：

- 这里的引用关系可以自然地变成“没有”

例如：

- 班级暂时还没分配老师
- 视图控制器可能已经被关闭
- 某个对象引用的拥有者可能先离开

这些场景共同的特征是：

- 这条关系本来就允许为空

如果符合这个特征，`weak` 通常就很自然。

## `unowned` 的最基础写法

另一个常见关键字是：

```swift
unowned let 属性名: 某个类类型
```

例如：

```swift
class ChapterNote {
    let content: String
    unowned let chapter: Chapter

    init(content: String, chapter: Chapter) {
        self.content = content
        self.chapter = chapter
    }
}
```

这里的核心含义是：

- `ChapterNote` 引用 `chapter`
- 但这种引用也不增加强引用计数

和 `weak` 的关键差别在于：

- `unowned` 通常不写成 Optional

这代表调用方在语义上做了一个更强的判断：

- 这里引用的对象在使用期间一定存在

## `weak` 和 `unowned` 的区别到底是什么

当前阶段最稳妥的区分方式，不是死背关键字，而是抓生命周期关系。

### `weak` 更像是在说：

- 我引用你
- 但你可能先离开
- 如果你离开了，我这里就接受变成 `nil`

### `unowned` 更像是在说：

- 我引用你
- 但在我活着的时候，你应该一直都在

所以当前阶段你可以先这样记：

- 允许变空，用 `weak`
- 不允许变空，但又不该强持有，用 `unowned`

如果还是拿前面的“所属关系”来建立直觉，可以先这样理解：

- `weak` 对应的是“对方可以先离开，我这里接受变成空”
- `unowned` 对应的是“对方不该先离开，所以我这里不写 Optional”

## 一个完整示例：课程和章节笔记

这个关系非常适合用来理解 `unowned`。

```swift
class Chapter {
    let title: String
    var notes: [ChapterNote] = []

    init(title: String) {
        self.title = title
    }

    deinit {
        print("Chapter \(title) 被释放")
    }
}

class ChapterNote {
    let content: String
    unowned let chapter: Chapter

    init(content: String, chapter: Chapter) {
        self.content = content
        self.chapter = chapter
    }

    deinit {
        print("Note \(content) 被释放")
    }
}
```

这里的关系更像是：

- `Chapter` 拥有一组笔记
- 笔记必须知道自己属于哪个章节
- 但笔记不应该反过来强持有章节

为什么这里 `unowned` 比 `weak` 更自然？

因为从建模语义看：

- 一条笔记不应该存在于“没有所属章节”的状态里

也就是说：

- `chapter` 对笔记来说应该始终存在

这类场景通常就更适合 `unowned`。

如果你继续追问“那它们到底会怎样释放”，可以看下面这个过程：

```swift
var chapter: Chapter? = Chapter(title: "ARC 进阶")

if let chapter {
    let note1 = ChapterNote(content: "先画清持有关系", chapter: chapter)
    let note2 = ChapterNote(content: "再决定 weak 还是 unowned", chapter: chapter)
    chapter.notes.append(note1)
    chapter.notes.append(note2)
}

chapter = nil
```

这里的释放顺序可以先这样理解：

1. `chapter = nil`
   外部变量不再强引用这个 `Chapter` 实例。
2. 如果这时已经没有别的强引用指向 `Chapter`，那么 `Chapter` 就会开始释放。
3. `Chapter` 在释放时，它内部强持有的 `notes` 数组也会一起结束。
4. `notes` 数组里那两个 `ChapterNote` 实例随之失去强引用，于是也会释放。

这里最重要的不是把顺序背成固定口诀，而是看清所有权关系：

- `Chapter` 强持有 `ChapterNote`
- `ChapterNote` 只是 `unowned` 引用 `Chapter`
- 所以释放时不会形成“你留住我，我留住你”的环

这也正是 `unowned` 在这种“所属对象必须存在，但又不该反向拥有”场景里最有价值的地方。

## 闭包为什么也会产生循环引用

这一点和上一章的“闭包会捕获外部变量”直接连起来。

先看一个最基础的例子：

```swift
class StudySession {
    let title: String
    var onFinish: (() -> Void)?

    init(title: String) {
        self.title = title
    }

    func setupCallback() {
        onFinish = {
            print("\(self.title) 已完成")
        }
    }

    deinit {
        print("StudySession \(title) 被释放")
    }
}
```

这里的问题在于：

- `StudySession` 强持有 `onFinish` 这个闭包
- 闭包内部又使用了 `self`
- 闭包因此会捕获并强持有 `self`

于是形成了：

- 对象强持有闭包
- 闭包强持有对象

这同样是一种强引用循环。

## 捕获列表是什么

Swift 用捕获列表来显式说明：

- 闭包在捕获某些外部引用时，应该采用什么方式

最常见的入门写法如下：

```swift
{ [weak self] in
    ...
}
```

例如，把前面的代码改成：

```swift
func setupCallback() {
    onFinish = { [weak self] in
        guard let self else {
            return
        }

        print("\(self.title) 已完成")
    }
}
```

这里可以先这样理解：

- 闭包仍然会引用 `self`
- 但这次不是强引用
- 而是弱引用

于是循环就被打破了。

## 为什么 `[weak self]` 后面经常要解包

因为：

- `weak self` 本质上意味着 `self` 可能已经不存在

也就是说，在闭包执行时：

- 原对象可能还活着
- 也可能已经释放

所以后面通常需要做一次处理，例如：

```swift
guard let self else {
    return
}
```

当前阶段你可以先把这套写法理解成：

- 如果对象还在，就继续执行
- 如果对象已经没了，就安静退出

## 什么时候闭包里适合用 `[weak self]`

这通常取决于两个问题：

1. 闭包是否会被当前对象强持有？
2. 闭包执行时，当前对象是否可能已经离开？

如果两个答案都是“是”，那么 `[weak self]` 往往很自然。

典型场景包括：

- 回调属性
- 异步完成回调
- 定时器或延迟执行逻辑

这些场景都有一个共同特征：

- 闭包的生命周期可能长于当前调用栈

## 什么时候不必机械地写 `[weak self]`

这同样很重要。

如果闭包只是：

- 立即执行
- 并没有被当前对象长期持有

那么机械地加 `[weak self]` 通常没有必要，还会让代码多一层解包噪音。

例如：

```swift
let text = { () -> String in
    return self.title
}()
```

这种写法是否需要特别处理，要看上下文是否真的形成“对象持有闭包，闭包再持有对象”的环。

所以更稳妥的原则不是：

- 看到闭包就写 `[weak self]`

而是：

- 先判断有没有长期持有和环

## 一个很实用的判断顺序

如果你遇到复杂引用关系，当前阶段可以按下面顺序判断：

1. 先画出谁强持有谁。
2. 看是否形成闭环。
3. 再判断这条环上的哪一段关系不该是强持有。
4. 最后根据“是否允许变空”决定用 `weak` 还是 `unowned`。

这个顺序比直接背：

- 某种关系固定用 `weak`
- 某种关系固定用 `unowned`

更可靠。

因为真正决定写法的不是名字，而是生命周期语义。

## `deinit` 在这一章的作用

前面的选读章节里你已经见过：

- `deinit`

本章它最重要的价值不是做复杂清理，而是帮助你观察：

- 对象到底有没有正常释放

如果你在示例里把：

```swift
teacher = nil
classroom = nil
```

都写了，但 `deinit` 迟迟不打印，那么通常就说明：

- 还有强引用链条没断掉

所以在学习 `weak` 和 `unowned` 时，`deinit` 是非常好用的观测点。

## 一个常见误区：把 `weak` 当成“更安全的默认值”

不是。

`weak` 不是“更保险所以到处都该用”。

如果一段关系从业务上本来就应该稳定存在，却被你写成 `weak`，反而可能导致：

- 到处都是 Optional 解包
- 真正的对象关系被写得模糊

所以 `weak` 的价值不在于“更安全”，而在于：

- 正确表达这条关系不拥有对方
- 并且允许对方先离开

## 常见误区

### 1. 以为 ARC 会自动打破所有循环引用

不是。

ARC 只根据引用计数工作，不会替你改写持有关系。

### 2. 以为 `weak` 更安全，所以总比 `unowned` 好

不是。

如果语义上对象就应该始终存在，那么 `unowned` 反而更清楚。

### 3. 以为闭包循环引用只会出现在异步代码里

不是。

只要对象强持有闭包，而闭包又强持有对象，就可能形成循环。

### 4. 以为闭包写 `[weak self]` 更安全

不是。

是否需要这样写，取决于引用关系和生命周期，而不是闭包这个语法本身。

## 本章练习与课后作业

如果你想把这一章的内容真正落实到一个“能跑但关系写错”的项目里，可以继续完成下面这道选读作业：

- 作业答案：`exercises/zh-CN/answers/28-arc-advanced-weak-unowned-and-capture-lists.md`
- 起始工程：`exercises/zh-CN/projects/28-arc-advanced-weak-unowned-and-capture-lists-starter`
- 参考答案工程：`exercises/zh-CN/answers/28-arc-advanced-weak-unowned-and-capture-lists`

这道题的重点不是继续增加功能，而是分析和修复下面这些典型问题：

- 对象之间互相强持有
- 所属关系该不该是强引用
- 闭包为什么把 `self` 留住

更稳妥的做法通常是：

1. 先画清谁强持有谁。
2. 再判断哪条关系不该继续参与强引用计数。
3. 最后再决定使用 `weak`、`unowned` 还是 `[weak self]`。

要求：

- 使用 `weak` 的形式，修复 `Teacher` 和 `Classroom` 之间不该继续强持有的关系。
- 使用 `unowned` 或 `weak` 中更合适的一种形式，重构 `ChapterNote` 对 `Chapter` 的所属关系，并说明为什么这样选。
- 使用 `[weak self]` 的捕获列表形式，修复回调闭包对 `self` 的强捕获问题。
- 保留当前 demo 的释放观察输出，不要把 `deinit` 和关键观察步骤删掉。
- 完成后，你至少应能解释三件事：谁先释放、为什么能释放、哪条引用没有再参与强引用计数。

## 本章小结

这一章最需要记住的是下面这组关系：

- 强引用循环的本质是对象之间互相强持有，导致强引用计数无法归零
- `weak` 不增加强引用计数，而且通常写成 Optional
- `unowned` 也不增加强引用计数，但表达的是“引用对象在使用期间应当始终存在”
- `weak` 适合允许变空的关系
- `unowned` 适合不允许变空但又不该拥有对方的关系
- 闭包会捕获外部变量，因此也可能形成循环引用
- `[weak self]` 是闭包中最常见的打环方式之一

如果你现在已经能比较稳定地看懂下面这类代码：

- `weak var teacher: Teacher?`
- `unowned let chapter: Chapter`
- `onFinish = { [weak self] in ... }`

并且开始习惯先画清谁持有谁，再决定关键字，那么这一章的核心目标就已经达到了。

## 接下来怎么读

如果继续沿这条主线往下走，下一步很自然会进入：

- [29. 并发入门：`async/await` 与 `Task`](./29-concurrency-basics-async-await-and-task.md)

因为当你已经理解了：

- 对象生命周期
- 闭包捕获
- 回调与引用关系

接下来一个很现实的问题就是：

- 当任务开始异步执行后，这些引用关系和状态变化会怎样继续影响代码组织
