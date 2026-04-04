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
- 开始建立持久化模型设计意识：哪些字段该存、哪些字段不该存、哪些字段适合给默认值、哪些字段应该做成可选
- 对关系建模建立最低认知：一对多关系在 SwiftData 里长什么样，为什么“关系”本身也是建模问题
- 区分“SwiftData 核心概念”和“项目里为了组织代码而加的一层 store”
- 理解这套最小 CRUD 闭环的边界：它解决了“能保存”，但还没覆盖“怎么读更合理”

## 本章对应资源

- 文稿：`docs/zh-CN/chapters/44-swiftdata-basics-model-container-context-and-crud.md`
- 示例项目：`demos/projects/44-swiftdata-basics-model-container-context-and-crud`

## 这一章在解决什么开发问题

第 43 章里，本地数据只是“远程返回的一份待办快照”。

而这一章把需求升级了一步：

- 用户会在本地新增待办
- 用户会切换待办完成状态
- 用户会删除某一条待办
- 这些修改在应用重启后仍然要保留

一旦需求变成这样，你管理的就不再是一份 JSON 文件，而是一条条本地记录。

随之而来的变化有三个：

- 你需要围绕“单条记录”做增删改，而不是每次整份读写
- 你开始需要一个长期稳定的本地数据入口，而不是一次性文件操作
- 你希望持久化系统帮你维护对象生命周期，而不是自己拼接文件读写流程

SwiftData 就是在这一步开始变得合适。

## 先把定位说清楚：SwiftData 不是“更高级的文件写入”

这一章先抓住一句话：

- `SwiftData` 让本地数据更像“可长期维护的记录集合”，而不是“需要你手工读写的一份文件”

从开发角度看，它主要在帮你做三件事：

- 定义哪些对象值得被长期保存
- 提供一个统一的本地数据系统入口
- 让你围绕对象做读写与保存

本章不会展开 UI、属性包装器或数据库理论。重点只放在：

- 作为开发者，你如何把“待办项”变成本地可维护记录
- 最小闭环是怎么跑通的
- 出问题时你该先怀疑哪一层

本章正文统一采用这种纯 SwiftData 的起手方式：

```swift
let container = try ModelContainer(for: TodoList.self, TodoItem.self)
let context = ModelContext(container)

let list = TodoList(name: "收件箱")
context.insert(list)

let item = TodoItem(title: "在本地新增一条待办", list: list)
context.insert(item)
try context.save()
```

也就是说，本章重点是：

- `@Model`
- `ModelContainer`
- `ModelContext`
- `insert / fetch / delete / save`

而不是任何界面层注入或绑定写法。

## 统一场景：待办项已经变成“用户本地维护的数据”

这章开始，待办项不再是远程结果快照，而是用户本地维护的数据本体。

场景具体化以后，需求就很明确了：

1. 应用启动后要能打开本地数据系统
2. 用户新增一条待办时，数据要被记录下来
3. 用户修改状态时，不需要重写整份文件
4. 用户删除一条待办后，本地记录要同步消失
5. 应用重启后，之前的记录还能读回来

这个需求本章会先在正文里用最小代码讲清楚，demo 只负责帮助你观察运行结果。

## 本章怎么读

建议按这个顺序读：

1. 先看完整闭环在做什么，而不是先背术语
2. 再看 `@Model`、`ModelContainer`、`ModelContext` 分别在这个闭环里扮演什么角色
3. 然后看“模型怎么设计”本身：字段、默认值、可选值、时间字段、关系
4. 最后再看最小 CRUD 是如何围绕 `ModelContext` 完成的
5. 再看为什么真实项目里常常会加一层 `TodoStore`

如果你读完能独立写出这几个动作，本章就达标：

- 创建本地持久化容器
- 新增一条待办
- 读取全部待办
- 切换某一条待办状态
- 删除某一条待办
- 重建容器后再次读取并确认数据仍然存在

## 先看完整闭环：正文先给出一份最小可运行骨架

先不要跳去 demo。只看下面这段正文代码，你就应该能把第 44 章的主线看清楚：

