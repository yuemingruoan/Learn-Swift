# 19. 继承：is-a、has-a 与类型层次设计

## 阅读导航

- 前置章节：[16. class 与引用语义：为什么改一个地方，另一个地方也会变](./16-class-and-reference-semantics.md)、[18. 面向对象入门：封装、职责与对象协作](./18-oop-basics-object-collaboration.md)
- 上一章：[18. 面向对象入门：封装、职责与对象协作](./18-oop-basics-object-collaboration.md)
- 建议下一章：[20. 多态：用统一接口处理不同对象](./20-polymorphism-unified-interfaces.md)
- 下一章：[20. 多态：用统一接口处理不同对象](./20-polymorphism-unified-interfaces.md)
- 适合谁先读：已经理解对象协作，准备学习何时抽共同父类、何时不该继承的读者

## 本章目标

学完这一章后，你应该能够：

- 理解继承在当前阶段到底解决什么问题
- 看懂父类、子类、`override` 和 `super` 的最基础写法
- 理解继承表达的核心是 `is-a` 关系
- 区分 `is-a`、`has-a`、`uses-a` 三种常见建模关系
- 知道什么时候适合继承，什么时候更适合组合

## 本章对应目录

- 对应项目目录：`demos/projects/19-inheritance-is-a-has-a`
- 练习与课后作业：无

## 先看继承最基础的语法外形

在讨论 `is-a` 之前，先把继承最常见的代码形状看清楚。

### 父类与子类的基础写法

最通用的写法如下：

```swift
class 父类名 {
    属性定义

    init(参数列表) {
        初始化逻辑
    }

    func 方法名() {
        父类方法逻辑
    }
}

class 子类名: 父类名 {
    子类自己的属性

    init(参数列表) {
        子类初始化逻辑
        super.init(父类参数)
    }

    override func 方法名() {
        子类重写逻辑
    }
}
```

例如：

```swift
class LearningMember {
    var name: String

    init(name: String) {
        self.name = name
    }

    func roleDescription() -> String {
        return "学习中心成员"
    }
}

class StudentMember: LearningMember {
    var track: String

    init(name: String, track: String) {
        self.track = track
        super.init(name: name)
    }

    override func roleDescription() -> String {
        return "学生，学习方向是 \(track)"
    }
}
```

这里最值得先记住的是：

- `class 子类名: 父类名`：表示子类继承父类
- `super.init(...)`：调用父类初始化器
- `override`：表示这里在重写父类已有方法

### 通用的创建与调用形式

这一章最常见的几种使用方式如下：

```swift
let 子类实例 = 子类名(参数)
子类实例.继承来的属性
子类实例.子类自己的属性
子类实例.方法名()

let 父类视角变量: 父类名 = 子类名(参数)
父类视角变量.方法名()
```

例如：

```swift
let student = StudentMember(name: "小林", track: "iOS")
print(student.name)
print(student.track)
print(student.roleDescription())

let member: LearningMember = StudentMember(name: "小周", track: "SwiftUI")
print(member.roleDescription())
```

你可以先把它们记成：

- `子类名(...)`：创建子类实例
- `实例.继承来的成员`：照常访问
- `实例.子类自己的成员`：照常访问
- `父类类型 = 子类实例`：这是后面多态会继续用到的基础写法

## 先说结论：继承首先是建模，不是省代码

很多读者第一次学继承时，最先记住的往往是：

- 可以复用父类代码

这句话不能算错，但如果只记住这一句，后面很容易写偏。

因为程序里“长得有点像”的东西太多了。如果你只按“能不能少写一点代码”来决定是否继承，很容易出现这些问题：

- 为了复用而硬继承
- 父类越写越大，职责越来越混乱
- 子类名字虽然能写出来，但语义越来越别扭

所以这一章最重要的起点是：

- 继承首先服务于建模
- 代码复用只是它带来的一个结果

下面这一章会按以下顺序展开：

1. 继承到底在表达什么关系
2. 区分 `is-a`、`has-a`、`uses-a`
3. 继承的基础语法
4. 在完整 demo 中理解继承

## 继承到底在表达什么关系

### 什么是继承

当前阶段，可以先把继承理解成：

- 在一个已有类型的基础上，定义一个更具体的类型

最基础的写法如下：

```swift
class LearningMember {
    var name: String

    init(name: String) {
        self.name = name
    }

    func roleDescription() -> String {
        return "学习中心成员"
    }
}

class StudentMember: LearningMember {
    var track: String

    init(name: String, track: String) {
        self.track = track
        super.init(name: name)
    }
}
```

这里可以先这样理解：

- `LearningMember` 是父类
- `StudentMember` 是子类
- 子类拥有父类已经定义好的成员
- 子类还可以增加自己的新成员

### 父类和子类的核心关系是什么

继承最重要的不是语法，而是语义关系。

当你写：

```swift
class StudentMember: LearningMember
```

你真正想表达的是：

- 学生是一种学习中心的成员

这一层关系，就是继承最核心的判断标准：

