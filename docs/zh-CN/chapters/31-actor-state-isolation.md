# 31. Actor：隔离共享可变状态

## 阅读导航

- 前置章节：[16. class 与引用语义：为什么改一个地方，另一个地方也会变](./16-class-and-reference-semantics.md)、[21. 协议：比继承更灵活的抽象方式](./21-protocols-flexible-abstraction.md)、[29. 并发入门：async/await 与 Task](./29-concurrency-basics-async-await-and-task.md)、[30. 并发中的共享状态：当多个任务同时改数据时会发生什么](./30-concurrency-shared-state.md)
- 上一章：[30. 并发中的共享状态：当多个任务同时改数据时会发生什么](./30-concurrency-shared-state.md)
- 建议下一章：[32. 结构化并发：async let、TaskGroup 与父子任务](./32-structured-concurrency.md)
- 下一章：[32. 结构化并发：async let、TaskGroup 与父子任务](./32-structured-concurrency.md)
- 适合谁先读：已经理解共享状态为什么危险，准备学习 Swift 如何给共享可变状态建立隔离边界的读者

## 本章目标

学完这一章后，你应该能够：

- 理解 `actor` 在 Swift 并发里的核心角色
- 看懂最基础的 `actor` 定义语法
- 理解 `actor` 也是引用类型，以及它和 `class` 的关键差别
- 看懂最基础的 actor 创建与调用方式
- 理解为什么跨 actor 边界访问成员时经常需要 `await`
- 理解 actor 在“多个任务同时来”时到底解决了什么问题
- 理解为什么 actor 方法中间一旦 `await`，前后状态就不能想当然地当成完全不变
- 建立“actor 负责保护状态边界，而不是替你写业务逻辑”的认识
- 区分什么时候更适合 `struct`、`class`，什么时候才值得引入 `actor`

## 本章对应目录

- 对应项目目录：`demos/projects/31-actor-state-isolation`
- 练习起始工程：`exercises/zh-CN/projects/31-actor-state-isolation-starter`
- 练习答案文稿：`exercises/zh-CN/answers/31-actor-state-isolation.md`
- 练习参考工程：`exercises/zh-CN/answers/31-actor-state-isolation`

建议你这样使用：

- 把本章当成“共享状态的组织方式”来读，不要把 `actor` 当成单纯的新关键字
- 阅读时优先关注：哪些状态被关进了 actor，哪些访问必须穿过隔离边界
- 如果你第一次看到 `await store.markFinished()` 这种写法觉得奇怪，重点去体会“跨边界调用”这件事

你可以这样配合使用：

- `demos/projects/31-actor-state-isolation`：先看 actor 的最小语法和隔离边界。
- `exercises/zh-CN/projects/31-actor-state-isolation-starter`：再把上一章的冲突代码改造成 actor 版本。
- `exercises/zh-CN/answers/31-actor-state-isolation.md`：做完后对照为什么“改成 actor”还不够，关键动作也要收拢。
- `exercises/zh-CN/answers/31-actor-state-isolation`：最后运行参考工程，观察结果为什么变稳定。

## 先看本章最常见的通用语法

这一章建议你先把下面几种写法记成“actor 的最小模板”，再去理解它为什么能隔离共享状态。

### 1. 定义一个 actor

```swift
actor StudyProgressStore {
    private var finishedCount = 0

    func markFinished() {
        finishedCount += 1
    }

    func currentCount() -> Int {
        return finishedCount
    }
}
```

### 2. 创建 actor 实例

```swift
let store = StudyProgressStore()
```

### 3. 在 `async` 作用域里调用 actor 成员

```swift
await store.markFinished()
let count = await store.currentCount()
```

### 4. 在同步位置先进入异步上下文，再调用 actor

```swift
Task {
    await store.markFinished()
    let count = await store.currentCount()
    print(count)
}
```

### 5. actor 内部继续调用自己的成员

