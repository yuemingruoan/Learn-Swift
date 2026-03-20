# 20. 多态：用统一接口处理不同对象

## 阅读导航

- 前置章节：[19. 继承：is-a、has-a 与类型层次设计](./19-inheritance-is-a-has-a-modeling.md)
- 上一章：[19. 继承：is-a、has-a 与类型层次设计](./19-inheritance-is-a-has-a-modeling.md)
- 建议下一章：21. 协议：比继承更灵活的抽象方式（待补充）
- 下一章：21. 协议：比继承更灵活的抽象方式（待补充）
- 适合谁先读：已经理解父类、子类和 `override`，准备理解“统一调用，不同结果”这类行为差异的读者

## 本章目标

学完这一章后，你应该能够：

- 理解什么是多态，以及它在当前阶段最核心的意义
- 看懂为什么父类类型可以持有子类实例
- 看懂为什么同样的方法调用，在不同子类上会得到不同结果
- 理解多态如何减少大量类型判断分支
- 为后续学习协议多态打下直觉基础

## 本章对应目录

- 对应项目目录：`demos/projects/20-polymorphism-unified-interfaces`
- 练习与课后作业：无

建议你这样使用：

- 先看正文中“统一接口处理不同对象”的思路
- 再运行 `demos/projects/20-polymorphism-unified-interfaces`
- 重点观察同一个函数如何接收不同子类对象，并输出不同结果

## 先看多态在代码里的基础写法

多态听起来像概念词，但它在代码里的外形其实很固定。当前阶段最常见的就是下面这几种写法。

### 父类类型变量持有子类实例

```swift
let 变量名: 父类名 = 子类名(参数)
变量名.方法名()
```

例如：

```swift
let member: LearningMember = StudentMember(name: "小林", track: "iOS")
print(member.dailyFocus())
```

这里的重点是：

- 变量类型写的是父类
- 实际装进去的是子类实例
- 调用形式仍然是 `变量名.方法名()`

### 父类数组里放多个不同子类

```swift
let 数组名: [父类名] = [
    子类一(参数),
    子类二(参数),
    子类三(参数)
]
```

例如：

```swift
let members: [LearningMember] = [
    StudentMember(name: "小林", track: "iOS"),
    TeacherMember(name: "周老师", subject: "Swift"),
    MentorMember(name: "阿杰", groupName: "晚间答疑组")
]
```

### 统一遍历并调用同一个方法

```swift
for item in 数组名 {
    item.方法名()
}
```

例如：

```swift
for member in members {
    print(member.dailyFocus())
}
```

你可以先把多态最常见的调用形式记成：

- `父类类型变量 = 子类实例`
- `[父类类型]` 数组里装多个子类实例
- `统一调用同一个方法`

## 为什么继承之后还要继续学多态

如果你刚学完继承，很容易先停留在这样的理解上：

- 父类抽共性
- 子类加差异

这当然没错，但它只说清了“类型怎么长”。

而多态真正要解决的是另一个问题：

- 当你面对多个不同子类时，程序怎样用更统一的方式处理它们

如果没有多态，你很容易写出这样的代码：

```swift
if role == "student" {
    ...
} else if role == "teacher" {
    ...
} else if role == "mentor" {
    ...
}
```

或者：

- 到处根据类型名字做分支
- 新增一个类型，就得把很多地方都改一遍

多态的价值就在这里：

- 调用方式尽量统一
- 具体行为交给各个子类自己决定

## 什么是多态

当前阶段，可以先把多态理解成：

- 同样的接口调用，面对不同对象时，会表现出不同的具体行为

这里最重要的不是术语，而是这个运行效果。

例如，假设父类里有一个方法：

```swift
func dailyFocus() -> String
```

然后不同子类分别重写它：

- 学生返回“完成作业”
- 老师返回“准备授课”
- 助教返回“整理答疑记录”

这时如果你统一写：

```swift
print(member.dailyFocus())
```

那么虽然调用形式完全一样，但输出结果会随对象实际类型不同而不同。

这就是当前阶段最该抓住的多态直觉。

## 父类类型为什么可以装子类实例

先看这个例子：

```swift
let member: LearningMember = StudentMember(name: "小林", track: "iOS")
```

这句代码对很多初学者来说会有一点别扭，但它其实很合理。

因为前一章我们已经确认：

- `StudentMember is-a LearningMember`

既然学生本来就是一种学习中心成员，那么把它放到父类类型变量里，就是成立的。

你可以先这样理解：

- 这个变量对外只承诺“我会按学习中心成员的接口来使用它”
- 但它背后实际装着的对象，仍然是学生成员实例

所以后面如果调用一个被重写的方法，程序看到的仍然是：

- 这是个学生对象

## 多态最直观的场景：父类数组里放多个不同子类

这一类代码是理解多态最直接的入口：

```swift
let members: [LearningMember] = [
    StudentMember(name: "小林", track: "iOS"),
    TeacherMember(name: "周老师", subject: "Swift"),
    MentorMember(name: "阿杰", groupName: "晚间答疑组")
]
```

表面上看，这是一个：

- `LearningMember` 数组

但数组里实际放进去的是：