```swift
import Foundation
import SwiftData

@Model
final class TodoList {
    var name: String

    @Relationship(inverse: \TodoItem.list)
    var items: [TodoItem] = []

    init(name: String) {
        self.name = name
    }
}

@Model
final class TodoItem {
    var title: String
    var isDone: Bool
    var priority: Int
    var notes: String?
    var createdAt: Date
    var updatedAt: Date
    var list: TodoList?

    init(
        title: String,
        isDone: Bool = false,
        priority: Int = 0,
        notes: String? = nil,
        createdAt: Date = .now,
        updatedAt: Date = .now,
        list: TodoList? = nil
    ) {
        self.title = title
        self.isDone = isDone
        self.priority = priority
        self.notes = notes
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.list = list
    }
}

struct TodoStore {
    let context: ModelContext

    func fetchAll() throws -> [TodoItem] {
        let descriptor = FetchDescriptor<TodoItem>(
            sortBy: [
                SortDescriptor(\TodoItem.priority, order: .reverse),
                SortDescriptor(\TodoItem.createdAt, order: .forward)
            ]
        )
        return try context.fetch(descriptor)
    }

    func fetchLists() throws -> [TodoList] {
        let descriptor = FetchDescriptor<TodoList>(
            sortBy: [SortDescriptor(\TodoList.name, order: .forward)]
        )
        return try context.fetch(descriptor)
    }

    @discardableResult
    func addList(name: String) throws -> TodoList {
        let list = TodoList(name: name)
        context.insert(list)
        try context.save()
        return list
    }

    func add(
        title: String,
        priority: Int = 0,
        notes: String? = nil,
        list: TodoList? = nil
    ) throws {
        let item = TodoItem(title: title, priority: priority, notes: notes, list: list)
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

let container = try ModelContainer(for: TodoList.self, TodoItem.self)
let context = ModelContext(container)
let store = TodoStore(context: context)

let inbox = try store.addList(name: "收件箱")
try store.add(title: "在本地新增一条待办", priority: 2, notes: "演示默认值和可选字段")
try store.add(title: "验证 SwiftData 的最小 CRUD", priority: 1, list: inbox)

var items = try store.fetchAll()
try store.toggle(items[0])
try store.delete(items[1])

let containerAfterRestart = try ModelContainer(for: TodoList.self, TodoItem.self)
let contextAfterRestart = ModelContext(containerAfterRestart)
let storeAfterRestart = TodoStore(context: contextAfterRestart)
let persistedItems = try storeAfterRestart.fetchAll()
print(persistedItems.count)
```

显然你不需要把这段代码逐行背下来，你只需要理解其中的几个重点即可：

- 用 `@Model` 定义哪些对象值得长期保存
- 用 `ModelContainer` 创建本地持久化容器
- 用 `ModelContext` 承接当前这次读写
- 开始看懂一个持久化模型除了标题和状态，还能怎么设计字段和最小关系
- 用一个很薄的 `TodoStore` 把 CRUD 收口

## 持久化建模不只是“把几个属性列出来”

很多人第一次接触 SwiftData，会把重点全放在：

- `insert`
- `save`
- `fetch`

但真实工程里，持久化系统第一步其实不是 CRUD，而是建模。

因为一旦模型设计得含糊，后面所有读写都会跟着变形。当前章先建立一个最小但完整的建模视角：

- 哪些字段属于真正要长期保存的数据
- 哪些字段只是业务推导，不该直接存
- 哪些字段适合默认值
- 哪些字段应该允许为空
- 关系是不是也应该算模型的一部分

换句话说，这一章除了“会操作数据”，也要开始学习“怎样定义数据”。

## 三个核心角色：不要背定义，要看它们各自解决什么问题

### 1. `@Model`：哪些数据值得被长期保存

```swift
import SwiftData

@Model
final class TodoItem {
    var title: String
    var isDone: Bool
    var priority: Int
    var notes: String?
    var createdAt: Date
    var updatedAt: Date

    init(
        title: String,
        isDone: Bool = false,
        priority: Int = 0,
        notes: String? = nil,
        createdAt: Date = .now,
        updatedAt: Date = .now
    ) {
        self.title = title
        self.isDone = isDone
        self.priority = priority
        self.notes = notes
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
```

这里先别盯着宏本身的写法，先看它解决什么问题：

- `TodoItem` 已经不再只是某次请求返回的临时值
- 它现在是应用里一条可长期存在、可修改、可删除的记录

换成工程语言，`@Model` 解决的是：

- 哪些类型应该进入本地持久化系统，成为可被管理的数据对象

这个阶段先抓住一个判断就够了：

- 如果某类数据需要长期保存、频繁修改、后续还可能被筛选和排序，它就很可能值得建成 `@Model`

这里再顺手补两个很常用的细节：

- `final class`
  - 本章常见形式：`@Model final class TodoItem`
  - 作用：SwiftData 的持久化模型在教程里统一用引用类型，强调“这是一条可被上下文跟踪的本地记录”。

- `init(...)`
  - 本章常见形式：`TodoItem(title: "在本地新增一条待办")`
  - 作用：在 `insert` 前创建一条新的本地对象，不是为了 JSON 解码服务

## 一个 `@Model` 里最常见的字段类型到底怎么选

当前 demo 里的 `TodoItem` 故意不再只放两个字段，而是把持久化模型里最常见的几类字段都摆出来：

- `title: String`
  - 基础文本字段
- `isDone: Bool`
  - 基础状态字段
- `priority: Int`
  - 适合排序或筛选的简单数值字段
- `notes: String?`
  - 可选文本，允许“这条记录可以没有备注”
- `createdAt: Date`
  - 创建时间