```swift
actor StudyProgressStore {
    private var finishedCount = 0

    func markFinished() {
        finishedCount += 1
        logCount()
    }

    func logCount() {
        print(finishedCount)
    }
}
```

如果你先把这五种最小模板看顺，后面再谈隔离边界、同时访问和重入，理解会稳很多。

## 为什么共享状态之后适合学习 actor

上一章你已经看到：

- 并发真正难的地方，是共享可变状态
- 问题经常出在“多个任务同时碰同一份会变化的数据”
- 只要有读旧值再写新值、先检查再修改，就容易出现竞态

这时一个很自然的问题就会出现：

- 那我应该怎么组织这份共享状态

Swift 并发给出的一个很重要的答案就是：

- `actor`

但这里一定要先说清楚：

- `actor` 不是“让并发自动更快”的按钮
- 它首先是在帮你建立**状态隔离边界**

换句话说，前一章回答的是：

- 哪里危险

而这一章要回答的是：

- 危险的共享状态，应该被关在哪里

## 先说结论：actor 不是“会跑在后台的 class”

很多人第一次看到 `actor`，直觉会是：

- 这是不是一种自带线程的对象
- 这是不是“并发版 class”
- 只要改成 actor，所有问题都会自动消失

这些理解都不够稳。

当前阶段更合适的结论是：

- `actor` 是一种**把可变状态放进隔离边界里**的类型

它最重要的价值不是：

- 看起来更高级

而是：

- 让外部代码不能再像碰普通共享对象那样，随手同时改内部状态

所以学习 `actor` 时，注意力不要先放在“底层怎么调度”，而要先放在：

- 哪些成员在 actor 内部
- 外部代码怎样进入这个边界

## 先看 actor 最基础的语法

最基础的写法如下：

```swift
actor StudyProgressStore {
    private var finishedCount = 0

    func markFinished() {
        finishedCount += 1
    }

    func currentCount() -> Int {
        return finishedCount
    }
}
```

从外形上看，它和 `class` 有点像：

- 都可以有属性
- 都可以有方法

但当前阶段最值得先抓住的是：

- 这些可变状态现在被放进了 actor 的内部边界

外部如果想读写它，就不再是“拿到对象就直接乱改”的关系了。

## actor 也是引用类型，这一点要先说清楚

这一点非常重要，因为很多读者第一次看到 `actor` 时，注意力全在“并发”两个字上，反而容易忘掉：

- `actor` 也是引用类型

也就是说，下面这种代码里：

```swift
let store = StudyProgressStore()
let sameStore = store
```

`store` 和 `sameStore` 当前阶段可以先近似理解成：

- 它们都指向同一个 actor 实例

这和 `struct` 很不一样。

这里最值得你先建立的直觉是：

- actor 不是值复制容器
- 它更像“有身份、可被共享引用、但内部状态受隔离保护的对象”

这也是为什么它特别适合承载：

- 会被多个任务共同访问的共享状态负责人

## actor 和 class 最像的地方是什么

当前阶段先抓住最重要的一点就够了：

- 它们都有引用语义

也就是说：

- 你可以创建一个实例
- 把这个实例交给不同变量
- 也可以让不同任务都持有同一个实例引用

但 `actor` 和普通 `class` 的关键差别在于：

- `class` 的共享状态如果直接暴露出去，多个任务就可能同时乱改
- `actor` 则要求这些访问经过它自己的隔离边界

所以更稳妥的近似理解不是：

- actor 是“会跑在后台的 class”

而是：

- actor 是“带并发隔离边界的引用类型”

## 先把最小可运行调用路径走一遍

这一章最应该先讲清楚的，不是抽象定义，而是：

- actor 到底怎么创建
- actor 方法到底怎么调

先看一个最小可运行例子：

```swift
actor StudyProgressStore {
    private var finishedCount = 0

    func markFinished() {
        finishedCount += 1
    }

    func currentCount() -> Int {
        return finishedCount
    }
}

func runDemo() async {
    let store = StudyProgressStore()

    await store.markFinished()
    await store.markFinished()

    let count = await store.currentCount()
    print("当前完成数：\(count)")
}
```

