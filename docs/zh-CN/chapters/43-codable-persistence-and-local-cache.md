# 43. 本地快照缓存：Codable、文件落盘与恢复路径

## 阅读导航

- 前置章节：[34. JSON 格式与解析](./34-json-format-and-parsing.md)、[35. JSON 进阶：字段映射与复杂结构](./35-json-advanced-field-mapping-and-nested-structures.md)、[42. 文件与目录：FileManager、URL 与本地读写](./42-filemanager-url-and-local-file-io.md)
- 上一章：[42. 文件与目录：FileManager、URL 与本地读写](./42-filemanager-url-and-local-file-io.md)
- 建议下一章：[44. 从快照到记录：SwiftData 最小持久化闭环](./44-swiftdata-basics-model-container-context-and-crud.md)
- 下一章：[44. 从快照到记录：SwiftData 最小持久化闭环](./44-swiftdata-basics-model-container-context-and-crud.md)
- 适合谁先读：已经能完成基础网络请求、会用 `Codable` 解码 JSON、也掌握了文件读写；现在想把“上一次成功结果保留下来”的读者

## 本章目标

学完这一章后，你应该能够：

- 说清“本地快照缓存”在实际开发中的作用：减少重复请求、保留上次结果、提供最小离线兜底
- 写出一条最小缓存链路：`远程 -> DTO -> 领域快照 -> JSON 编码 -> 文件落盘 -> 读回 -> 解码`
- 明确区分三种缓存状态：命中、缺失、损坏
- 理解为什么这类方案更像“保存一份结果快照”，而不是“管理可查询、可局部更新的数据”
- 建立一个朴素判断：当需求还是“保存上次结果”时，文件快照通常已经够用

## 本章定位：先解决“把上次结果留住”

这一章只解决一个很常见、也很实际的问题：

- 远程接口已经拿到了一份待办列表，下一次启动应用时，能不能先把上次成功结果读出来？

这类需求在真实开发里很常见：

- 首页列表希望更快出现内容
- 网络失败时希望仍然展示上次成功结果
- 某些只读数据没有必要每次都重新请求

先把边界卡住：本章讲的是**快照缓存**，不是数据库。

所谓快照缓存，意思是：

- 你保存的是“某个时刻的一整份结果”
- 你读回来时，通常也是“整份读回”
- 你修改其中一条记录时，往往还是要重写整份文件

如果你的数据目前就是这种形态，那文件缓存已经够用，而且实现成本最低。

## 统一场景：缓存远程返回的待办列表

从这一章开始到第 45 章，我们统一使用同一个场景：待办应用。

这一章里的需求最简单：

1. 远程接口返回一份待办列表
2. 应用把它保存到本地 JSON 文件
3. 下一次启动时优先读取本地文件
4. 如果缓存损坏，就删除坏文件并重新走远程

先看这个需求的工程判断：

- 数据来源仍然以远程为主
- 本地只是为了“保存上次成功结果”
- 你不会在本章里本地新增一条待办，也不会单独修改某一条待办

这就是为什么本章适合文件缓存：它足够直接，也足够符合当前需求。

## 本章怎么读

建议按下面顺序读：

1. 先看“缓存解决什么问题，不解决什么问题”
2. 再看最小链路里每一段的职责：编码、落盘、读回、解码
3. 然后看调用端如何区分命中、缺失、损坏三种状态
4. 最后判断：什么时候文件快照已经不够，需求开始接近“本地数据管理”

如果你读完能独立写出这三个函数，说明你已经理解了本章的内容：

- `loadSnapshot()`：从文件读快照
- `saveSnapshot()`：把快照写回文件
- `getTodos()`：先读缓存，必要时走远程，并在成功后回写缓存

## 为什么这里先用文件快照

如果你现在的需求只是“把一份远程结果保留下来”，文件快照往往已经足够直接。

因为这一章的数据特点是：

