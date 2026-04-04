# 46. 语言进阶：协议抽象、依赖注入与可测试设计

## 阅读导航

- 前置章节：[21. 协议：灵活抽象的第一步](./21-protocols-flexible-abstraction.md)、[24. 泛型：让同一套逻辑适配更多类型](./24-generics-reusable-abstractions.md)、[39. 网络层分层与错误建模](./39-network-layer-architecture-and-error-modeling.md)、[45. 结构化读取与关系一致性：筛选、排序、列表与删除规则](./45-swiftdata-advanced-query-sort-relationships-and-boundaries.md)
- 上一章：[45. 结构化读取与关系一致性：筛选、排序、列表与删除规则](./45-swiftdata-advanced-query-sort-relationships-and-boundaries.md)
- 建议下一章：[47. 工程化第一步：多文件协作、类型边界与项目拆分](./47-multi-file-project-organization-and-cross-file-collaboration.md)
- 下一章：[47. 工程化第一步：多文件协作、类型边界与项目拆分](./47-multi-file-project-organization-and-cross-file-collaboration.md)
- 适合谁先读：已经写过“能跑起来的网络请求/缓存/持久化代码”，但开始觉得它们难以复用、难以替换、难以测试的读者

## 本章目标

学完这一章后，你应该能够：

- 用一句话解释“协议抽象”和“依赖注入”在工程里的真实目的：**把依赖变成可替换的**，从而让代码更容易测试、维护和演进。
- 在网络层、缓存层、本地持久化（含 SwiftData）这些“带副作用的依赖”上，画出一条清晰边界：业务逻辑依赖协议，不依赖具体实现。
- 写出一个最小可用的依赖注入方式（初始化注入 / 参数注入），并明确本章**不引入** DI 框架。
- 用替身实现（stub / fake / spy）在不访问网络、不落盘、不触碰真实数据库的情况下，验证你的业务逻辑分支。
- 判断什么时候值得抽象、什么时候不值得抽象，避免“为了抽象而抽象”的过度设计。

本章还是用“控制台 + 最小业务链路”的方式展开，尽量不让 UI 把讨论带偏。

本章会把前几章出现过的网络、快照缓存、SwiftData 记录存储与结构化读取这些素材，整理成“可替换依赖”的形式，帮助你为后续测试与维护打基础。

## 本章怎么读

这一章可以分三遍读：

1. 第一遍只抓结论：理解“为什么要抽象依赖”，以及“注入依赖后，代码会发生什么变化”。
2. 第二遍跟着代码形状看：协议怎么设计、注入点放哪里、替身实现怎么写。
3. 第三遍回到工程实践：对照“何时值得抽象/何时不值得抽象”，检查自己是不是在过度设计。

如果你读完仍不确定“值不值得抽象”，先记住一个足够实用的判断问题：

- 当你需要验证某段逻辑时，你是否必须真的去访问网络、真的去写文件、真的去读数据库？

如果答案是“是”，那你大概率已经走到本章要解决的问题前面了。

## 正文主体

### 模块 0：开场定位

第 21 章讲过协议语法，第 24 章也讲过泛型复用。到了第 46 章，为什么还要再回来看“协议”？

因为前几章已经开始碰到真实工程里最常见的三类依赖：

- 网络：请求成功与否受网络环境影响，失败路径复杂，速度不可控。
- 文件缓存：读写路径、权限、磁盘状态会影响行为；并且“测试里不想真的落盘”。
- 持久化（SwiftData / 其他存储）：它们通常有上下文、线程/并发约束，以及“测试隔离”的问题。

这些依赖有一个共同点：它们都带副作用，而且它们都可能需要被替换。替换的理由包括：

- 运行环境不同：真机/模拟器、开发/生产、离线/在线。
- 需求变化：从文件缓存迁移到数据库，从 REST 迁移到 GraphQL，从本地持久化迁移到云同步。
- 更关键的一点：**测试需要可控性**。测试最怕“慢、脆、不确定”。

这一章不是协议语法复习，也不是架构名词大全。它只处理一件事：把这些可替换的依赖从业务逻辑里剥开，让代码更容易测试，也更容易改。

### 模块 1：为什么要抽象依赖

先看一段在学习阶段非常常见的代码形状：把网络、缓存、持久化全写在一个服务里。它能跑，但会很快变得难维护、难测试。

```swift
import Foundation

// 仅用于演示问题：刻意把依赖写死在实现里
final class ArticleService {
    func refresh() async throws -> [String] {
        let url = URL(string: "https://example.com/articles")!
        let (data, _) = try await URLSession.shared.data(from: url)
        let articles = try JSONDecoder().decode([String].self, from: data)

        // 这里“顺手”加一个缓存落盘
        let cacheURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("articles.json")
        try data.write(to: cacheURL, options: .atomic)

        // 这里“顺手”再加一个持久化（伪代码：具体类型取决于你的 SwiftData 模型）
        // modelContext.insert(...)
        // try modelContext.save()

        return articles
    }
}
```