如果你现在只先记这一段，至少要先记住下面三件事：

- actor 和 `class` 一样，也要先创建实例
- 从 actor 外部调用它的方法时，当前阶段通常要写 `await`
- actor 方法本体就算没写 `async`，跨边界调用时也仍然可能要 `await`

## 第一步：先像普通类型一样创建实例

这一点其实不复杂：

```swift
let store = StudyProgressStore()
```

也就是说，创建 actor 实例这件事本身，当前阶段可以先近似理解成和创建 `class` 实例差不多。

读到这里最不该卡住的，不是“怎么 new 一个 actor”，而是后面那一步：

- 创建完以后，到底该怎么调它的方法

## 第二步：在 `async` 作用域里调用 actor 方法

最基础的调用外形如下：

```swift
func runDemo() async {
    let store = StudyProgressStore()

    await store.markFinished()
    let count = await store.currentCount()

    print(count)
}
```

这里最关键的是：

- `runDemo()` 本身是 `async`
- 所以它有能力写 `await`
- 于是它可以跨 actor 边界调用 `store` 的方法

当前阶段你可以先把这件事记成一个非常实用的模板：

```swift
let actor实例 = Actor类型()
await actor实例.方法()
let 结果 = await actor实例.方法()
```

先把这个调用骨架记稳，比一开始追太多底层细节更重要。

## 第三步：从同步位置怎么调用 actor

这也是非常容易卡住的新手点。

如果你当前在一个同步位置，例如：

```swift
func startDemo() {
    let store = StudyProgressStore()
    // 这里不能直接写 await
}
```

显然这时候你意识到：

- 同步函数里不能直接写 `await`

这时最常见的入门做法通常是：

```swift
func startDemo() {
    let store = StudyProgressStore()

    Task {
        await store.markFinished()
        let count = await store.currentCount()
        print(count)
    }
}
```

也就是说，如果你人在同步位置，但又想调用 actor 的隔离成员，那么当前阶段最容易理解的入口通常是：

- 先进入一个异步上下文

而 `Task { ... }` 正是最常见的入口之一。

## 为什么方法体里没写 `async`，调用点却还是要 `await`

这是初学 actor 时最值得停下来体会的一点。

例如：

```swift
let store = StudyProgressStore()
await store.markFinished()
let count = await store.currentCount()
```

这里看起来容易让人困惑：

- `markFinished()` 里也没 `sleep`
- `currentCount()` 里也没网络请求
- 为什么还会出现 `await`

当前阶段最重要的理解不是“底层一定发生了什么等待”，而是：

- **你正在跨过 actor 的隔离边界访问它的状态**

也就是说，`await` 在这里最值得你先建立的直觉是：

- 这不是普通的同步直连调用
- 这是一次穿过并发隔离边界的访问

具体来讲，当前阶段你可以先这样理解：

- 当你访问一个 actor 的隔离成员时
- 这次访问要进入它自己的状态边界
- 如果这个边界当前正在处理别的访问，你这边就要等一下
- 这也是为什么调用点会写成 `await`

所以它和上一章里那种“共享对象任由外部同时改”已经不是同一种组织方式了。

这里最好再明确补一句：

- `markFinished()` 本身不是异步业务函数
- 但“从 actor 外部进入它的隔离边界”这件事，仍然会让调用点必须写 `await`

所以当前阶段不要把 `await` 只理解成：

- “这个函数体内部一定写了 `sleep` 或网络请求这类的操作”

你还应该开始接受另一层含义：

- “我现在正在跨并发隔离边界访问 actor”

## 如果两个任务同时调用同一个 actor，会发生什么

这正是很多读者最关心、也最重要的地方。

例如：