- `updatedAt: Date`
  - 修改时间

这几类字段非常典型，因为它们几乎覆盖了多数本地模型的起手设计。

### 1. 基础字段：`String`、`Bool`、`Int`

这一类字段的判断通常最简单：

- `String`
  - 适合标题、名称、描述、备注
- `Bool`
  - 适合完成状态、开关状态、是否归档
- `Int`
  - 适合优先级、数量、顺序、计数

当前 demo 里：

- `title` 用来表达业务内容
- `isDone` 用来表达任务状态
- `priority` 用来表达排序优先级

这比只写一个 `title` 更接近真实项目，因为你很快就会遇到“这条记录除了标题还能存什么”的问题。

### 2. 可选字段：什么时候该用 `?`

`notes: String?` 这类字段解决的不是“高级语法问题”，而是业务事实：

- 有些记录本来就允许缺值

如果你把本来允许为空的字段硬写成非可选，通常只会得到两类坏结果：

- 用空字符串伪装“没有值”
- 到处编造占位值，污染业务判断

所以像备注、补充说明、附件说明这类字段，经常天然就适合做成可选。

### 3. 默认值：什么时候该直接写在模型里

`priority = 0`、`isDone = false`、`createdAt = .now` 这类默认值的意义是：

- 让一条新记录在最常见场景下创建成本更低
- 让模型自己带着一份稳定的初始状态

当前 demo 里：

- 不传 `priority` 时，默认从 `0` 开始
- 不传 `notes` 时，默认就是 `nil`
- 不传 `createdAt` / `updatedAt` 时，默认取当前时间

这能显著减少调用方的样板代码。

### 4. 时间字段：为什么常常成对出现

很多入门示例只放一个 `createdAt`，但真实模型里经常是：

- `createdAt`
- `updatedAt`

它们服务的是两件不同的事：

- `createdAt`
  - 这条记录什么时候诞生
- `updatedAt`
  - 这条记录最近一次什么时候被修改

这不是“字段多一点更专业”，而是它们对排序、调试、同步、冲突判断都很常见。

## 哪些东西不该直接存进 `@Model`

当你开始会建字段之后，第二个容易踩的坑是：

- 什么都想往模型里塞

这一章先立一个很实用的判断：

- 需要长期保存、以后还要再读出来的数据，才适合直接存
- 只是在运行时临时算出来的结果，更适合做计算属性

例如：

```swift
var displayTitle: String {
    "[P\\(priority)] " + title
}
```

这种值很适合在业务层或模型上做计算属性，但通常没必要真的写进持久化字段，因为它完全可以由已有字段稳定推导出来。

再例如：

- “未完成任务数”
- “展示用组合标题”
- “按钮颜色”

这类值一般都不该在这一章直接做成存储字段。

## 关系建模也是持久化建模的一部分

关系建模不应该被理解成“只有更后面的主题才需要关心的内容”。它本质上就是持久化建模的一部分。

这一章的 demo 不只停留在单模型，而是把最基础的 `TodoList -> TodoItem` 一对多关系真正跑起来。这里讨论的不是关系声明的表面写法，而是当前章就会直接用到的建模知识。

本章先建立最低认知：

- 持久化模型不一定总是孤立的一张表意对象
- 很多时候，一条记录会属于另一个记录，或者拥有一组子记录

最常见的一对多形状大致像这样：

```swift
@Model
final class TodoList {
    var name: String

    @Relationship(inverse: \TodoItem.list)
    var items: [TodoItem] = []

    init(name: String) {
        self.name = name
    }
}

@Model
final class TodoItem {
    var title: String
    var list: TodoList?

    init(title: String, list: TodoList? = nil) {
        self.title = title
        self.list = list
    }
}
```

这里你最少要先看懂三件事：

- `TodoList.items`
  - 父对象持有一组子对象
- `TodoItem.list`
  - 子对象知道自己属于哪个父对象
- `@Relationship(inverse: ...)`
  - 这不是普通数组属性，而是在告诉 SwiftData：这里存在真正的关系

也就是说，关系建模不是“把另一个对象塞进属性里就完了”，而是：

- 你在定义记录之间如何关联
- 你在告诉持久化系统：这些对象不是彼此独立的

本章先把关系建模当成“建模视角”的一部分建立起来，而不继续往查询语义和删除语义展开。

## 把最小一对多关系真正跑起来

如果关系建模只停在一段类型声明里，它还是容易被读成“知识点认识”。所以本章 demo 还会做一轮真正的关系落盘验证。

核心代码形状非常简单：

```swift
let workList = try store.addList(name: "工作")
let lifeList = try store.addList(name: "生活")

try store.add(
    title: "整理 Sprint 计划",
    priority: 3,
    notes: "演示记录直接归属到某个 TodoList",
    list: workList
)

try store.add(
    title: "预约体检",
    priority: 2,
    list: lifeList
)

try store.add(
    title: "收集未归类灵感",
    priority: 1,
    notes: "演示可选关系：list 可以为空"
)
```