- 读多，改少，甚至几乎不改
- 基本以整份列表形式出现
- 需要的是简单恢复路径，而不是复杂查询

所以本章要建立的是一个很朴素的判断标准：

- 只是保存上次结果：文件快照通常够用
- 需要频繁改单条、查局部、长期维护：文件快照会越来越吃力

## 先把类型边界说清楚

为了让当前链路里的职责更清楚，这里先把三类类型分开。

### 1. 远程 DTO：服从接口返回

```swift
struct TodoDTO: Decodable {
    let id: Int
    let title: String
    let completed: Bool
}
```

DTO 的第一职责是“把接口返回解出来”。它的结构首先服从后端，不一定适合直接落盘，更不一定适合直接拿来做业务。

### 2. 本地快照：服从当前应用要保存什么

```swift
struct TodoSnapshot: Codable, Equatable {
    let id: Int
    let title: String
    let isDone: Bool

    init(dto: TodoDTO) {
        self.id = dto.id
        self.title = dto.title
        self.isDone = dto.completed
    }
}
```

这里把 `completed` 映射成 `isDone`，是为了强调一件事：

- 本地保存格式是你自己定义的
- 它可以更贴近当前应用的表达方式
- 它不必和接口 DTO 一模一样

### 3. 缓存外壳：服从缓存文件需要哪些元信息

```swift
struct CacheEnvelope<Value: Codable>: Codable {
    let cachedAt: Date
    let value: Value
}
```

之所以多这一层，是因为缓存文件通常不只保存数据本体，还会顺手带上一些元信息，例如：

- 写入时间
- 版本号
- 来源

本章只用 `cachedAt`，已经够说明快照文件本身也是你定义的格式。

## 最小缓存链路：编码、落盘、读回、解码

我们要跑通的链路很简单：

```text
远程 JSON
-> TodoDTO
-> TodoSnapshot
-> JSONEncoder.encode
-> 文件写入
-> 文件读取
-> JSONDecoder.decode
-> CacheEnvelope<[TodoSnapshot]>
```

这里重要的不是 API 名字，而是下面这些失败点：

- 编码可能失败
- 写文件可能失败
- 读文件可能失败
- 解码可能失败
- 文件不存在不是错误，而是缓存缺失

### 1. 设计缓存文件地址

```swift
enum AppPaths {
    static func cacheFileURL(fileName: String) throws -> URL {
        let fm = FileManager.default
        let base = try fm.url(
            for: .cachesDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )

        let folder = base
            .appendingPathComponent("learn-swift", isDirectory: true)
            .appendingPathComponent("43-cache-demo", isDirectory: true)

        try fm.createDirectory(at: folder, withIntermediateDirectories: true)
        return folder.appendingPathComponent(fileName)
    }
}
```

这里用 `Caches` 而不是 `Documents`，是为了明确表达：

- 这不是用户主动管理的文档
- 这是应用为了性能和兜底保存的临时性结果

这里只多看一个参数：

- `fileName`：缓存文件名，例如 `todos.json`

这段代码的作用是统一决定缓存写入位置，避免在业务代码里到处拼接路径。

### 2. 保存快照：编码 + 原子写入

```swift
enum CacheWriteError: Error {
    case encodeFailed(underlying: Error)
    case writeFailed(underlying: Error)
}

func saveSnapshot<T: Encodable>(_ value: T, to fileURL: URL) throws {
    do {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(value)
        try data.write(to: fileURL, options: [.atomic])
    } catch let error as EncodingError {
        throw CacheWriteError.encodeFailed(underlying: error)
    } catch {
        throw CacheWriteError.writeFailed(underlying: error)
    }
}
```

这里打开 `.prettyPrinted` 和 `.sortedKeys`，是为了让教学阶段更容易直接打开文件看内容，而不是为了性能。

这里真正需要看的参数有两个：

- `value`：要保存的数据，要求遵守 `Encodable`
- `fileURL`：目标文件位置

