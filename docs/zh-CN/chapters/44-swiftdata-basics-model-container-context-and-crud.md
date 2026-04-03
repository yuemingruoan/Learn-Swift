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
3. 然后看最小 CRUD 是如何围绕 `ModelContext` 完成的
4. 最后再看为什么真实项目里常常会加一层 `TodoStore`

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
        return try ModelContainer(for: TodoItem.self, configurations: configuration)
    }
}

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

let storeURL = try TodoStoreBootstrap.storeURL()
let container = try TodoStoreBootstrap.makeContainer(at: storeURL)
let context = ModelContext(container)
let store = TodoStore(context: context)

try store.add(title: "在本地新增一条待办")
try store.add(title: "验证 SwiftData 的最小 CRUD")

var items = try store.fetchAll()
try store.toggle(items[0])
try store.delete(items[1])

let containerAfterRestart = try TodoStoreBootstrap.makeContainer(at: storeURL)
let contextAfterRestart = ModelContext(containerAfterRestart)
let storeAfterRestart = TodoStore(context: contextAfterRestart)
let persistedItems = try storeAfterRestart.fetchAll()
print(persistedItems.count)
```

显然你不需要把这段代码逐行背下来，你只需要理解其中的几个重点即可：

- 用 `@Model` 定义哪些对象值得长期保存
- 用 `ModelContainer` 打开或创建底层 store
- 用 `ModelContext` 承接当前这次读写
- 用一个很薄的 `TodoStore` 把 CRUD 收口

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

这里先别盯着宏本身的写法，先看它解决什么问题：

- `TodoItem` 已经不再只是某次请求返回的临时值
- 它现在是应用里一条可长期存在、可修改、可删除的记录

换成工程语言，`@Model` 解决的是：

- 哪些类型应该进入本地持久化系统，成为可被管理的数据对象

这个阶段先抓住一个判断就够了：

- 如果某类数据需要长期保存、频繁修改、后续还可能被筛选和排序，它就很可能值得建成 `@Model`

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
        return try ModelContainer(for: TodoItem.self, configurations: configuration)
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

这里最值得建立的认知，是 `ModelConfiguration` 和 `ModelContainer` 不是一回事：

- `ModelConfiguration` 更像“配置说明书”
- `ModelContainer` 更像“真正运行起来的持久化系统”

先看这一行：

```swift
let configuration = ModelConfiguration(url: storeURL)
```

按 Apple Developer 文档，`ModelConfiguration` 是“描述应用 schema 或特定模型组配置”的类型。放到当前代码里，它做的事情可以直接理解成：

- 把“数据存哪”这件事包装成一个 SwiftData 能理解的配置对象

这一行里你至少要看懂两个点：

- `ModelConfiguration(url: storeURL)` 里的参数 `url`
  - 类型是 `URL`
  - 含义是让 SwiftData 把这套 store 落到这个文件位置

- 返回值 `configuration`
  - 类型是 `ModelConfiguration`
  - 它本身还不能拿来 `fetch` 或 `save`
  - 它只是后面创建容器时要用到的配置输入

再看这一行：

```swift
return try ModelContainer(for: TodoItem.self, configurations: configuration)
```

按 Apple Developer 文档，`ModelContainer` 是“管理应用 schema 和模型存储配置的对象”。这里可以把它理解成：

- 它知道这套系统要管理哪些模型
- 它知道这些模型背后连到哪份底层存储
- 当 `ModelContext` 去 `fetch` 或 `save()` 时，真正协调读写的是它

这一行里新出现的点有三个：

- `for: TodoItem.self`
  - 这里传入的是要交给 SwiftData 管理的模型类型。
  - 如果你后面有多个 `@Model`，这里就会把多个模型类型一起传进去。

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

这一段第一次把“读取描述”显式写出来，所以也值得把两个类型补成最小导读：

`FetchDescriptor`

- 它解决的问题：把“我要查什么模型、按什么条件、按什么顺序”描述成一个对象。
- 本章常用成员：初始化时的 `sortBy`
- 当前代码里怎么理解：它是 `context.fetch(...)` 前的一份查询说明书。

`SortDescriptor`

- 它解决的问题：把排序规则写成可组合的描述，而不是查出来后再临时排序。
- 本章常用成员：排序键路径、`order`
- 当前代码里怎么理解：这里它负责保证待办按 `createdAt` 有稳定顺序。

这个类型不是 SwiftData 强制要求的。它只是一个很薄的“存储入口”，方便把读取和写入动作收口。

### 1. 读取全部待办

```swift
struct TodoStore {
    let context: ModelContext

    func fetchAll() throws -> [TodoItem] {
        let descriptor = FetchDescriptor<TodoItem>(
            sortBy: [SortDescriptor(\TodoItem.createdAt, order: .forward)]
        )
        return try context.fetch(descriptor)
    }
}
```

这一步解决的问题非常朴素：

- 应用启动后，我怎么把当前本地已有的待办全部拿回来

这段代码的作用是读取当前 `TodoStore` 关联上下文中的全部待办，并按创建时间升序返回。

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

- `sortBy: [SortDescriptor(\\TodoItem.createdAt, order: .forward)]`
  - 这一行决定返回结果的顺序。
  - `SortDescriptor` 可以理解成“排序规则”。
  - `\\TodoItem.createdAt` 表示按 `TodoItem` 的 `createdAt` 字段排序。
  - `order: .forward` 表示从小到大，也就是时间从早到晚。
  - 这里特意把排序写进查询，而不是读出来以后再临时排序，是为了让读取规则稳定、明确、可重复。
  - 如果这里不写排序，列表顺序就可能依赖底层存储当前返回的顺序，读者会误以为“SwiftData 自带稳定顺序”，这在教学上是危险的。

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
func add(title: String) throws {
    let item = TodoItem(title: title)
    context.insert(item)
    try context.save()
}
```

这里你能看到的是语法，但最重要的，也是你看不到的，是行为变化：

- 你不再需要把整份列表读出来、追加、再整体写回文件
- 你是在对一条记录执行插入动作

这里只补一个参数说明：

- `title`：新待办标题

这段代码的作用是创建一条新的本地待办并保存。

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

## 现在回头看：这两轮验证各自在确认什么

到这里再回头看开头那段完整骨架，顺序就更自然了。

- 第 1 轮：在同一个容器里做新增、读取、修改、删除
  - 它在验证“本地记录能不能像对象一样被管理”
  - 也就是验证 `ModelContext + save()` 这条最小 CRUD 链路有没有跑通

- 第 2 轮：用同一个 `storeURL` 重建 `ModelContainer` 和 `ModelContext`
  - 它在验证“这些变更有没有真的落盘”
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

这些并非不重要，而是它们会把主题冲散，且当前的前置知识不足以支撑。
