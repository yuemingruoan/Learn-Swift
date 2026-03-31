# 44. 从快照到记录：SwiftData 最小持久化闭环

## 阅读导航

- 前置章节：[13. 结构体与最基础的自定义类型](./13-structs-and-custom-types.md)、[43. 本地快照缓存：Codable、文件落盘与恢复路径](./43-codable-persistence-and-local-cache.md)
- 上一章：[43. 本地快照缓存：Codable、文件落盘与恢复路径](./43-codable-persistence-and-local-cache.md)
- 建议下一章：[45. 结构化读取与关系一致性：筛选、排序、列表与删除规则](./45-swiftdata-advanced-query-sort-relationships-and-boundaries.md)
- 下一章：[45. 结构化读取与关系一致性：筛选、排序、列表与删除规则](./45-swiftdata-advanced-query-sort-relationships-and-boundaries.md)
- 适合谁先读：已经理解第 43 章“快照缓存”能做什么，并开始遇到“本地数据要按记录长期维护”的读者

## 本章目标

学完这一章后，你应该能够：

- 说清为什么第 43 章的文件快照不适合继续承载“本地待办管理”
- 用 `SwiftData` 跑通一条最小闭环：建模、创建容器、读取、插入、修改、删除、重启后读回
- 理解 `@Model`、`ModelContainer`、`ModelContext` 各自在实际开发中解决什么问题
- 区分“SwiftData 核心概念”和“项目里为了组织代码而加的一层 store”
- 理解这套最小 CRUD 闭环的边界：它解决了“能保存”，但还没覆盖“怎么读更合理”

## 这一章在解决什么开发问题

第 43 章里，本地数据只是“远程返回的一份待办快照”。

而这一章把需求升级了一步：

- 用户会在本地新增待办
- 用户会切换待办完成状态
- 用户会删除某一条待办
- 这些修改在应用重启后仍然要保留

一旦需求变成这样，你管理的就不再是一份 JSON 文件，而是一条条本地记录。

这会带来三个直接变化：

- 你需要围绕“单条记录”做增删改，而不是每次整份读写
- 你开始需要一个长期稳定的本地数据入口，而不是一次性文件操作
- 你希望持久化系统帮你维护对象生命周期，而不是自己拼接文件读写流程

这正是 SwiftData 适合进入的位置。

## 先把定位说清楚：SwiftData 不是“更高级的文件写入”

你可以先用一句话理解这一章：

- `SwiftData` 让本地数据更像“可长期维护的记录集合”，而不是“需要你手工读写的一份文件”

从开发角度看，它主要在帮你做三件事：

- 定义哪些对象值得被长期保存
- 提供一个统一的本地数据系统入口
- 让你围绕对象做读写与保存

本章不会展开 UI、属性包装器或数据库理论。重点只放在：

- 作为开发者，你如何把“待办项”变成本地可维护记录
- 最小闭环是怎么跑通的
- 出问题时你该先怀疑哪一层

## 统一场景：待办项已经变成“用户本地维护的数据”

这章开始，待办项不再是远程结果快照，而是用户本地维护的数据本体。

场景具体化以后，需求就很明确了：

1. 应用启动后要能打开本地数据系统
2. 用户新增一条待办时，数据要被记录下来
3. 用户修改状态时，不需要重写整份文件
4. 用户删除一条待办后，本地记录要同步消失
5. 应用重启后，之前的记录还能读回来

这个需求就是本章配套 demo 会完整演示的东西。

## 本章怎么读

建议按这个顺序读：

1. 先看完整闭环在做什么，而不是先背术语
2. 再看 `@Model`、`ModelContainer`、`ModelContext` 分别在这个闭环里扮演什么角色
3. 然后看最小 CRUD 是如何围绕 `ModelContext` 完成的
4. 最后再看为什么真实项目里常常会加一层 `TodoStore`

如果你读完能独立写出这几个动作，本章就达标：

- 创建本地持久化容器
- 新增一条待办
- 读取全部待办
- 切换某一条待办状态
- 删除某一条待办
- 重建容器后再次读取并确认数据仍然存在

## 先看完整闭环：这章到底要跑通什么

本章 demo 的核心流程只有两轮：

### 第 1 轮：在同一个容器里做最小 CRUD

- 创建容器
- 插入两条待办
- 读出全部待办
- 修改其中一条完成状态
- 删除其中一条
- 再次读取确认结果

### 第 2 轮：重建容器，模拟应用重启后再读一次

- 用同一个 store 文件重新创建 `ModelContainer`
- 创建新的 `ModelContext`
- 再次读取待办列表
- 确认上一轮保存的数据仍然存在

如果你能用自己的话解释这两轮各自在验证什么，本章主线就没有偏：

- 第 1 轮验证的是“我能不能把本地记录当对象来管理”
- 第 2 轮验证的是“这些对象修改有没有真的落到磁盘”

## 三个核心角色：不要背定义，要看它们各自解决什么问题

### 1. `@Model`：哪些数据值得被长期保存