- `is-a`

也就是说，继承表达的是：

- 子类本来就是父类的一种

如果这句话本身说不通，那么语法就算写得出来，建模也很可能是错的。

## 区分 `is-a`、`has-a`、`uses-a`

这一节是本章真正的判断核心。很多“继承到底该不该用”的问题，最后都能落回这三种关系。

### 什么是 `is-a`

你可以把 `is-a` 理解成一种非常直接的判断句：

- X 是一种 Y

例如：

- `StudentMember is-a LearningMember`
- `TeacherMember is-a LearningMember`
- `AssistantTeacher is-a TeacherMember`

这些句子读起来都比较自然，所以继承关系通常也是成立的。

但如果你尝试说：

- `Projector is-a StudyCenter`
- `Course is-a Student`
- `Library is-a Book`

你会立刻感觉很别扭。

这通常就是一个强信号：

- 这里不该继承

### 什么是 `has-a`

`has-a` 可以先理解成：

- 一个对象拥有另一个对象，或者内部包含另一个对象

例如：

- `StudyCenter has-a Projector`
- `Student has-a StudyPlan`
- `Course has-a Teacher`

这里的重点不是“它们有关联”，而是：

- 一个对象把另一个对象当作自己的组成部分

这种关系通常更适合：

- 组合

而不是继承。

例如：

```swift
class Projector {
    let model: String

    init(model: String) {
        self.model = model
    }
}

class StudyCenter {
    let name: String
    let projector: Projector

    init(name: String, projector: Projector) {
        self.name = name
        self.projector = projector
    }
}
```

这里表达的就是：

- 学习中心里有一个投影仪

而不是：

- 学习中心是一种投影仪

### 什么是 `uses-a`

`uses-a` 则更像：

- 一个对象在某个动作里临时使用另一个对象的能力

例如：

- `Teacher uses-a Projector`

这句话的重点不是“老师拥有投影仪”，而是：

- 老师在授课时会使用投影仪

例如：

```swift
class TeacherMember: LearningMember {
    func use(projector: Projector) {
        print("\(name) 正在使用 \(projector.model)")
    }
}
```

这里表示的是一种使用关系，而不是继承关系，也不一定是拥有关系。

### 先把三种关系压缩成一句话

当前阶段你可以先这样记：

- `is-a`：是一种什么
- `has-a`：拥有或包含什么
- `uses-a`：在动作里会使用什么

## 什么时候适合继承

如果你还不确定要不要继承，可以先按下面这几条判断。

#### 1. 能不能自然说出“X 是一种 Y”

如果这句话说出来很自然，继承通常更有可能成立。

例如：

- 学生是一种成员
- 老师是一种成员

#### 2. 父类的共性，是否所有子类都共有

如果你抽到父类里的内容，只有一部分子类用得到，那就说明这个父类可能抽得不对。

#### 3. 子类是不是在“更具体地表达父类”

继承更适合从一般到具体。

例如：

- `LearningMember`
- `StudentMember`
- `TeacherMember`

这个方向就比较自然。

## 什么时候不该继承

#### 1. 只是因为两个类型“都有某个方法”

例如：

- 都有 `printSummary()`

这并不自动说明它们该继承。

#### 2. 只是因为想少写几行代码

如果继承唯一的理由是“这样可以少复制几个属性”，很可能你是在拿继承硬凑复用。

#### 3. 明明更像拥有关系，却强行写成继承

例如：

- `StudyCenter: Projector`

这类写法虽然语法上也许能成立，但建模语义是错的。

## 继承的基础语法

当前阶段只需要先掌握三件事：

- 子类如何继承父类
- 子类如何重写父类方法
- 子类怎样用 `super` 调父类逻辑

### 什么是 `override` 

如果子类想要保留父类已有接口，但实现得更具体，就会用到 `override`。

例如：

```swift
class LearningMember {
    var name: String

    init(name: String) {
        self.name = name
    }

    func roleDescription() -> String {
        return "学习中心成员"
    }
}

class TeacherMember: LearningMember {
    var subject: String

    init(name: String, subject: String) {
        self.subject = subject
        super.init(name: name)
    }

    override func roleDescription() -> String {
        return "授课教师，负责 \(subject)"
    }
}
```

这里的重点是：

- 父类先定义一个通用接口
- 子类保留这个接口名字
- 但给出更适合自己的实现

### `super` 的作用

`super` 当前阶段最常见的两个用途是：

- 在初始化器里调用父类初始化逻辑
- 在重写方法时，先保留父类原来的部分行为

例如：

```swift
override func introduce() {
    super.introduce()
    print("我当前负责的科目是 \(subject)")
}
```

你可以先把它理解成：

- 先执行父类那一版
- 再补上子类自己的部分

## 把判断标准放进完整示例

本章 demo 对应目录：

- `demos/projects/19-inheritance-is-a-has-a`

这个示例会同时展示三种关系：

- `StudentMember is-a LearningMember`
- `StudyCenter has-a Projector`
- `TeacherMember uses-a Projector`

