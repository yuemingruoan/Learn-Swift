# 45. 结构化读取与关系一致性：筛选、排序、列表与删除规则

## 阅读导航

- 前置章节：[44. 从快照到记录：SwiftData 最小持久化闭环](./44-swiftdata-basics-model-container-context-and-crud.md)
- 上一章：[44. 从快照到记录：SwiftData 最小持久化闭环](./44-swiftdata-basics-model-container-context-and-crud.md)
- 建议下一章：[46. 语言进阶：协议抽象、依赖注入与可测试设计](./46-protocol-abstraction-dependency-injection-and-testability.md)
- 下一章：[46. 语言进阶：协议抽象、依赖注入与可测试设计](./46-protocol-abstraction-dependency-injection-and-testability.md)
- 适合谁先读：已经能用 SwiftData 跑通本地待办的最小 CRUD，现在想解决“怎么读、怎么排、怎么建关系、怎么定义删除影响”的读者

## 本章目标

学完这一章后，你应该能够：

- 说清为什么只会 CRUD 还不足以支撑真实本地数据管理
- 用“查询、排序、关系、删除规则”四个维度拆解读取与一致性问题
- 理解 `#Predicate`、`FetchDescriptor`、`SortDescriptor` 在开发中分别承担什么职责
- 在 `TodoList + TodoItem` 的一对多场景里明确删除语义，而不是把关系处理留给默认行为
- 判断哪些问题应该继续交给 SwiftData，哪些更适合停留在文件缓存、内存处理或业务层

## 这一章在解决什么开发问题

第 44 章把待办项变成了可长期维护的本地记录，但那还只是起点。

一旦你的待办开始变多，新的问题会立刻出现：

- 我只想看某个列表下未完成的待办
- 我希望列表顺序稳定，而不是每次看起来都在抖动
- 我想让待办项属于某个待办列表
- 删掉一个待办列表时，列表里的待办到底该怎么办

这些问题的共同点是：

- 它们已经不是“会不会保存”
- 而是“如何读取”和“如何保证关系一致”

所以这一章的主线不是更多语法，而是更接近真实开发的数据管理问题。

## 场景升级：从单个待办，升级到“列表里的待办”

从这一章开始，场景升级为：

- 一个 `TodoList` 表示待办列表，例如“今天”“工作”“个人”
- 一个 `TodoItem` 表示列表里的单条待办
- `TodoItem` 可以属于某个列表，也可以暂时不属于任何列表

这会带来四类需求：

1. 按条件读：例如只读某个列表下未完成的待办
2. 按顺序读：例如先按优先级，再按创建时间
3. 按关系管理：例如一条待办属于哪个列表
4. 按规则删除：例如删掉列表后，待办是一起删还是保留为未归类

这四类需求，就是本章的四个核心主题。

## 本章怎么读

建议按下面顺序读：

1. 先看“读取需求为什么要拆成查询和排序”
2. 再看“关系为什么会把删除问题变复杂”
3. 最后看“哪些逻辑应该交给持久化层，哪些应该留在业务层”

如果你读完能把一个读取需求描述成下面这种形式，本章就达标：

- 读取哪个列表里的待办
- 只要未完成还是全部
- 按什么顺序返回
- 删除列表时，待办应该跟着删还是回到未归类

## 先立一条总则：持久化层只做它听得懂的事

SwiftData 很适合处理结构化条件和稳定排序，但它不是 Swift 运行时，也不是你的全部业务逻辑。

所以这章先立一条非常实用的总则：

- 能被持久化层稳定表达的条件和排序，就放进查询描述里
- 不能稳定表达的复杂业务规则，就留在内存或业务层处理

这个判断会反复出现：

- “只读未完成待办”适合放进查询
- “按复杂相关度打分排序”通常不该一股脑塞进持久化层
- “删除列表后待办怎么办”必须先决定产品语义，再写关系规则

## 1. 查询：用 predicate 把“读哪些数据”说清楚

在真实开发里，最常见的读取错误不是“语法写错”，而是：

- 本来只需要读一小部分数据，却先把全部数据读出来，再在内存里随手过滤

当数据量还小时，这样写似乎也能跑；但一旦需求变多，可维护性会迅速变差。

所以这一章只主讲一条读取路径：

- 用 `#Predicate` 表达条件
- 用 `FetchDescriptor` 把条件和排序包起来
- 用 `ModelContext.fetch(_:)` 真正取数据

### 当前场景里的模型长什么样

```swift
import SwiftData

@Model
final class TodoList {
    var name: String

    @Relationship(deleteRule: .nullify, inverse: \TodoItem.list)
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
    var createdAt: Date
    var updatedAt: Date
    var list: TodoList?

    init(
        title: String,
        isDone: Bool = false,
        priority: Int = 0,
        createdAt: Date = .now,
        updatedAt: Date = .now,
        list: TodoList? = nil
    ) {
        self.title = title
        self.isDone = isDone
        self.priority = priority
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.list = list
    }
}
```