```swift
actor StudyProgressStore {
    private var finishedCount = 0

    func markFinished() {
        let oldValue = finishedCount
        let newValue = oldValue + 1
        finishedCount = newValue
    }

    func currentCount() -> Int {
        return finishedCount
    }
}

func runDemo() async {
    let store = StudyProgressStore()

    async let first: Void = store.markFinished()
    async let second: Void = store.markFinished()

    _ = await (first, second)

    let count = await store.currentCount()
    print("当前完成数：\(count)")
}
```

这里最值得观察的不是 `async let`，而是：

- 两个子任务都在调同一个 `store`
- 它们都想修改同一份 `finishedCount`

如果这是一个普通共享对象，而且你把状态直接暴露在外面，就很容易出现前一章那种“都读到旧值 0，最后只写回一次 1”的问题。

而 actor 当前阶段最值得先建立的直觉是：

- 对它隔离状态的访问，不会像普通共享对象那样让外部代码同时直接冲进去改
- 这些访问会被收束到同一个 actor 边界里处理

你可以先近似理解成：

- 第一个 `markFinished()` 先进入 actor 的隔离状态边界
- 它先完成这一小段内部修改
- 第二个 `markFinished()` 再进入 actor 继续处理

所以这里最想解决的，不是“让两个任务永远不要同时存在”，而是：

- **让两个任务不要同时直接改同一份 actor 内部状态**

## 这件事更准确地说，是“同一个 actor 的隔离状态访问会被串起来”

如果用更接近当前阶段的说法，可以先这样记：

- 同一个 actor 的隔离状态访问，不会让多个外部任务同时直接碰内部可变状态
- 这些访问会按进入边界的顺序，一段一段地处理

这里故意说成“一段一段”，是因为后面马上要补一个非常重要的边界：

- 这种串起来的效果，不等于“整个 actor 方法从头到尾绝对不会被打断”

这两个认识必须一起记，不然很容易学偏。

## actor 在这里到底解决了什么

这一点直接地说就是：

`actor`解决的不是：

- 世界上从此不再有并发
- 所有业务逻辑天然都不会冲突

更准确地说，`actor`是在解决下面这类问题：

- 原本多个任务都能直接摸到同一份可变状态
- 现在这份状态被收回 actor 内部
- 外部只能通过 actor 的隔离边界访问它

所以在“同时读写同一份内部状态”这个问题上，actor 提供的是：

- **访问收束**
- **边界隔离**
- **不让外部代码并发地直接乱改内部状态**

这就是为什么它能明显减少前一章那类共享状态冲突。

## 但 actor 不是“天然一切都不会冲突”

这里必须加以说明，不然容易把 actor 理解成魔法。

更准确的说法应该是：

- actor 让内部隔离状态的访问方式更安全
- 但它不会自动替你修好所有业务逻辑

例如下面这类情况，仍然值得警惕：

- 把“检查”和“修改”拆到了 actor 外部
- 在本来就把不该分开的业务动作拆成了多次跨边界调用
- 在 actor 方法里跨了等待点，却还假设前后的状态绝不会变化

所以千万不要把 actor 学成：

- “只要套一层 actor，业务冲突就从世界上消失了”

它没这么神。

## 一个非常重要的边界：actor 不等于“整段方法自动绝对独占到结束”

这是 actor 最容易被误解的地方之一。

例如你写出这样的代码：

```swift
actor WorkshopCenter {
    private var seatsLeft = 1

    func register(name: String) async -> Bool {
        if seatsLeft <= 0 {
            return false
        }

        await logRequest(name)
        seatsLeft -= 1
        return true
    }

    func logRequest(_ name: String) async {
        print("记录报名请求：\(name)")
    }
}
```

很多初学者会天然以为：

- 既然我已经进了 actor，那 `register(name:)` 整段都会像上锁一样绝对独占到最后

当前阶段更稳妥的理解是：

- actor 能保护它的隔离状态边界
- 但如果方法中间自己 `await` 了，这段流程就会先挂起
- 挂起期间，actor 可能去处理别的访问

这意味着什么？

意味着你不能轻易想当然地以为：