这段演示在本章里有三个明确目的：

- 证明关系不是“写了属性就算会了”，而是要真正插入父对象、子对象，并让它们一起进入持久化系统
- 证明可选关系本身也是建模选择：有些待办天然允许先处于“未归类”状态
- 证明关系也必须经过“重建容器后再读回”的验证，才能确认不是当前上下文里的内存假象

所以这一章不仅验证：

- 单条记录能不能新增、修改、删除

也同时验证：

- 一对多关系能不能被创建
- 子对象能不能正确挂到父对象上
- 重建容器后父子关系还在不在

对应官方文档：

- [`@Model` / SwiftData 概览相关入口（Apple Developer）](https://developer.apple.com/documentation/swiftdata)

### 2. `ModelContainer`：谁来承载整套本地数据系统

如果说 `@Model` 决定了“保存什么”，那么 `ModelContainer` 决定的是：

- 应用启动后，谁来承载这整套本地持久化系统

从开发视角看，`ModelContainer` 至少承担三件事：

- 知道当前系统要管理哪些模型类型
- 知道底层数据存放在哪里
- 为后续的 `ModelContext` 提供依附基础

最小代码可以先写成这样：

```swift
enum TodoStoreBootstrap {
    static func storeURL() throws -> URL {
        let fm = FileManager.default
        let caches = try fm.url(
            for: .cachesDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )

        let folder = caches
            .appendingPathComponent("learn-swift", isDirectory: true)
            .appendingPathComponent("44-swiftdata-basics", isDirectory: true)

        try fm.createDirectory(at: folder, withIntermediateDirectories: true)
        return folder.appendingPathComponent("todos.store")
    }

    static func makeContainer(at storeURL: URL) throws -> ModelContainer {
        let configuration = ModelConfiguration(url: storeURL)
        return try ModelContainer(
            for: TodoList.self,
            TodoItem.self,
            configurations: configuration
        )
    }
}
```

这里的 `storeURL()` 会继续用到第 `42` 章已经讲过的文件系统 API：

- `FileManager.url(for:in:appropriateFor:create:)`
- `appendingPathComponent(_:isDirectory:)`
- `createDirectory(at:withIntermediateDirectories:attributes:)`

所以这一段的重点不是重新认识这些 API，而是理解：

- 为什么 SwiftData 的 store 也需要先决定一个稳定文件位置
- 为什么在真正创建 `ModelContainer` 前，要先把父目录准备好

对应官方文档：

- [`ModelContainer`（Apple Developer）](https://developer.apple.com/documentation/swiftdata/modelcontainer)
- [`ModelConfiguration`（Apple Developer）](https://developer.apple.com/documentation/swiftdata/modelconfiguration)
- [`FetchDescriptor`（Apple Developer）](https://developer.apple.com/documentation/swiftdata/fetchdescriptor)
- [`SortDescriptor`（Apple Developer）](https://developer.apple.com/documentation/foundation/sortdescriptor)

这一小段里，其实包含了两层事情：

1. 先决定底层 store 文件放在哪里
2. 再按这个位置创建 SwiftData 容器

### 先看 `storeURL()`

函数声明：

```swift
static func storeURL() throws -> URL
```

参数：

- 无

返回值：

- `URL`：底层 store 文件的位置

作用：

- 找到合适的系统目录
- 创建用于本章演示的文件夹
- 返回最终的 `todos.store` 文件地址

逐行看这段实现：

- `let fm = FileManager.default`
  - 拿到文件系统操作入口。
  - 后面找目录、建目录都要通过它完成。

- `let caches = try fm.url(for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: true)`
  - 这一步是在向系统要“当前用户的缓存目录 URL”。
  - `for: .cachesDirectory` 表示目标目录类型是缓存目录。
  - `in: .userDomainMask` 表示取当前用户域下的目录，而不是系统级公共位置。
  - `appropriateFor: nil` 在这里表示不为某个替换操作额外指定参考位置。
  - `create: true` 表示如果系统判断这个目录需要被创建，就允许创建。
  - 返回值是一个 `URL`，不是字符串路径。这一点很重要，因为后续拼接路径时，用 `URL` 比手写字符串稳得多。

- `let folder = caches.appendingPathComponent(...).appendingPathComponent(...)`
  - 这两步是在缓存目录下继续拼出本章自己的子目录。
  - `appendingPathComponent(_:isDirectory:)` 的作用是基于已有目录 URL 继续拼接一段路径。
  - `isDirectory: true` 是在明确告诉系统：这里拼出来的是目录，不是普通文件。

- `try fm.createDirectory(at: folder, withIntermediateDirectories: true)`
  - 这一步是真正保证目录存在。
  - `at:` 是要创建的目标目录。
  - `withIntermediateDirectories: true` 表示中间目录如果还不存在，也一并创建。
  - 返回值是 `Void`，也就是成功时不返回额外内容；失败就抛错。

- `return folder.appendingPathComponent("todos.store")`
  - 这一步还没有创建数据库文件本身，只是在返回“容器应该使用哪个文件 URL”。
  - 真正读写这个位置，是后面 `ModelContainer` 的职责。

### 再看 `makeContainer(at:)`

函数声明：

```swift
static func makeContainer(at storeURL: URL) throws -> ModelContainer
```

参数：

- `storeURL`：底层持久化文件的位置

返回值：

- `ModelContainer`：一套可以管理指定模型并连接到底层存储的 SwiftData 容器

作用：

- 用配置对象描述“这套数据系统应该怎么落到磁盘”
- 创建真正的 SwiftData 容器，让后续 `ModelContext` 可以依附其上工作

这里需要澄清一个概念 `ModelConfiguration` 和 `ModelContainer` 不是一回事：

- `ModelConfiguration` 更像“配置说明书”
- `ModelContainer` 更像“真正运行起来的持久化系统”

先看这一行：

```swift
let configuration = ModelConfiguration(url: storeURL)
```

按 `Apple Developer` 文档，`ModelConfiguration` 是“描述应用 schema 或特定模型组配置”的类型。放到当前代码里，它做的事情可以直接理解成：

- 把“数据存哪”这件事包装成一个 SwiftData 能理解的配置对象

这一行里需要要理解两个点：

- `ModelConfiguration(url: storeURL)` 里的参数 `url`
  - 类型是 `URL`
  - 含义是让 SwiftData 把这套 store 落到这个文件位置

- 返回值 `configuration`
  - 类型是 `ModelConfiguration`
  - 它本身还不能拿来 `fetch` 或 `save`
  - 它只是后面创建容器时要用到的配置输入

再看这一行：

```swift
return try ModelContainer(
    for: TodoList.self,
    TodoItem.self,
    configurations: configuration
)
```

按 `Apple Developer` 文档，`ModelContainer` 是“管理应用 schema 和模型存储配置的对象”。这里可以把它理解成：

- 它知道这套系统要管理哪些模型
- 它知道这些模型背后连到哪份底层存储
- 当 `ModelContext` 去 `fetch` 或 `save()` 时，真正协调读写的是它

这一行里新出现的点有三个：

- `for: TodoList.self, TodoItem.self`
  - 这里传入的是要交给 SwiftData 管理的模型类型。
  - 当前章已经不是只有一个模型，而是把列表和待办一起交给容器管理。

- `configurations: configuration`
  - 这里传入的是刚刚构造好的配置对象。
  - 在当前章节里，我们只关心一件事：它把 store 位置告诉了容器。

- 返回值 `ModelContainer`
  - 这是后面创建 `ModelContext` 的依附基础。
  - 如果容器创建失败，说明模型声明、配置或底层存储路径这一层就已经出问题，后面的 CRUD 都无从谈起。

所以，这段代码的作用可以压成一句话：

- `storeURL()` 决定文件放哪
- `ModelConfiguration(url:)` 把“放哪”包装成配置
- `ModelContainer(...)` 按“管理哪些模型 + 用哪份配置”创建真正的持久化系统

所以排错时可以这样想：

- 如果容器都没创建成功，后面的 CRUD 根本无从开始
- 如果容器连到了错误位置，你看到的数据就可能不是你预期的那份

### 3. `ModelContext`：这次读写到底发生在哪里

`ModelContext` 是你日常操作最多的对象，它解决的问题是：

- 当前这次插入、读取、修改、删除，究竟发生在什么上下文里

先把“上下文”说得具体一点。

这里的上下文不是为了显得专业才加上的术语，可以直接把它看成：

- 当前这次本地读写操作所在的工作现场
- 当前有哪些对象正在被读取、插入、修改、删除的那层边界
- 当前哪些变更只是留在内存里，哪些会在 `save()` 后真正落盘的管理范围

如果只用一句话说：

- `ModelContainer` 更像整套持久化系统的底座
- `ModelContext` 更像你这一次具体操作数据时所在的工作区

对应官方文档：

- [`ModelContext`（Apple Developer）](https://developer.apple.com/documentation/swiftdata/modelcontext)

最小启动代码通常长这样：

```swift
let storeURL = try TodoStoreBootstrap.storeURL()
let container = try TodoStoreBootstrap.makeContainer(at: storeURL)
let context = ModelContext(container)
```

如果你想模拟“应用重启后再读一次”，并不是去重置 `context`，而是重新走一遍：

```swift
let containerAfterRestart = try TodoStoreBootstrap.makeContainer(at: storeURL)
let contextAfterRestart = ModelContext(containerAfterRestart)
```

所以当你写下面这些代码时：

- `context.insert(item)`
- `context.fetch(descriptor)`
- `context.delete(item)`

它的意思其实很直白：

- 我正在这个上下文里登记一次插入
- 我正在这个上下文里读取一批对象
- 我正在这个上下文里标记一次删除

操作集中在这里：

- `insert(_:)`
- `fetch(_:)`
- `delete(_:)`
- `save()`

这四个 API 最好按“职责顺序”记：

- `insert(_:)`
  - 解决的问题：把新建对象登记进当前上下文。
  - 当前章落点：`context.insert(item)` 只是登记“这条记录应该被纳入持久化系统”，还没真正写盘。

- `save()`
  - 解决的问题：把当前上下文里的新增、修改、删除一起提交到底层 store。
  - 当前章落点：如果你漏掉它，同进程里有时看起来还能读到对象，但重建容器后往往就消失了。

- `delete(_:)`
  - 解决的问题：把某个模型对象标记为删除。
  - 当前章落点：和 `insert` 一样，它只是当前上下文里的变更登记，真正持久化仍然依赖 `save()`。

这里最该记住的不是 API 名字，而是顺序：

1. 先在上下文里做变更
2. 再显式 `save()` 持久化

本章坚持显式保存，原因不是“唯一正确”，而是它最适合教学和排错：

- 数据没落盘时，你能清楚怀疑是不是没调用 `save()`
- 重启后读不到数据时，你也更容易判断问题落在哪一步

## 把最小 CRUD 收口到一个 `TodoStore`

为了让正文本身完整，这里先把 `TodoStore` 的最小形状一次性放出来。配套 demo 只是把同样的逻辑跑起来给你观察结果，不是正文缺失部分的补丁。

```swift
struct TodoStore {
    let context: ModelContext

    func fetchAll() throws -> [TodoItem] {
        let descriptor = FetchDescriptor<TodoItem>(
            sortBy: [
                SortDescriptor(\TodoItem.priority, order: .reverse),
                SortDescriptor(\TodoItem.createdAt, order: .forward)
            ]
        )
        return try context.fetch(descriptor)
    }

    func fetchLists() throws -> [TodoList] {
        let descriptor = FetchDescriptor<TodoList>(
            sortBy: [SortDescriptor(\TodoList.name, order: .forward)]
        )
        return try context.fetch(descriptor)
    }

    @discardableResult
    func addList(name: String) throws -> TodoList {
        let list = TodoList(name: name)
        context.insert(list)
        try context.save()
        return list
    }

    func add(
        title: String,
        priority: Int = 0,
        notes: String? = nil,
        list: TodoList? = nil
    ) throws {
        let item = TodoItem(title: title, priority: priority, notes: notes, list: list)
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

这一段第一次把“读取描述”显式写出来，所以也值得把两个类型补成最小导读：

`FetchDescriptor`

- 它解决的问题：把“我要查什么模型、按什么条件、按什么顺序”描述成一个对象。
- 本章常用成员：初始化时的 `sortBy`
- 当前代码里怎么理解：它是 `context.fetch(...)` 前的一份查询说明书。

`SortDescriptor`

- 它解决的问题：把排序规则写成可组合的描述，而不是查出来后再临时排序。
- 本章常用成员：排序键路径、`order`
- 当前代码里怎么理解：这里它先按 `priority` 排主要顺序，再用 `createdAt` 保证同优先级时仍然稳定。

这个类型不是 SwiftData 强制要求的。它只是一个很薄的“存储入口”，方便把读取和写入动作收口。

这里也可以顺手看懂一个工程上的选择：

- `fetchAll()` 负责收口“把全部待办按稳定顺序读回来”
- `fetchLists()` 负责收口“把父对象列表本身读回来”
- `addList(name:)` 负责创建父对象
- `add(..., list:)` 负责在创建子对象时决定是否挂到某个父对象上

这几个动作放在一起，当前章就不只是“单条记录 CRUD”，而是已经开始覆盖最基础的本地关系建模。

### 1. 读取全部待办

```swift
struct TodoStore {
    let context: ModelContext

    func fetchAll() throws -> [TodoItem] {
        let descriptor = FetchDescriptor<TodoItem>(
            sortBy: [
                SortDescriptor(\TodoItem.priority, order: .reverse),
                SortDescriptor(\TodoItem.createdAt, order: .forward)
            ]
        )
        return try context.fetch(descriptor)
    }
}
```

这一步解决的问题是：

- 应用启动后，我怎么把当前本地已有的待办全部拿回来

这段代码的作用是读取当前 `TodoStore` 关联上下文中的全部待办，并按“优先级倒序 + 创建时间升序”稳定返回。

如果只看结果，在实际工程中很容易变成“照着抄”。这里把每一行拆开：

- `struct TodoStore {`
  - 这里先定义一个很薄的存储入口。
  - 它不是 SwiftData 强制要求的类型，而是教程为了把读写逻辑收口，主动加的一层。
  - 这样做的好处是：后面你找“待办怎么读、怎么加、怎么删”时，不用在 demo 里到处翻。

- `let context: ModelContext`
  - `TodoStore` 自己不创建 `ModelContext`，而是接收外面传进来的上下文。
  - 这说明 `TodoStore` 只是“使用这个上下文做事”，不负责“创建整套持久化系统”。
  - 这里也顺手把职责分开了：
  - `ModelContainer` 负责承载存储系统。
  - `ModelContext` 负责当前这次读写操作。
  - `TodoStore` 负责把这些读写动作整理成更好用的方法。

- `func fetchAll() throws -> [TodoItem] {`
  - 这个方法的名字很直接：取回全部待办。
  - 返回值是 `[TodoItem]`，说明读出来的不是 DTO，也不是 JSON，而是 SwiftData 管理的模型对象。
  - 这里标了 `throws`，说明读取过程可能失败，调用方不能假设它一定成功。
  - 即使只是“读数据”，也可能因为底层 store、上下文或查询过程出错而抛错。

- `let descriptor = FetchDescriptor<TodoItem>(`
  - 这一行开始在构造“查询描述”。
  - `FetchDescriptor<TodoItem>` 的意思不是“立刻去查”，而是先把“我要查什么类型、怎么查”描述出来。
  - 这里的目标类型是 `TodoItem`，也就是告诉 SwiftData：这次查询面对的是待办模型。

- `sortBy: [SortDescriptor(...), SortDescriptor(...)]`
  - 这一行决定返回结果的顺序。
  - 第一个 `SortDescriptor` 按 `priority` 倒序，表示优先级高的任务排前面。
  - 第二个 `SortDescriptor` 按 `createdAt` 正序，表示同优先级时更早创建的任务排前面。
  - 这里特意把双重排序写进查询，而不是读出来以后再临时排序，是为了让读取规则稳定、明确、可重复。
  - 如果只写一个排序键，列表一旦出现并列值，顺序就可能看起来不稳定。

- `)`
  - 到这里，查询描述对象构造完成。
  - 你可以把 `descriptor` 理解成“查询计划”或“查询说明书”，但它本身还没有真正去取数据。

- `return try context.fetch(descriptor)`
  - 这一行才是真正执行查询。
  - `context.fetch(...)` 的意思是：让当前 `ModelContext` 按这个描述去取 `TodoItem`。
  - 前面的 `try` 说明执行查询本身仍然可能失败，所以错误要继续往外抛。
  - 前面的 `return` 说明方法不再做额外加工，直接把查到的结果返回给调用方。

- `}`
  - `fetchAll()` 到这里结束。
  - 从结构上看，这个方法只做了两件事：定义排序规则，然后执行查询。
  - 这种写法很适合初学阶段，因为逻辑短、职责单一，排错时也容易定位。

- `}`
  - `TodoStore` 的这个最小读取入口定义完成。
  - 后面 `add / toggle / delete` 也会沿用同样的收口方式，让“对待办做什么”都集中在一个地方。

如果把这段再压成一句工程语言，它做的事情其实就是：

- 用 `FetchDescriptor` 明确描述“按什么顺序读取哪些模型”
- 再交给 `ModelContext` 去真正执行这次查询

### 2. 新增一条待办

```swift
func add(
    title: String,
    priority: Int = 0,
    notes: String? = nil,
    list: TodoList? = nil
) throws {
    let item = TodoItem(title: title, priority: priority, notes: notes, list: list)
    context.insert(item)
    try context.save()
}
```

这里你能看到的是语法，但最重要的，也是你看不到的，是行为变化：

- 你不再需要把整份列表读出来、追加、再整体写回文件
- 你是在对一条记录执行插入动作

这里只补四个参数说明：

- `title`：新待办标题
- `priority`：持久化优先级字段，默认从 `0` 开始
- `notes`：可选备注字段，没有就保持 `nil`
- `list`：可选父对象；传入时表示这条待办会归属到某个列表，不传时表示它暂时未归类

这段代码的作用是创建一条新的本地待办并保存。

这里最值得一起记住的其实是两步组合：

1. `context.insert(item)`
2. `try context.save()`

也就是说，SwiftData 的最小新增闭环不是“构造对象就自动持久化”，而是：

- 先创建对象
- 再把它放进 `ModelContext`
- 最后显式保存

如果当前记录需要直接归属到某个父对象，那么这一步也会一起完成关系建立：

- `list: workList`
  - 表示这条记录在创建时就属于 `workList`
- `list: nil`
  - 表示它先作为未归类记录存在

### 3. 修改一条待办

```swift
func toggle(_ item: TodoItem) throws {
    item.isDone.toggle()
    item.updatedAt = .now
    try context.save()
}
```

这也是它和第 43 章最明显的不同：

- 你在改的是对象属性
- 持久化系统负责把这次对象变更落地

这里只补一个参数说明：

- `item`：要修改的待办对象

这段代码的作用是切换一条待办的完成状态，并更新时间。

这一段也刚好能帮助你区分：

- `ModelContext` 负责跟踪对象变更
- `save()` 负责让这些变更真正持久化

所以修改动作的常见形状不是“重新构造一个新对象覆盖回去”，而往往是：

- 直接改模型属性
- 再 `save()`

### 4. 删除一条待办

```swift
func delete(_ item: TodoItem) throws {
    context.delete(item)
    try context.save()
}
```

这段代码的价值也在于开发动作被明确表达了：

- 删除的是一条记录
- 不是自己手动改数组再整份写回文件

这里只补一个参数说明：

- `item`：要删除的待办对象

这段代码的作用是从当前持久化系统中移除一条记录，并保存结果。

这里重要的是它和第 43 章“删文件”完全不是一类动作：

- 第 43 章删的是整个文件
- 第 44 章删的是一条记录对象

这也是为什么进入 SwiftData 后，操作粒度已经从“整份文件”升级到了“单条模型”。

## 现在回头看：这三轮验证各自在确认什么

到这里再回头看开头那段完整骨架，顺序就更自然了。

- 第 1 轮：在同一个容器里做新增、读取、修改、删除
  - 它在验证“本地记录能不能像对象一样被管理”
  - 也就是验证 `ModelContext + save()` 这条最小 CRUD 链路有没有跑通

- 第 1.5 轮：在同一个容器里建立 `TodoList -> TodoItem` 关系
  - 它在验证“关系是不是也能作为持久化模型的一部分被保存下来”
  - 也就是验证父对象、子对象、可选关系三种建模选择都能进入当前 store

- 第 2 轮：用同一个 `storeURL` 重建 `ModelContainer` 和 `ModelContext`
  - 它在验证“这些变更和关系有没有真的落盘”
  - 也就是验证你前面调用的 `save()` 有没有把数据真正写进底层 store，而不是只留在当前进程内存里

## 为什么“重建容器再读回”这么重要

很多人第一次写本地持久化时，会把“当前进程里能读到数据”和“数据真的持久化成功”混为一谈。

所以本章要求你一定做一次重建容器验证。

原因很简单：

- 同一个进程里读得到，可能只是内存中还有对象
- 只有重建容器后还能读回，才能证明数据真的进了底层存储

从排错角度看，这一步也非常有价值：

- 当前轮能读，重建后不能读：优先怀疑保存动作或 store 路径
- 当前轮都读不到：优先怀疑插入、查询或上下文本身

## 为什么 demo 选择 `TodoStore`

这一章的 demo 一开始就用了一个轻量 `TodoStore`，理由也很简单：

- 它把 `fetch / insert / delete / save` 这些动作收口到一个地方
- 它让教程里的每个核心方法都能在 demo 中直接找到
- 它避免你在教学阶段同时追踪“数据逻辑”与“代码散落在哪”

这里要特别强调：

- `TodoStore` 不是 SwiftData 必学概念
- 它只是项目中整理持久化代码的一种方式

这里真正要记住的只有一件事：

- `TodoStore` 是教程里自己加的一层薄封装，用来把读取和写入逻辑收口；它不是 SwiftData 强制要求的类型

## Demo 里你应该重点观察什么

本章配套 demo 不展示界面，只展示开发上真正关心的事情：

- store 文件放在哪里
- 第一次插入后有哪些待办
- 默认值、可选字段、优先级字段是如何落进模型的
- `TodoList` 和 `TodoItem` 的一对多关系是怎样建立出来的
- 哪些待办归属于某个列表，哪些待办保持未归类
- 修改和删除后，列表结果如何变化
- 重建容器后，哪些数据和父子关系被成功保留下来

你在终端里看到的每一轮输出，应该都能回答一个问题：

- 现在这一步是在验证插入、修改、删除，还是在验证持久化是否真的完成

## 常见误区 / 排错顺序

常见误区：

- 以为 `@Model` 就等于“数据库本身”，看不清容器和上下文各自负责什么
- 在一个 context 里改完就直接宣布“持久化成功”，却没有重建容器验证
- 把 SwiftData 原生概念和教程里的 `TodoStore` 组织层混在一起

排错顺序建议固定成这样：

1. 先看 `ModelContainer` 是否成功创建
2. 再看 `ModelContext` 是否真的执行了 `insert / delete / save`
3. 再看 fetch 结果是否符合当前 context 内的变更
4. 最后重建容器，再读一遍确认数据真的落盘

## 边界说明

为了让入门阶段保持清楚，本章明确不做这些事：

- 不讲界面层集成方式，例如容器注入、查询绑定和界面刷新联动
- 不展开复杂筛选表达式和大规模查询优化
- 不展开关系删除语义和同步冲突
- 不讲迁移、同步、性能优化、多上下文协同

这些并非不重要，而是它们会把主题冲散，且当前的前置知识不足以支撑。