这段代码的作用是把内存中的快照编码成 JSON，并原子写入磁盘。

### 3. 读取快照：缺失是 `nil`，损坏是错误

```swift
enum CacheReadError: Error {
    case readFailed(underlying: Error)
    case decodeFailed(underlying: Error)
}

func loadSnapshot<T: Decodable>(_ type: T.Type, from fileURL: URL) throws -> T? {
    do {
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            return nil
        }

        let data = try Data(contentsOf: fileURL)
        return try JSONDecoder().decode(T.self, from: data)
    } catch let error as DecodingError {
        throw CacheReadError.decodeFailed(underlying: error)
    } catch {
        throw CacheReadError.readFailed(underlying: error)
    }
}
```

这个函数最重要的地方在于它把两件事分开了：

- 文件不存在：缓存缺失
- 文件存在但读/解码失败：缓存损坏或不兼容

参数里真正决定读取结果的有两个：

- `type`：想读回来的目标类型，例如 `CacheEnvelope<[TodoSnapshot]>.self`
- `fileURL`：缓存文件位置

这段代码的作用是把“有没有缓存”和“缓存能不能读”清楚地区分开。

实际开发里，这两个状态的处理完全不同，不能混成一句“读取失败”。

## 三种缓存状态：命中、缺失、损坏

把状态显式写出来，调用端会清楚很多：

```swift
enum CacheLoadResult<Value> {
    case hit(Value)
    case miss
    case corrupted(underlying: Error)
}

func loadCacheOrReportCorruption<T: Decodable>(
    _ type: T.Type,
    from fileURL: URL
) -> CacheLoadResult<T> {
    do {
        if let value = try loadSnapshot(T.self, from: fileURL) {
            return .hit(value)
        }
        return .miss
    } catch {
        return .corrupted(underlying: error)
    }
}
```

这不是为了把代码写得“更讲究”，而是为了让业务分支更清楚：

- `.hit`：直接用缓存
- `.miss`：走远程
- `.corrupted`：先恢复，再走远程

参数仍然是这两个：

- `type`：缓存文件里预期保存的数据类型
- `fileURL`：缓存文件位置

这段代码的作用是把底层的 `nil / throw / value` 三种结果规范成命中、缺失、损坏三种业务分支。

### 损坏时的最小恢复路径

```swift
func deleteFileIfExists(_ url: URL) {
    do {
        if FileManager.default.fileExists(atPath: url.path) {
            try FileManager.default.removeItem(at: url)
        }
    } catch {
        print("[warn] 删除缓存失败：\(error)")
    }
}
```

这一章故意采用最朴素的恢复策略：

- 删掉坏文件
- 重新请求远程
- 用新结果覆盖回去

这里只需要看一个参数：

- `url`：要删除的文件路径

这段代码的作用是在检测到缓存损坏时执行最小恢复动作。

这样写的好处是恢复路径简单，也方便观察。

## 把缓存接进真实的数据获取函数

下面给一份正文内可独立阅读的最小主流程。为了避免把注意力带偏，这里只给一个最小远程来源占位类型：

```swift
struct FakeRemoteAPI {
    func fetchTodos() async throws -> [TodoDTO] {
        [
            TodoDTO(id: 1, title: "复习 Codable 缓存链路", completed: false),
            TodoDTO(id: 2, title: "验证缓存损坏恢复路径", completed: true)
        ]
    }
}

enum DataSource<Value> {
    case cache(Value)
    case remote(Value)
}

func getTodos(api: FakeRemoteAPI) async throws -> DataSource<[TodoSnapshot]> {
    let cacheURL = try AppPaths.cacheFileURL(fileName: "todos.json")

    switch loadCacheOrReportCorruption(CacheEnvelope<[TodoSnapshot]>.self, from: cacheURL) {
    case .hit(let envelope):
        print("缓存命中：读取上次成功快照，cachedAt = \(envelope.cachedAt)")
        return .cache(envelope.value)

    case .miss:
        print("缓存缺失：本地没有快照，准备走远程")

    case .corrupted(let error):
        print("缓存损坏：\(error)")
        print("执行恢复：删除坏文件，再重新请求远程")
        deleteFileIfExists(cacheURL)
    }

    let dtos = try await api.fetchTodos()
    let snapshots = dtos.map(TodoSnapshot.init(dto:))

    do {
        let envelope = CacheEnvelope(cachedAt: Date(), value: snapshots)
        try saveSnapshot(envelope, to: cacheURL)
        print("远程成功：已把最新待办快照写回缓存")
    } catch {
        print("[warn] 回写缓存失败，但不影响主流程：\(error)")
    }

    return .remote(snapshots)
}
```