- 前面检查过 `seatsLeft > 0`
- 那后面恢复执行时，这个条件就一定还保持原样

所以这里最需要先建立的边界是：

- actor 很重要
- 但它不是“整段业务逻辑自动永远不被打断”的魔法锁

## 这在并发里通常叫“重入”

如果你后面继续学更深入的并发资料，经常会遇到一个词：

- `reentrancy`

当前阶段你不需要背定义，但可以先建立一个够用的近似理解：

- actor 方法执行到 `await` 时，会先挂起
- 挂起期间，同一个 actor 可能继续处理别的访问
- 等原来的方法恢复时，内部状态可能已经和挂起前不一样了

所以“重入”当前阶段最值得抓住的，不是术语本身，而是这个后果：

- **不要把 `await` 前后，当成同一份状态必然原封不动的连续世界**

## 用一条时间线看一遍，为什么 `await` 前后可能变了

继续看刚才那个报名例子。你可以近似把它想成下面这样：

1. 任务 A 进入 `register(name:)`
2. A 看到 `seatsLeft == 1`
3. A 执行到 `await logRequest(name)`，先挂起
4. actor 在这段时间去处理任务 B 的访问
5. B 也进入 `register(name:)`，并把 `seatsLeft` 改掉
6. A 恢复执行时，看到的世界已经不是它挂起前那一刻了

所以这个问题的重点不是：

- actor 没有发挥作用

而是：

- 你把一个本该紧密连在一起的业务动作，中间插入了等待点

actor 保护了边界，但你自己的业务组织仍然要讲道理。

## 真正更稳妥的做法是什么

更稳妥的思路通常是：

- 尽量把彼此强相关的检查和修改，放在同一个不跨等待点的 actor 内部动作里完成

例如：

```swift
actor WorkshopCenter {
    private var seatsLeft = 1

    func register(name: String) -> Bool {
        if seatsLeft <= 0 {
            return false
        }

        seatsLeft -= 1
        return true
    }
}
```

这里最关键的不是“代码变短了”，而是：

- 名额检查和名额扣减没有被拆到 actor 外面
- 也没有在两者之间插入新的等待点

这会比“先查、再 await、再改”稳得多。

## actor 内部调用自己的成员时，为什么又不用 `await`

这一点也要补上，不然读者很容易形成另一种误解：

- 只要看到 actor，所有方法调用都必须写 `await`

不是。

例如：

```swift
actor StudyProgressStore {
    private var finishedCount = 0

    func markFinished() {
        finishedCount += 1
        logCurrentCount()
    }

    func logCurrentCount() {
        print("当前完成数：\(finishedCount)")
    }
}
```

这里 `markFinished()` 在 actor 内部调用 `logCurrentCount()`，当前阶段就可以先这样理解：

- 它们都还在同一个 actor 边界里面
- 这里不是“从外部跨边界进入”

所以最值得先抓住的区别是：

- actor 外部调用隔离成员：通常要 `await`
- actor 内部继续调用自己的隔离成员：当前阶段通常不需要额外 `await`

## 一个最小调用模板：当前阶段先把这 4 种写法记住

如果你第一次学 actor，不妨先只记下面这 4 种最常见写法。

### 1. 定义 actor

```swift
actor StudyProgressStore {
    private var finishedCount = 0

    func markFinished() {
        finishedCount += 1
    }

    func currentCount() -> Int {
        return finishedCount
    }
}
```

### 2. 创建实例

```swift
let store = StudyProgressStore()
```

### 3. 在 async 作用域里调用

```swift
await store.markFinished()
let count = await store.currentCount()
```

### 4. 在同步作用域里先进入异步上下文

```swift
Task {
    await store.markFinished()
    let count = await store.currentCount()
    print(count)
}
```

如果这四种写法你已经看顺了，后面再谈“为什么要这样设计”，就会顺很多。

## 从这一章你真正该建立的 actor 直觉是什么

到这里最好收一下，不然很容易又掉回“零散记语法”的状态。