- 学生
- 老师
- 导师

这时如果你统一遍历：

```swift
for member in members {
    print(member.dailyFocus())
}
```

你就会看到：

- 每个对象都给出自己的结果
- 但调用方式完全一致

这正是多态最值得掌握的价值。

## 多态不是“魔法跳转”，而是子类自己提供实现

多态看起来像“同一句代码会自己变”，但它并不是神秘机制。

你可以先按下面这条线理解：

1. 父类先定义统一接口
2. 子类分别重写这个接口
3. 调用时虽然都通过父类视角发起
4. 但真正执行的是对象实际类型对应的那一版实现

所以多态不是凭空发生的，而是建立在两件事上：

- 继承层次已经成立
- 子类已经对同一接口给出了不同实现

## 一个完整示例：晨会中的统一汇报

本章 demo 对应目录：

- `demos/projects/20-polymorphism-unified-interfaces`

示例里会有一个父类：

```swift
class LearningMember {
    let name: String

    init(name: String) {
        self.name = name
    }

    func dailyFocus() -> String {
        return "完成今天的学习安排"
    }

    func printDailyBrief() {
        print("\(name)：\(dailyFocus())")
    }
}
```

然后几个子类分别重写 `dailyFocus()`：

```swift
class StudentMember: LearningMember {
    let track: String

    init(name: String, track: String) {
        self.track = track
        super.init(name: name)
    }

    override func dailyFocus() -> String {
        return "继续完成 \(track) 方向的练习"
    }
}

class TeacherMember: LearningMember {
    let subject: String

    init(name: String, subject: String) {
        self.subject = subject
        super.init(name: name)
    }

    override func dailyFocus() -> String {
        return "准备 \(subject) 的授课内容"
    }
}
```

这样一来，就可以写一个完全统一的晨会函数：

```swift
func runMorningBriefing(members: [LearningMember]) {
    for member in members {
        member.printDailyBrief()
    }
}
```

这里最值得观察的地方是：

- `runMorningBriefing` 根本不关心数组里具体是谁
- 它只要求这些对象至少能按 `LearningMember` 的接口被使用
- 真正的差异由各自子类自己负责

这就是多态把“判断类型”改成“统一调用”的过程。

## 多态到底减少了什么问题

多态最实际的价值，是减少下面这类代码：

- 围绕类型名字写一长串 `if-else`
- 新增一个子类，就要去很多地方补分支
- 外部调用方知道了太多内部细节

而用多态之后，外部调用方通常只需要知道：

- 我可以按父类接口来调用

至于每个对象到底怎么完成这件事，交给对象自己决定。

这会让代码更容易扩展。因为以后如果你新增一个子类，例如：

- `ReviewerMember`

那么很多已有调用方往往根本不用改，只要新子类自己把那套接口实现好即可。

## 多态和“内容不同”不是一回事

这里需要特别区分一个点。

多态说的不是：

- 对象里的数据不一样

而是：

- 面对同一个接口调用，不同对象会给出不同实现

例如，两个学生对象名字不同，这只是数据不同。

但如果：

- 学生、老师、导师都重写了 `dailyFocus()`

那这才是多态层面的差异。

## 多态和继承的关系

你可以先把两章关系记成：

- 继承解决“这些类型是什么关系”
- 多态解决“建立关系后，怎么统一使用这些对象”

所以多态不是替代继承，而是建立在继承之上的下一步理解。

当然，Swift 里后面还有一个很重要的话题：

- 协议也能提供非常强的多态能力

但在当前阶段，先把“继承层次上的多态”看稳最重要。

## 一个很实用的判断标准

如果你在写代码时发现自己总在做这件事：

- 先判断对象是哪一类
- 再决定调用哪套逻辑

那就可以停下来问自己：

- 这里是不是可以提一个共同父类接口
- 让不同子类自己重写

也就是说，多态最值得你养成的习惯是：

- 尽量让调用方写“我要什么接口”
- 尽量不要让调用方到处写“你到底是哪一种对象”

## 常见误区

### 1. 以为多态只是“父类变量能装子类”

这只是表面现象。

真正的重点是：

- 统一接口下的不同实现

### 2. 以为子类内容不同就自动算多态

不是。

重点仍然是：

- 同一个接口
- 不同实现

### 3. 写了继承，但外部还是到处判断子类类型

如果还是这样，多态的价值就没有真正发挥出来。

### 4. 过早把所有抽象都压到多态里

当前阶段只需要把最基础的动态行为差异看懂，不必一上来追求很复杂的抽象层次。

## 本章小结

这一章最需要记住的是下面这组关系：

- 多态强调的是统一调用方式下的不同行为表现
- 父类类型可以持有子类实例，因为子类本来就是父类的一种
- 真正执行哪一版方法，取决于对象实际类型
- 多态能减少大量围绕类型名称展开的分支判断
- 继承讲的是关系，多态讲的是统一使用这些关系

如果你现在已经能比较稳定地看懂下面这类代码：

- 一个父类数组里放多个不同子类
- 统一遍历并调用同名方法
- 输出结果却各不相同

那么这一章最重要的目标就已经完成了。