这里先不急着讨论关系写法细节，你只要先抓住两个事实：

- 现在待办已经可以属于某个列表
- 删除列表时，系统会按我们定义的规则处理关联待办

类型补充：

- `@Relationship(deleteRule:inverse:)`：声明模型之间的关系，并指定删除时如何处理关联对象
- `deleteRule: .nullify`：删除 `TodoList` 时，不删除关联 `TodoItem`，而是把它们的 `list` 设为 `nil`
- `inverse: \TodoItem.list`：指出这段关系在另一侧对应的是 `TodoItem` 的 `list` 属性
- `TodoList.items`：父对象视角的一对多关系
- `TodoItem.list`：子对象视角的“属于哪个列表”

### 一个最常见的读取需求

“读出 `Today` 列表里所有未完成的待办”。

对应的查询描述可以写成：

```swift
func fetchUndoneTodos(in listName: String, context: ModelContext) throws -> [TodoItem] {
    let predicate = #Predicate<TodoItem> { item in
        item.isDone == false && item.list?.name == listName
    }

    let descriptor = FetchDescriptor<TodoItem>(predicate: predicate)
    return try context.fetch(descriptor)
}
```

从开发角度看，这段代码最重要的不是形式，而是职责分离：

- predicate 决定“读哪些”
- fetch 决定“现在去拿结果”

函数声明：

```swift
func fetchUndoneTodos(in listName: String, context: ModelContext) throws -> [TodoItem]
```

参数：

- `listName`：要读取的列表名称，例如 `Today`
- `context`：执行查询的 `ModelContext`

返回值：

- `[TodoItem]`：指定列表下所有未完成待办

作用：

- 读取指定列表下所有未完成待办

这能带来的实际价值是：

- 读取需求更清楚
- 代码更容易集中到存储层
- 后面改动条件时，不会在一堆列表处理逻辑里到处找过滤代码

### 查询边界：什么不要急着塞进 predicate

一旦你习惯了条件读取，很容易产生另一个误区：

- 把所有业务判断都往 predicate 里塞

这通常会让问题变糟。下面这些情况就应该先停一下：

- 依赖复杂文本匹配、本地化或打分逻辑
- 依赖外部状态，例如网络、权限、远端开关
- 依赖你自定义函数或复杂控制流

更稳的做法通常是两段式：

1. 先让持久化层完成粗筛，例如“某列表下未完成的待办”
2. 再对较小结果集做内存内的精加工

这不是妥协，而是职责边界。

## 2. 排序：让列表顺序稳定、可解释

很多列表问题本质上不是“数据没读到”，而是“返回顺序不稳定”。

在待办场景里，最自然的需求往往是：

- 高优先级的待办排前面
- 同优先级时，较早创建的先显示

这种需求不应该留到 UI 层“看着不顺再补一把排序”，因为它本质上是读取结果的一部分。

### 把排序写进查询描述

```swift
func fetchUndoneTodosSorted(in listName: String, context: ModelContext) throws -> [TodoItem] {
    let predicate = #Predicate<TodoItem> { item in
        item.isDone == false && item.list?.name == listName
    }

    let descriptor = FetchDescriptor<TodoItem>(
        predicate: predicate,
        sortBy: [
            SortDescriptor(\TodoItem.priority, order: .reverse),
            SortDescriptor(\TodoItem.createdAt, order: .forward)
        ]
    )

    return try context.fetch(descriptor)
}
```

这里的工程意义非常直接：

- `priority` 决定主要先后顺序
- `createdAt` 作为第二排序键，保证同优先级时列表仍然稳定

函数声明：

```swift
func fetchUndoneTodosSorted(in listName: String, context: ModelContext) throws -> [TodoItem]
```

参数：

- `listName`：目标列表名称
- `context`：执行查询的 `ModelContext`

返回值：

- `[TodoItem]`：指定列表下未完成待办的稳定排序结果

作用：

- 读取指定列表下未完成待办，并按优先级和创建时间返回稳定排序结果

如果你少了第二排序键，列表看起来就可能“抖动”。这不是 UI 小毛病，而是读取规则没定义完整。

### 排序边界：不要指望持久化层理解你的运行时计算

有些排序规则其实不适合交给持久化层，例如：

- 根据复杂文本相关度排序
- 根据多个运行时状态综合打分排序
- 根据本地化展示结果排序

这些规则通常更适合：

1. 先用 predicate 把结果集缩小
2. 再在内存里做复杂排序

所以排序问题不是“能不能写”，而是“这条排序规则到底属于数据读取，还是属于业务/展示计算”。

## 3. 关系：待办属于哪个列表，不再是“额外字段”那么简单

一旦进入一对多关系，复杂度的来源通常不是“多了一个属性”，而是：

- 父对象和子对象如何一起演化
- 查询时你到底是在查父还是查子
- 删除时关联对象如何处理

在当前场景里：

- `TodoList` 是父对象
- `TodoItem` 是子对象

### 关系带来的第一个变化：查询开始依赖上下文