当前阶段最值得建立的 actor 直觉，其实就是下面这四句：

- actor 是引用类型，不是值复制容器
- actor 的核心价值是隔离共享可变状态
- 多个任务同时来时，actor 会把对隔离状态的访问收束到同一个边界里处理
- 但 actor 不是魔法锁；一旦方法中间 `await`，你就要重新警惕前后状态变化

如果这四句你已经真正吃透，后面的很多并发判断都会稳很多。

## 什么叫隔离边界

当前阶段可以先把“隔离边界”近似理解成：

- actor 内部的状态，不允许外部代码直接随手并发改动

外部代码能做的，不是：

- 直接改 `finishedCount`

而是：

- 通过 actor 暴露出来的方法，请它自己处理内部状态

这件事非常关键，因为它会迫使你重新整理职责：

- 哪些数据应该只留在内部
- 哪些操作应该由拥有这份状态的对象自己完成

这其实和前面学过的封装是一条主线，只是这里放到了并发语境里。

## actor 最适合承载什么

最适合放进 actor 的，通常是下面这类东西：

- 会被多个任务共同访问的可变计数器
- 共享缓存
- 会不断追加和修改的日志中心
- 某个全局或模块级的进度仓库
- 某类“必须统一串起来处理”的业务状态

例如：

```swift
actor DashboardCache {
    private var values: [String: String] = [:]

    func value(for key: String) -> String? {
        return values[key]
    }

    func save(_ value: String, for key: String) {
        values[key] = value
    }
}
```

这个例子最值得观察的不是字典本身，而是：

- 缓存字典没有再裸露给外部
- 外部只能通过 actor 的接口读写

这正是在用边界保护共享状态。

## actor 内部方法和外部访问的分工

当你把一份状态放进 actor 后，最自然的重构思路通常是：

1. 把可变状态收进 actor 内部
2. 把依赖这份状态的读写逻辑也尽量收进 actor 方法
3. 让外部只表达“我要做什么”，而不是自己拆开所有读写步骤

这很像前一章的反面教材修复。

例如，错误写法的危险之处常常是：

- 外部先读旧值
- 外部自己算新值
- 外部再写回去

而更稳妥的 actor 思路通常是：

- 让 actor 自己完成这整个动作

例如：

```swift
actor WorkshopCenter {
    private var seatsLeft = 1

    func register(name: String) -> Bool {
        if seatsLeft <= 0 {
            return false
        }

        seatsLeft -= 1
        return true
    }
}
```

这里最值得你体会的是：

- 名额检查和名额扣减不再由外部拆开做
- 它们被放回了拥有这份状态的边界内部

这会让业务约束更容易保持完整。

但这里也要立刻补一句边界：

- actor 让这段逻辑回到了状态拥有者一侧
- 不代表你就可以在这段逻辑中随手插入新的 `await`，然后仍然假设前后状态完全不变

所以真正该学会的是：

- 不只是“把状态放进 actor”
- 还包括“把强相关的状态变更组织成合理的 actor 内部动作”

## actor 和 class 的差别，当前阶段先抓哪几点

如果你已经学过 `class`，那这一章很容易陷入“全面对比所有细节”。当前阶段没必要一下比太满，先抓住下面几条最实用的差别就够了。

### 1. `class` 更像普通引用类型容器

你拿到一个 `class` 实例后，如果成员可见，就可能直接读写它的状态。

这在单线程里未必有问题，但在并发里就容易把共享状态暴露得太开。

### 2. `actor` 更强调状态隔离

你不是直接冲进去改内部状态，而是要通过它提供的边界访问。

### 3. `actor` 不是用来替代所有 `class`

有些类型只是：

- 普通数据对象
- 局部生命周期对象
- 根本不被多任务共享

那就未必值得引入 actor。

所以当前阶段不要把“学会 actor”理解成：

- 以后所有引用类型都该改成 actor

## 什么时候更适合 `struct`、`class`，什么时候才值得引入 actor

这是一个特别实用的判断题。