### 第一部分：先看真正适合继承的关系

先看父类：

```swift
class LearningMember {
    let name: String

    init(name: String) {
        self.name = name
    }

    func roleDescription() -> String {
        return "学习中心成员"
    }

    func introduce() {
        print("你好，我是 \(name)，我的身份是：\(roleDescription())")
    }
}
```

再看两个子类：

```swift
class StudentMember: LearningMember {
    let track: String

    init(name: String, track: String) {
        self.track = track
        super.init(name: name)
    }

    override func roleDescription() -> String {
        return "学生，学习方向是 \(track)"
    }
}

class TeacherMember: LearningMember {
    let subject: String

    init(name: String, subject: String) {
        self.subject = subject
        super.init(name: name)
    }

    override func roleDescription() -> String {
        return "老师，授课方向是 \(subject)"
    }
}
```

这里最关键的判断不是“代码像不像”，而是：

- 学生本来就是成员的一种
- 老师本来也是成员的一种

所以这里的继承关系在语义上是成立的。

### 第二部分：再看更适合组合的关系

```swift
class Projector {
    let model: String

    init(model: String) {
        self.model = model
    }
}

class StudyCenter {
    let name: String
    let projector: Projector

    init(name: String, projector: Projector) {
        self.name = name
        self.projector = projector
    }
}
```

这里显然表达的是：

- 学习中心有一个投影仪

不是继承。

### 第三部分：最后看使用关系

```swift
func use(projector: Projector) {
    print("\(name) 正在使用 \(projector.model)")
}
```

这又不是拥有关系，而是：

- 老师在执行某个动作时会使用它

这样一来，三种关系就被清楚地区分开了。

## 需要牢记的判断顺序

如果你以后拿不准某两个类型到底该怎样建模，优先按这个顺序判断：

1. 先问：它们是不是 `is-a`
2. 如果不是，再问：是不是 `has-a`
3. 如果也不是，再问：是不是 `uses-a`

这个顺序的好处在于：

- 先从语义最强的继承关系开始判断
- 避免把一切关联都误写成父类子类

## 常见误区

### 1. 以为“看起来相似”就该继承

相似只能说明它们可能有共同点，不能直接说明它们是父子类型。

### 2. 以为继承只是复用工具

复用当然有帮助，但如果建模关系错了，复用越多，后面越难改。

### 3. 把 `has-a` 硬写成 `is-a`

这是最常见、也最该尽早避免的错误。

### 4. 父类装太多不必要的东西

如果父类里堆了很多只有个别子类才需要的成员，通常说明抽象层次不对。

## 本章练习与课后作业

如果你想把这一章的“继承首先服务于建模”真正练一遍，建议直接从下面这个起始工程开始：

- 起始工程：`exercises/zh-CN/projects/19-inheritance-is-a-has-a-starter`
- 练习草稿：`exercises/zh-CN/answers/19-inheritance-is-a-has-a-modeling.md`

这个工程当前已经能运行，但关系还没有整理好。你会看到：

- `StudentMember` 和 `TeacherMember` 之间有明显重复
- 共同的“成员”概念还没有被抽出来
- `Projector`、`StudyCenter`、`TeacherMember` 之间的关系需要重新判断

这一章建议你完成下面这些重构：

1. 提取 `LearningMember`，把 `name` 和通用介绍逻辑收进去。
2. 让 `StudentMember` 和 `TeacherMember` 继承 `LearningMember`。
3. 保持 `StudyCenter has-a Projector` 这种组合关系。
4. 保持 `TeacherMember uses-a Projector` 这种使用关系。

完成后，你的代码至少应该表现出下面这些特征：

- `StudentMember is-a LearningMember`
- `TeacherMember is-a LearningMember`
- `StudyCenter` 不是 `Projector` 的子类
- `TeacherMember` 通过方法使用 `Projector`，而不是把它当成父类

这道练习最值得你反复问自己的不是“能不能少写几行”，而是：

- 这句“X 是一种 Y”到底说不说得通
- 这里更像 `is-a`、`has-a`，还是 `uses-a`

## 本章小结

这一章最需要记住的是下面这组关系：

- 继承表达的是 `is-a`
- 组合更常用于 `has-a`
- 临时调用能力更常用于 `uses-a`
- `override` 让子类在保留接口的同时给出更具体的实现
- `super` 让子类在需要时复用父类已有逻辑

如果你现在已经开始在写继承前先问自己：

- 这句“X 是一种 Y”到底说不说得通

那么这一章最重要的目标就已经达到了。

## 接下来怎么读

下一章建议继续阅读：

- [20. 多态：用统一接口处理不同对象](./20-polymorphism-unified-interfaces.md)

因为当父类和子类关系建立起来后，接下来最自然的问题就是：

- 为什么同样的方法调用，换成不同子类会有不同结果
- 为什么一个父类类型的数组里，可以放多个不同子类
- 多态到底帮我们减少了什么样的分支判断

下一章会专门把这个问题讲清楚。