以前你读“所有待办”就够了；现在你要读的是：

- 某个列表下的待办
- 未归类待办
- 某个列表下未完成且高优先级的待办

例如读取未归类待办：

```swift
func fetchInboxTodos(context: ModelContext) throws -> [TodoItem] {
    let predicate = #Predicate<TodoItem> { item in
        item.list == nil
    }

    let descriptor = FetchDescriptor<TodoItem>(
        predicate: predicate,
        sortBy: [SortDescriptor(\TodoItem.createdAt, order: .forward)]
    )

    return try context.fetch(descriptor)
}
```

你应该从这里建立一个很重要的开发意识：

- 关系一出现，读取需求就不再只是“取全部数据”
- 它会直接影响你的存储接口长什么样

函数声明：

```swift
func fetchInboxTodos(context: ModelContext) throws -> [TodoItem]
```

参数：

- `context`：执行查询的 `ModelContext`

返回值：

- `[TodoItem]`：所有未归类待办，也就是 `list == nil` 的待办

作用：

- 读取所有未归类待办

### 关系带来的第二个变化：删除不再是“顺手删掉父对象”

真正麻烦的地方在这里。

如果删掉一个 `TodoList`，对应的 `TodoItem` 到底怎么办？这不是 API 选择题，而是产品语义问题。

在当前教程里，我们把 demo 默认策略设成 `nullify`：

- 删掉列表
- 待办项不删除
- 这些待办回到“未归类”状态

为什么这里选 `nullify`？因为这个场景里，待办项本身通常仍然有意义。

用户删掉的是“分类方式”，不一定是“任务本身”。

### 三种最常见删除语义

你至少要能说清下面三种：

- `cascade`：删父就删子。适合“子对象没有独立意义”的场景。
- `nullify`：删父不删子，但把关系置空。适合“子对象仍有独立意义”的场景。
- `deny`：父对象还有子对象时不允许删除。适合“必须先清理子对象”的场景。

这三种没有绝对正确，只有是否符合当前产品语义。

教程里更重要的结论是：

- 不要把删除语义交给模糊的默认直觉
- 先明确业务，再写关系规则

## 4. 把查询、排序、关系串起来：一个真实读取需求长什么样

到这里，你就可以把“我要读待办列表”这种模糊需求，升级成更完整的描述：

- 我要读哪个列表里的待办
- 我要全部还是只要未完成
- 我要按优先级还是按创建时间排序
- 如果列表被删掉，这些待办是否仍然应该可见

你会发现，这些信息已经非常接近一个真实存储接口了。例如：

```swift
func fetchTodos(
    in listName: String?,
    onlyUndone: Bool,
    context: ModelContext
) throws -> [TodoItem]
```

本章不急着把它抽成协议，但你已经该看到一个很实际的工程信号：

- 当读取需求越来越具体，存储层接口也必须开始变得明确

## 5. 持久化边界：哪些问题交给 SwiftData，哪些不要硬塞

SwiftData 很适合处理下面这类本地数据问题：

- 数据会长期存在
- 数据会持续增长
- 需要稳定查询和排序
- 存在明确关系和删除影响

在当前待办场景里，下面这些就很适合继续交给 SwiftData：

- 读取某个列表下未完成的待办
- 按优先级与时间排序
- 维护列表与待办之间的关系
- 在删除列表时落实既定语义

但下面这些问题就不必一股脑压给持久化层：

- 复杂搜索打分
- 强依赖 UI 展示的临时排序
- 完全依赖远端实时状态的业务判断
- 只是一份偶尔落盘的快照结果

所以本章真正想教会你的边界判断是：

- SwiftData 不是所有本地数据问题的默认答案
- 但一旦需求进入“结构化读取 + 关系一致性”，它就比文件快照更适合承担主角

## Demo 里你应该看到什么

第 45 章 demo 会用终端直接演示四件事：

1. 读取某个列表下未完成的待办
2. 用两级排序返回稳定结果
3. 读取未归类待办
4. 删除一个列表后，待办因为 `nullify` 重新变成未归类

你应该重点观察的是“结果为什么会这样”，而不是只看 API 有没有跑通。

如果你能解释每一轮输出背后的读取规则和删除语义，本章就达到了目标。

## 现在终于有必要抽象存储层了

到这一章，你已经把问题推进到了：

- 查询条件越来越具体
- 排序规则越来越明确
- 关系和删除语义越来越重要

到这一步，存储层已经不再只是几个零散函数，而是开始承载真正的业务需求描述。

- 当存储需求已经足够真实时，如何把它整理成可替换、可测试、可维护的接口

## 边界说明

为了让主题保持集中，本章明确不做这些事：

- 不讲 SwiftUI 的 `@Query` 绑定
- 不讲迁移、CloudKit、同步冲突
- 不讲大数据量性能优化和索引策略
- 不讲多上下文高级并发组织
- 不讲复杂全文检索与搜索引擎式需求

这些内容都很重要，但它们已经超出了“结构化读取与关系一致性”的入门范围。