### 更适合 `struct` 的情况

- 主要承载数据
- 值语义更自然
- 不需要被多个任务共享为同一实例

### 更适合 `class` 的情况

- 需要引用语义
- 生命周期、身份语义比值复制更重要
- 但并发共享并不是这个类型的核心场景

### 更适合 `actor` 的情况

- 这份状态会被多个任务共同访问
- 你明确担心共享可变状态边界
- 你希望把读写动作收回到拥有状态的一侧

所以 actor 最适合的，不是“所有对象”，而是：

- **共享状态的负责人**

## actor 不能替你解决什么

显然`actor`也不是万能的

它不能替你自动解决下面这些问题：

- 业务规则本身设计错误
- 状态切分本身就不合理
- 你把本来无关的职责全塞进一个大 actor
- 不该共享的状态仍然到处共享

也就是说，actor 不是在替你“消灭设计问题”，它只是在给你一个更稳的并发边界工具。

如果你的建模本身混乱，那么就算上了 actor，也只是把混乱放进了另一个盒子里。

## 一个很实用的判断顺序

当你拿不准某个类型该不该用 actor 时，可以先问下面三个问题：

1. 这份状态会不会被多个任务共同访问
2. 其中是否存在真正的可变共享状态
3. 这些读写动作是否应该由拥有这份状态的一侧统一负责

如果这三个问题都越来越偏向“是”，那么 actor 往往就很合适。

如果答案更多是：

- 只是普通数据
- 没有共享修改
- 只是局部临时值

那就不必为了“用了并发新语法”而硬上 actor。

## 常见误区

### 1. 以为 actor 就是“并发版 class”

不够准确。

它首先是在表达状态隔离边界。

### 2. 以为用了 actor 之后，外部就可以随意拆着访问内部状态

不是。

更稳妥的思路通常是把相关读写动作收进 actor 方法里。

### 3. 以为 `await` 只会出现在网络请求或 `sleep` 前面

不是。

跨 actor 边界访问成员时，也经常会看到 `await`。

### 4. 以为只要改成 actor，就天然不会再有任何业务冲突

不是。

actor 保护的是隔离状态访问边界，不是自动替你保证所有跨步骤业务逻辑都永远正确。

### 5. 以为进入 actor 方法后，这整段代码都会绝对独占到最后

不是。

如果方法中间发生 `await`，你就要重新警惕挂起前后的状态变化。

### 6. 以为 actor 和 struct 一样，是“复制一份再改”

不是。

actor 也是引用类型，多个变量或多个任务可以指向同一个 actor 实例。

## 本章小结

这一章最需要记住的是下面这组关系：

- `actor` 的核心角色是给共享可变状态建立隔离边界
- `actor` 也是引用类型，它适合承载会被多个任务共同访问的共享状态负责人
- 学习 actor 时，注意力应先放在“谁拥有状态、谁负责修改”，而不是先放在底层调度
- 跨 actor 边界访问成员时，经常会出现 `await`
- 同一个 actor 的隔离状态访问，会被收束到同一个边界里处理
- actor 能减少“多个任务同时直接改同一份内部状态”的问题
- actor 不是魔法锁；如果你把业务动作拆碎，或者在关键步骤中间 `await`，仍然要重新检查边界
- actor 更像共享状态的负责人，而不是所有类型的默认替代品

如果你现在已经能看懂下面这类代码：

- `actor StudyProgressStore { ... }`
- `await store.markFinished()`

并且知道为什么要把读写动作收回到状态拥有者一侧，那么这一章最重要的目标就已经达到了。

## 接下来怎么读

下一章建议继续阅读：

- [32. 结构化并发：async let、TaskGroup 与父子任务](./32-structured-concurrency.md)

因为当你已经理解：

- 共享状态应该如何隔离
- actor 在并发边界里负责什么

接下来一个很自然的问题就是：

- 当我需要同时启动多段异步工作时，怎样把它们组织成更清楚、更可控的任务结构