```swift
import SwiftData

@Model
final class TodoItem {
    var title: String
    var isDone: Bool
    var createdAt: Date
    var updatedAt: Date

    init(
        title: String,
        isDone: Bool = false,
        createdAt: Date = .now,
        updatedAt: Date = .now
    ) {
        self.title = title
        self.isDone = isDone
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
```

这里的重点不是“这个宏长什么样”，而是：

- `TodoItem` 已经不再只是某次请求返回的临时值
- 它现在是应用里一条可长期存在、可修改、可删除的记录

也就是说，`@Model` 解决的是这个工程问题：

- 哪些类型应该进入本地持久化系统，成为可被管理的数据对象

在这个阶段，你只需要抓住一个非常实用的判断：

- 如果某类数据需要长期保存、频繁修改、后续还可能被筛选和排序，它就很可能值得建成 `@Model`

### 2. `ModelContainer`：谁来承载整套本地数据系统

如果说 `@Model` 决定了“保存什么”，那么 `ModelContainer` 决定的是：

- 应用启动后，谁来承载这整套本地持久化系统

函数声明：

```swift
func makeContainer(storeURL: URL) throws -> ModelContainer
```

从开发视角理解，`ModelContainer` 至少承担三件事：

- 知道当前系统要管理哪些模型类型
- 知道底层数据存放在哪里
- 为后续的 `ModelContext` 提供依附基础

参数：

- `storeURL`：SwiftData 底层 store 文件位置

返回值：

- `ModelContainer`

作用：

- 创建一套可以管理 `TodoItem` 的本地持久化系统入口

所以排错时可以这样想：

- 如果容器都没创建成功，后面的 CRUD 根本无从开始
- 如果容器连到了错误位置，你看到的数据就可能不是你预期的那份

### 3. `ModelContext`：这次读写到底发生在哪里

`ModelContext` 是你日常操作最多的对象，它解决的问题是：

- 当前这次插入、读取、修改、删除，究竟发生在什么上下文里

先把“上下文”这个词说得更具体一点。

这里的上下文，不是一个为了显得专业而加上的抽象名词。你可以先把它理解成：

- 当前这次本地读写操作所在的工作现场
- 当前有哪些对象正在被读取、插入、修改、删除的那层边界
- 当前哪些变更只是留在内存里，哪些会在 `save()` 后真正落盘的管理范围

如果只用一句话概括：

- `ModelContainer` 更像整套持久化系统的底座
- `ModelContext` 更像你这一次具体操作数据时所在的工作区

所以当你写下面这些代码时：

- `context.insert(item)`
- `context.fetch(descriptor)`
- `context.delete(item)`

真正的含义是：

- 我正在这个上下文里登记一次插入
- 我正在这个上下文里读取一批对象
- 我正在这个上下文里标记一次删除

最小操作集中在这里：

- `insert(_:)`
- `fetch(_:)`
- `delete(_:)`
- `save()`

这里最值得建立的认知不是 API 名字，而是顺序：

1. 先在上下文里做变更
2. 再显式 `save()` 持久化

本章坚持显式保存，原因不是“唯一正确”，而是它最适合教学和排错：

- 数据没落盘时，你能清楚怀疑是不是没调用 `save()`
- 重启后读不到数据时，你也更容易判断问题落在哪一步

## 用 `ModelContext` 直接跑最小 CRUD

本章先不急着讲工程封装，直接用 `ModelContext` 跑一遍最小动作，避免你把 SwiftData 核心概念和代码组织动作混在一起。

### 1. 读取全部待办

```swift
func fetchAll(in context: ModelContext) throws -> [TodoItem] {
    let descriptor = FetchDescriptor<TodoItem>(
        sortBy: [SortDescriptor(\TodoItem.createdAt, order: .forward)]
    )
    return try context.fetch(descriptor)
}
```

这一步在解决的开发问题非常朴素：

- 应用启动后，我怎么把当前本地已有的待办全部拿回来

函数声明：

```swift
func fetchAll(in context: ModelContext) throws -> [TodoItem]
```

参数：

- `context`：当前读写所在的 `ModelContext`

返回值：

- `[TodoItem]`：当前 store 中的全部待办，并按创建时间升序返回

作用：

- 读取当前本地已有的全部待办

### 2. 新增一条待办

```swift
func addTodo(title: String, in context: ModelContext) throws {
    let item = TodoItem(title: title)
    context.insert(item)
    try context.save()
}
```

这里你应该看到的不是语法，而是行为变化：

- 你不再需要把整份列表读出来、追加、再整体写回文件
- 你是在对一条记录执行插入动作

函数声明：

```swift
func addTodo(title: String, in context: ModelContext) throws
```

参数：

- `title`：新待办标题
- `context`：执行插入的 `ModelContext`

返回值：

- 无

作用：

- 创建一条新的本地待办并保存

### 3. 修改一条待办

```swift
func toggleDone(_ item: TodoItem, in context: ModelContext) throws {
    item.isDone.toggle()
    item.updatedAt = .now
    try context.save()
}
```

这正是本章相对第 43 章的核心升级：

- 你在改的是对象属性
- 持久化系统负责把这次对象变更落地

函数声明：