这里有两个很关键的工程判断：

- 缓存读取失败需要恢复，因为坏缓存会持续污染后续读取
- 缓存写回失败不应阻断主流程，因为缓存只是优化，不是真理来源

这里只需要额外说明一个参数：

- `api`：远程数据来源；这里先用一个最小 `FakeRemoteAPI` 占位，好让正文主流程能独立阅读

这段代码的作用是把“先查缓存，不行再查远程，并在成功后回写缓存”这条主流程收口到一个函数里。返回值用 `DataSource` 标记这次结果来自缓存还是远程。

这里第一次出现两个关键类型：

- `CacheEnvelope<Value>`：缓存文件的外壳，除了真正的数据，还保存 `cachedAt`
- `DataSource<Value>`：结果来源标记，用来区分这次展示的是缓存还是远程数据

这就是本章最核心的开发视角：

- 快照缓存的价值在于“兜底”和“提速”
- 但它不应该反过来绑架主流程

## Demo 里你应该看到什么

本章配套 demo 会固定演示三轮：

1. 第一次运行：缓存缺失，走远程，写入缓存
2. 第二次运行：缓存命中，直接返回本地快照
3. 手动写坏文件后：识别损坏，删掉旧文件，重新请求并回写

如果你能清楚解释这三轮分别在模拟什么真实场景，本章就已经进入开发视角了。

## 本章的边界：为什么它还不是“本地数据管理”

到这里，你已经能保存并恢复一份待办列表快照。但你也应该开始看到它的限制：

- 你拿到的是整份列表，而不是一条条可管理记录
- 你很难只更新某一条待办而不重写整个文件
- 你很难自然表达“只读未完成的待办”这类局部读取需求
- 你也还没有关系概念，例如“待办属于哪个列表”

换句话说，本章适合解决的是：

- 保存上次结果
- 读取上次结果
- 缓存损坏后的恢复

它不适合长期承载的是：

- 用户在本地持续编辑的数据
- 单条记录的增删改
- 基于条件的结构化读取
- 对象之间的关系与一致性

## 从“快照”到“记录”：你会在这里看到边界

如果需求进一步升级一步：

- 待办不再只是远程返回的一份快照
- 用户会在本地新增待办
- 用户会修改某一条待办的完成状态
- 用户会删除某一条待办
- 应用重启后，这些本地修改仍然要保留下来

一旦需求变成这样，文件快照的代价就会迅速升高，因为你已经不是在“保存上次结果”，而是在“管理一条条本地记录”。

这时，文件快照就不再顺手了。你需要的是：

- 让本地数据更像一组可管理对象
- 让增删改查围绕记录展开
- 让持久化开始服务于长期维护的数据，而不只是缓存一份结果

## 边界说明

为了让主线保持清楚，本章明确不做这些事：

- 不展开缓存过期策略大全（TTL、后台刷新、分层缓存）
- 不讲离线编辑与同步冲突
- 不讲复杂查询、关系、增量更新
- 不讲把文件缓存做成“伪数据库”

这些内容不是不重要，而是它们会把“快照缓存”这个主题冲散。