这里故意把依赖写死，是为了暴露耦合问题。文中的这些系统接口如果你想回看基础说明，可以直接回前面章节：

- `URLSession.shared.data(from:)`
  - 见 [第 `38` 章 `URLSession.shared.data(from:)` 的基础说明](./38-urlsession-get-and-post-json.md#urlsession-shared-data-from-basics) 和 [第 `39` 章网络层主线](./39-network-layer-architecture-and-error-modeling.md#network-client-send-mainline)
- `JSONDecoder().decode`
  - 见 [第 `39` 章网络层主线](./39-network-layer-architecture-and-error-modeling.md#network-client-send-mainline) 和 [第 `43` 章“读取快照：缺失是 `nil`，损坏是错误”](./43-codable-persistence-and-local-cache.md#jsondecoder-decode-cache)
- `FileManager.default.temporaryDirectory`
  - 见 [第 `42` 章 `temporaryDirectory` 说明](./42-filemanager-url-and-local-file-io.md#filemanager-temporary-directory)
- `.appendingPathComponent(...)`
  - 见 [第 `42` 章 URL 路径拼接说明](./42-filemanager-url-and-local-file-io.md#url-appending-path-component)
- `JSONEncoder().encode`
  - 见 [第 `43` 章“保存快照：编码 + 原子写入”](./43-codable-persistence-and-local-cache.md#jsonencoder-encode-cache)

这段代码的问题不是“写法不 Swift”，而是**耦合方式会让你很难做以下事情**：

- 想测试“当网络失败时是否回退到缓存”：你得真的断网或者构造复杂的网络失败；并且测试要读写真实文件。
- 想测试“缓存命中时不发请求”：你无法观察 `URLSession.shared` 是否被调用，除非你引入更复杂的 hook。
- 想在不同环境替换实现：例如预览用本地 JSON，线上用网络；你只能写 `if DEBUG` 或在函数里塞一堆开关。

更直接地说，依赖一旦写死，业务逻辑就只能跟着真实环境一起跑；而测试需要的是可控的环境和可观察的行为。

所以这里的抽象目标很明确：

- 可替换：同一份业务逻辑，可以替换不同实现（真网络 / 假网络，真落盘 / 内存缓存，真数据库 / 内存存储）。
- 可测试：可以用替身实现稳定地覆盖逻辑分支。
- 可维护：把变化快、失败多、细节多的部分放在边界之外，业务代码更干净。

### 模块 2：协议抽象

协议抽象最常见的坑，是一上来就想写一个“万能协议”。~~(啥都做成协议等于没写)~~ 这一章走相反方向：**协议越小越好，职责越清楚越好**。

一个实用的原则是：协议由使用方定义，它只表达使用方真正需要什么能力。举例来说，如果你的业务只需要“发请求得到 Data”，那协议就不要一上来定义“拦截器、重试、日志、缓存策略”等等。

下面给出三个最小协议边界，用来代表“远程数据源 / 缓存 / 持久化”三类可替换依赖。这里刻意**不重新定义第 39 章的 `NetworkClient` 主线契约**，而是把它包在更贴近业务的远程数据源边界后面：

```swift
import Foundation

protocol ArticleRemoteSource {
    func fetchArticles() async throws -> [String]
}

protocol CacheStore {
    func read(key: String) throws -> Data?
    func write(key: String, data: Data) throws
    func remove(key: String) throws
}

// 这里的“持久化”不限定 SwiftData，也不限定表结构。
// 关键是：业务只依赖它提供的最小能力。
protocol ArticleStore {
    func loadAll() throws -> [String]
    func replaceAll(with articles: [String]) throws
}
```

这里补几句说明：

- `ArticleRemoteSource` 是“使用方定义协议”的例子：`ArticleService` 只需要“拿到文章列表”，它不需要知道底层到底是第 39 章的 `NetworkClient`、别的 HTTP 客户端，还是本地假数据。
- `CacheStore` 的 key 用 `String` 只是便于示例。真实项目里你可能用 `enum CacheKey` 或更强类型，避免 key 拼错。
- `ArticleStore` 的存取接口刻意偏业务，而不是“通用数据库”。原因是：通用数据库抽象往往会把复杂度带回业务层。

这一步做的事情其实很朴素：**把不可控的世界（网络/磁盘/数据库）包起来，让业务只面对一个可控接口**。

### 模块 3：依赖注入

有了协议，还差最后一步：让业务代码拿到“实现”，但不把实现写死。这就是依赖注入（Dependency Injection, DI）。

依赖注入听起来很大，其实先记一句话就够了：

- 不在类型内部创建依赖，而是从外部把依赖传进来。

最常用、也最省事的做法是**初始化注入**：

```swift
import Foundation

final class ArticleService {
    private let remote: ArticleRemoteSource
    private let cache: CacheStore
    private let store: ArticleStore

    init(remote: ArticleRemoteSource, cache: CacheStore, store: ArticleStore) {
        self.remote = remote
        self.cache = cache
        self.store = store
    }

    private enum CacheLoadResult<Value> {
        case hit(Value)
        case miss
        case corrupted(underlying: Error)
    }

    private func loadCachedArticles() -> CacheLoadResult<[String]> {
        do {
            guard let data = try cache.read(key: "articles.json") else {
                return .miss
            }

            let articles = try JSONDecoder().decode([String].self, from: data)
            return .hit(articles)
        } catch {
            return .corrupted(underlying: error)
        }
    }

    func refresh() async throws -> [String] {
        let articles: [String]

        do {
            articles = try await remote.fetchArticles()
        } catch {
            let remoteError = error

            switch loadCachedArticles() {
            case .hit(let articles):
                return articles
            case .miss:
                throw remoteError
            case .corrupted:
                try? cache.remove(key: "articles.json")
                throw remoteError
            }
        }

        let data = try JSONEncoder().encode(articles)

        do {
            try cache.write(key: "articles.json", data: data)
        } catch {
            // 缓存写入失败不应覆盖远程成功结果；真实业务里可记录日志或上报。
        }

        try store.replaceAll(with: articles)
        return articles
    }
}
```

这段代码重点不在“缓存策略是否完美”，而在两件事：

- 业务逻辑从此不再直接依赖 `URLSession.shared`、`FileManager.default` 或某个具体数据库上下文。
- 缓存回退仍然沿用了第 43 章已经建立的边界：缓存命中、缓存缺失、缓存损坏是三种不同状态；坏缓存要清掉，而不是把新的缓存错误覆盖原始远程错误。

这一章不引入 DI 框架，理由也很简单：

- 在学习阶段，引入框架会把注意力从“边界在哪里、注入点在哪里”转移到“框架怎么配”。
- 多数项目里最难的不是“怎么注入”，而是“注入什么、注入到哪里、协议该怎么划分”。

你只需要知道：**注入发生在组合处（composition root）**，通常是程序启动入口或上层模块，而不是在每个业务类型内部。

### 模块 4：实现替换（真实实现 vs 替身实现）

有了协议之后，接下来要做两类实现：

- 真实实现：用于产品运行（例如 `URLSession` 网络实现、文件缓存实现、SwiftData 存储实现）。
- 替身实现：用于测试或预览（例如 stub/fake/spy）。

下面给一组直观的实现示例，细节故意压得比较少：

```swift
import Foundation

struct LiveArticleRemoteSource: ArticleRemoteSource {
    let client: NetworkClient

    func fetchArticles() async throws -> [String] {
        // `.articleTitles()` 代表你在第 39 章那套网络层里定义的具体 endpoint 工厂。
        try await client.send(.articleTitles(), as: [String].self)
    }
}

final class InMemoryCacheStore: CacheStore {
    private var storage: [String: Data] = [:]

    func read(key: String) throws -> Data? { storage[key] }
    func write(key: String, data: Data) throws { storage[key] = data }
    func remove(key: String) throws { storage.removeValue(forKey: key) }
}

final class InMemoryArticleStore: ArticleStore {
    private var articles: [String] = []

    func loadAll() throws -> [String] { articles }
    func replaceAll(with articles: [String]) throws { self.articles = articles }
}
```

注意：上面的 `InMemoryCacheStore` 虽然名字带 cache，但它其实更接近“测试用 fake”。真实的文件缓存实现会涉及目录选择、原子写、错误处理等；这些都应该被隔离在 `CacheStore` 协议实现里，而不是散落在业务逻辑里。

替身实现的价值就在“可控”和“可观察”。常见的有三种，名字不重要，目的才重要：

- stub：返回固定数据，用来驱动分支。
- fake：用更简单的方式实现同样的能力（例如用字典模拟数据库）。
- spy：除了实现能力，还记录调用次数/参数，方便断言“是否发生了某个调用”。

一个最小的 stub/spy 远程数据源可能长这样：

```swift
import Foundation

enum StubError: Error { case any }

final class StubArticleRemoteSource: ArticleRemoteSource {
    enum Mode {
        case success([String])
        case failure(Error)
    }

    var mode: Mode
    private(set) var fetchCallCount: Int = 0

    init(mode: Mode) { self.mode = mode }

    func fetchArticles() async throws -> [String] {
        fetchCallCount += 1
        switch mode {
        case .success(let articles): return articles
        case .failure(let error): throw error
        }
    }
}
```

到这里，“替换实现”是什么意思就很清楚了：`ArticleService` 不用改一行代码，只要换掉注入的依赖，就能在不同环境里运行。

### 模块 5：可测试设计（把可替换落到可验证）

本章目标是实现的可测试性，不是把 XCTest 从头讲一遍，而是把一个更关键的因果关系讲明白：

- 当你的业务逻辑只依赖协议时，你就能用替身实现把测试从“真实世界”解耦出来。

以 `refresh()` 的策略为例：网络失败时尝试读缓存。用替身实现，你可以让测试稳定覆盖这个分支，而不必真的断网或读写文件。

下面是一个偏伪代码的 XCTest 示例（这里用来表达思路，实际工程里你会把它放到测试 target）：

```swift
import XCTest

final class ArticleServiceTests: XCTestCase {
    func test_refresh_fallsBackToCache_whenNetworkFails() async throws {
        let cachedJSON = try JSONEncoder().encode(["a", "b"])

        let remote = StubArticleRemoteSource(mode: .failure(StubError.any))

        let cache = InMemoryCacheStore()
        try cache.write(key: "articles.json", data: cachedJSON)

        let store = InMemoryArticleStore()

        let service = ArticleService(remote: remote, cache: cache, store: store)
        let result = try await service.refresh()

        XCTAssertEqual(result, ["a", "b"])
        XCTAssertEqual(remote.fetchCallCount, 1)
    }
}
```

你可以用这个例子对照一下“写死依赖”的版本：如果 `ArticleService` 内部直接用 `URLSession.shared` 和 `FileManager.default`，你几乎不可能写出这样稳定的测试。

这里再强调一遍：可测试性并不是“为了写测试而写代码”，它更像一个工程信号灯：

- 当你发现“为了测试必须要做很多奇怪的事情”，通常不是测试写得不好，而是依赖边界没有划清楚。

### 模块 6：避免过度设计（什么时候值得抽象，什么时候不值得抽象）

抽象是一把刀，能切开耦合，也能切出复杂度。下面给出一组足够实用的判断准则，你可以在真实工程里直接拿来用。

什么时候值得抽象（更倾向于“是”）：

- 依赖带副作用：网络、磁盘、数据库、时间、随机数、系统环境变量等。
- 依赖不可控或不稳定：慢、易失败、结果不确定，或者你无法在测试里稳定复现。
- 你明确需要替换：至少存在两个实现（例如生产 vs 测试），或者你已经知道很快会出现第二个实现（例如从文件迁移到数据库）。
- 你需要观察行为：例如要断言“是否发了请求/写了缓存/提交了持久化”。

什么时候不值得抽象（更倾向于“否”）：

- 纯函数逻辑：输入确定，输出确定，没有副作用。此时测试本身就很简单，没必要再加协议层。
- 一次性代码或生命周期极短：例如你只是做一个实验脚本，或者某段逻辑不会复用也不会演进。
- 你抽象不出稳定边界：协议里充满“先放着以后可能用”的方法，说明你还不清楚真正的职责。
- 为了“通用”而通用：协议设计成一堆泛型、类型擦除、万能参数，最后调用方更难用，测试也更难写。

一个常用的“止损点”是：**当抽象让你更难写调用代码或更难写测试时，先停下来**。抽象的目的从来不是增加层数，而是减少不必要的耦合。

### 模块 7：阶段收束（把第 39-45 章的素材串起来）

到这里，你已经把前面章节出现的关键能力放到了三个“可替换边界”后面：

- 网络层（第 39 章的分层思路）可以被包在 `ArticleRemoteSource` 这类更贴近业务的边界后面，而不需要在这一章重写它的契约。
- 文件缓存（第 42-43 章的落盘与 Codable）可以通过 `CacheStore` 把“在哪里写、怎么写、失败怎么分”留在边界外。
- SwiftData（第 44-45 章）可以通过 `ArticleStore` 把“具体用 SwiftData 还是别的存储”从业务逻辑里剥离出来。

这会给你带来两个立刻可感知的收益：

- 你可以把“业务策略”写得更像业务，而不是一堆系统调用的拼装。
- 你可以更容易地把“可测性”落地为实际的替身实现，而不是停留在口号。

后续如果本书继续展开测试或更完整的 App 组织方式，你至少已经具备一个共同前提：**代码结构允许你替换依赖**。

## 边界说明

为了避免本章变成“大型架构模式大全”，本章不覆盖以下内容：

- 不引入 DI 框架或容器，不讨论 Service Locator 等更复杂的组织方式。
- 不系统讲解 MVC/MVVM/Clean Architecture 等架构流派；本章只关注语言层面的“协议边界 + 注入点 + 替身实现”。
- 不展开完整的 XCTest 教程。本章只用测试片段说明“可替换依赖如何让测试变得可控”。