```swift
func toggleDone(_ item: TodoItem, in context: ModelContext) throws
```

参数：

- `item`：要修改的待办对象
- `context`：当前修改所在的 `ModelContext`

返回值：

- 无

作用：

- 切换一条待办的完成状态，并更新时间

### 4. 删除一条待办

```swift
func deleteTodo(_ item: TodoItem, in context: ModelContext) throws {
    context.delete(item)
    try context.save()
}
```

这段代码的价值也在于开发动作被明确表达了：

- 删除的是一条记录
- 不是自己手动改数组再整份写回文件

函数声明：

```swift
func deleteTodo(_ item: TodoItem, in context: ModelContext) throws
```

参数：

- `item`：要删除的待办对象
- `context`：当前删除所在的 `ModelContext`

返回值：

- 无

作用：

- 从当前持久化系统中移除一条记录，并保存结果

## 为什么“重建容器再读回”这么重要

很多人第一次写本地持久化时，会把“当前进程里能读到数据”和“数据真的持久化成功”混为一谈。

所以本章要求你一定做一次重建容器验证。

原因很简单：

- 同一个进程里读得到，可能只是内存中还有对象
- 只有重建容器后还能读回，才能证明数据真的进了底层存储

从排错角度看，这一步也非常有价值：

- 当前轮能读，重建后不能读：优先怀疑保存动作或 store 路径
- 当前轮都读不到：优先怀疑插入、查询或上下文本身

## 什么时候再加一层 `TodoStore`

跑通上面的最小链路后，你会发现一件很自然的事：

- 这些 `fetch / insert / delete / save` 逻辑迟早要收口

真实项目里，很多人会像 demo 一样加一个轻量 `TodoStore`：

```swift
struct TodoStore {
    let context: ModelContext

    func fetchAll() throws -> [TodoItem] {
        let descriptor = FetchDescriptor<TodoItem>(
            sortBy: [SortDescriptor(\TodoItem.createdAt, order: .forward)]
        )
        return try context.fetch(descriptor)
    }

    func add(title: String) throws {
        let item = TodoItem(title: title)
        context.insert(item)
        try context.save()
    }

    func toggle(_ item: TodoItem) throws {
        item.isDone.toggle()
        item.updatedAt = .now
        try context.save()
    }

    func delete(_ item: TodoItem) throws {
        context.delete(item)
        try context.save()
    }
}
```

这里要特别强调：

- `TodoStore` 不是 SwiftData 必学概念
- 它只是项目中整理持久化代码的一种方式

类型补充：

- `@Model`：把类型声明为 SwiftData 可管理、可持久化的模型
- `ModelContainer`：整套持久化系统的入口
- `ModelContext`：当前这次增删改查发生的上下文
- `TodoStore`：教程里自己加的薄封装，用来集中管理读取和写入逻辑，不是 SwiftData 强制要求的类型

为什么这一层在开发里有价值？因为它能把这些问题集中到一个地方：

- 待办怎么读
- 待办怎么插入
- 待办怎么保存
- 待办怎么删除

这样你后面继续整理“读取需求”和“依赖边界”时，才有一个稳定的存储入口。

## Demo 里你应该重点观察什么

本章配套 demo 不展示界面，只展示开发上真正关心的事情：

- store 文件放在哪里
- 第一次插入后有哪些待办
- 修改和删除后，列表结果如何变化
- 重建容器后，哪些数据被成功保留下来

你在终端里看到的每一轮输出，应该都能回答一个问题：

- 现在这一步是在验证插入、修改、删除，还是在验证持久化是否真的完成

## 本章的边界：为什么只会 CRUD 还不够

到这里，你已经能把待办项当作本地记录来维护了。但真实项目很快会继续提出新问题：

- 我只想读未完成的待办怎么办
- 我想按优先级和创建时间排序怎么办
- 我想让待办属于某个列表怎么办
- 删除一个列表时，里面的待办怎么办

这些都不是“再多写几个 CRUD 函数”就能自然解决的问题。

因为一旦数据开始增长，你面对的重点就不再只是“有没有保存成功”，而是：

- 怎么读才合理
- 怎么排序才稳定
- 关系怎么建才不会把删除逻辑写乱

这正是本章边界开始出现的地方。

## 从“会 CRUD”到“会管理读取与关系”

如果继续沿用待办场景，并把结构升级为：

- 待办项属于某个待办列表 `TodoList`
- 你需要只读某个列表下未完成的待办
- 你需要稳定排序，而不是把全部数据读出来后随手排序
- 你需要提前决定：删掉列表时，列表里的待办是跟着删，还是回到“未归类”

这时你会看到：

- 只会 CRUD 还不够
- 当记录开始增长，读取规则、排序和删除影响都会变成新的重点

## 边界说明

为了让入门阶段保持清楚，本章明确不做这些事：

- 不讲 SwiftUI 绑定和界面刷新
- 不讲关系建模与删除规则
- 不讲复杂筛选和排序
- 不讲迁移、同步、性能优化、多上下文协同

这些都不是不重要，而是它们会把“最小持久化闭环”这个主题冲散。
