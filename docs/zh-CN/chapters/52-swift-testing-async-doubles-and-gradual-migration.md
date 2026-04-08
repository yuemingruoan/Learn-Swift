# 52. Swift Testing 工程实践：异步测试、依赖替身与从 XCTest 渐进迁移

## 阅读导航

- 前置章节：[29. 并发入门：async/await 与 Task](./29-concurrency-basics-async-await-and-task.md)、[32. 结构化并发：async let、TaskGroup 与父子任务](./32-structured-concurrency.md)、[46. 语言进阶：协议抽象、依赖注入与可测试设计](./46-protocol-abstraction-dependency-injection-and-testability.md)、[50. Swift Testing 入门：从 XCTest 到 @Test、#expect 与第一批单元测试](./50-swift-testing-basics-from-xctest-to-test-expect-and-require.md)、[51. Swift Testing 组织与复用：Suite、参数化测试、Tag 与 Trait](./51-swift-testing-organization-parameterized-tags-and-traits.md)
- 上一章：[51. Swift Testing 组织与复用：Suite、参数化测试、Tag 与 Trait](./51-swift-testing-organization-parameterized-tags-and-traits.md)
- 下一章：[53. Swift Package Manager 工程化入门：从多文件到多模块、Package.swift、Target 与 Product](./53-swift-package-manager-from-multi-file-to-multi-module.md)
- 适合谁读：已经完整读过第 50、51 章，知道单元测试、断言、`@Test`、`#expect`、`#require` 的基础写法，也理解依赖注入与可测试设计，现在想把测试真正落到异步业务代码上的读者

## 本章目标

学完这一章后，你应该能够：

- 写出 `async throws` 的 Swift Testing 测试函数
- 用 `#require` 和 `#expect` 验证异步结果
- 用 fake / stub / spy 替代真实远程、缓存、存储依赖
- 理解为什么第 46 章先讲依赖注入，第 52 章才正式把测试写完整
- 说清 Swift Testing 与 XCTest 在迁移过程中的推荐分工

## 本章对应资源

- 文稿：`docs/zh-CN/chapters/52-swift-testing-async-doubles-and-gradual-migration.md`
- 示例项目：`demos/projects/52-swift-testing-async-doubles-and-gradual-migration`

## 本章怎么读

1. 先读前两节，先理解为什么“异步测试”离不开前面讲过的边界设计。
2. 再看 demo 里的 `ArticleService` 与测试替身，理解 fake / stub / spy 的角色。
3. 最后读迁移建议，形成一个现实可执行的 XCTest -> Swift Testing 过渡策略。

## 正文主体

### 模块 0：为什么之前先讲“可测试设计”，而不是先教测试框架

如果你现在回头看第 46 章，会发现它其实已经把这一章最关键的前提铺好了：

- 业务逻辑依赖协议
- 真实依赖和替身依赖可以替换
- 注入点应该在外部，而不是写死在类型内部

当时很多读者会问：

- “既然已经讲了可测试设计，为什么不直接把测试也一起写完？”

答案就是：

- 因为当时先要解决的是**代码能不能被测**
- 现在才开始解决**测试怎么写**

这两个问题的先后顺序不能反。

如果没有边界设计，当你开始编写测试时很容易遇到这些问题：

- 远程请求写死在服务内部
- 缓存读写写死在 `FileManager` / `Data.write`
- 持久化上下文写死在服务里

这时你就算会 `@Test`、`#expect`、`#require`，测试仍然会很痛苦，因为你根本没法稳定控制外部环境。

所以这两章之间的真正关系是：

- 第 46 章解决“结构允许测试”
- 本章解决“结构允许之后，测试如何真正落地”

### 模块 1：为什么现在才开始碰 `async throws`

前两章都刻意避免了异步场景。

原因不是因为 Swift Testing 不能测异步，而是：

- 当时的知识储备不足以支撑你进行学习

但现在，我们已经可以把几个前置拼起来了：

- 并发基础：来自第 29、32 章
- 可测试边界：来自第 46 章
- Swift Testing 基础语法：来自第 50 章
- 测试组织与运行约束：来自第 51 章

所以现在我们才来开始讲解，如何为异步场景编写测试

### 模块 2：本章 demo 场景

这一章我们用一个代码最小但真实存在的服务层问题：

- 远程成功时，返回数据并写入缓存与存储
- 远程失败时，尝试回退到缓存
- 坏缓存需要清理，且不能掩盖原始远程错误

这正好对应第 46 章已经讲过的“依赖可替换”价值，但现在要正式用 Swift Testing 写出来。

### 模块 3：在看测试之前先看业务代码

本章 demo 的主角是 `ArticleService`：

```swift
import Foundation

struct Article: Codable, Equatable {
    let id: Int
    let title: String
}

protocol ArticleRemoteSource {
    func fetchArticles() async throws -> [Article]
}

protocol CacheStore {
    func read(key: String) throws -> Data?
    func write(key: String, data: Data) throws
    func remove(key: String) throws
}

protocol ArticleStore {
    func loadAll() throws -> [Article]
    func replaceAll(with articles: [Article]) throws
}

enum DemoRemoteError: Error, Equatable {
    case offline
}
```

这里只看这几行，就已经能看到本章的关键准备：

- 远程依赖被抽成 `ArticleRemoteSource`
- 缓存依赖被抽成 `CacheStore`
- 存储依赖被抽成 `ArticleStore`

这意味着：

- 真实实现可以换
- 测试替身也可以换

### 模块 4：`ArticleService` 的测试价值在哪里

完整服务代码如下：

```swift
import Foundation

struct ArticleService {
    private let remote: ArticleRemoteSource
    private let cache: CacheStore
    private let store: ArticleStore
    private let cacheKey = "articles.json"

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

    private func loadCachedArticles() -> CacheLoadResult<[Article]> {
        do {
            guard let data = try cache.read(key: cacheKey) else {
                return .miss
            }

            let articles = try JSONDecoder().decode([Article].self, from: data)
            return .hit(articles)
        } catch {
            return .corrupted(underlying: error)
        }
    }

    func refresh() async throws -> [Article] {
        let articles: [Article]

        do {
            articles = try await remote.fetchArticles()
        } catch {
            let remoteError = error

            switch loadCachedArticles() {
            case .hit(let cachedArticles):
                return cachedArticles
            case .miss:
                throw remoteError
            case .corrupted:
                try? cache.remove(key: cacheKey)
                throw remoteError
            }
        }

        let data = try JSONEncoder().encode(articles)
        try? cache.write(key: cacheKey, data: data)
        try store.replaceAll(with: articles)
        return articles
    }
}
```

这一段代码很适合这一章，它同时包含了：

1. 异步远程调用
2. 同步缓存读写
3. 存储更新
4. 成功路径
5. 失败回退路径
6. 坏缓存清理路径

也就是说，它足够真实，足够复杂，但还没有大到失控。

### 模块 5：`async throws` 测试函数该怎么写

先看本章第一条测试：

```swift
@Test("远程成功时会返回结果，并写入缓存和存储")
func refreshReturnsRemoteArticlesAndPersistsThem() async throws {
    let remoteArticles = [
        Article(id: 1, title: "Swift Testing 入门"),
        Article(id: 2, title: "参数化测试"),
    ]
    let remote = StubArticleRemoteSource(result: .success(remoteArticles))
    let cache = SpyCacheStore()
    let store = SpyArticleStore()
    let service = ArticleService(remote: remote, cache: cache, store: store)

    let received = try await service.refresh()

    #expect(received == remoteArticles)
    #expect(remote.fetchCallCount == 1)
    #expect(store.replaceAllCalls == [remoteArticles])
    #expect(cache.writeCalls.count == 1)

    let cachedData = try #require(cache.persistedDataByKey["articles.json"])
    let decoded = try JSONDecoder().decode([Article].self, from: cachedData)
    #expect(decoded == remoteArticles)
}
```

这一条测试已经展示了本章最重要的几个基本动作：

- 测试函数可以直接写成 `async throws`
- 业务调用处直接 `try await`
- 后面继续用 `#expect`
- 遇到必须存在的缓存数据，再用 `#require`

#### 这里没有使用旧式 expectation/wait 写法

这正是现代并发测试的关键变化之一。

以前很多 `XCTest` 异步代码会写成：

- 创建 expectation
- 回调里 fulfill
- `wait(for:timeout:)`

但在现代 `async/await` 风格下，很多业务本身已经是：

- `async`
- `throws`

这时测试就应该跟着使用同样的语义，而不是把它再包回回调式等待模型。

### 模块 6：为什么测试替身比“真的访问远程和磁盘”更重要

如果你没有替身，你为了验证 `ArticleService.refresh()` 的几条业务规则，就得真的做这些事：

- 构造一个远程接口
- 让它偶尔成功、偶尔失败
- 真的把 JSON 落盘
- 再想办法做坏缓存

这会立刻让测试变得：

- 慢
- 脆
- 不稳定

而本章的目标恰恰是反过来：

- 在完全可控的环境里稳定覆盖业务分支

这就是 fake / stub / spy 的意义。

### 模块 7：先把三种替身角色分清楚，不要混成一个词

本章 demo 里，虽然都叫“测试替身”，但它们承担的角色不完全一样。

#### 1. Stub

它最关注：

- 返回什么结果

本章 `StubArticleRemoteSource` 就是这种角色：

```swift
private final class StubArticleRemoteSource: ArticleRemoteSource {
    private let result: Result<[Article], Error>
    private(set) var fetchCallCount = 0

    init(result: Result<[Article], Error>) {
        self.result = result
    }

    func fetchArticles() async throws -> [Article] {
        fetchCallCount += 1
        return try result.get()
    }
}
```

这里很多初学者第一次会卡在这一行：

```swift
private let result: Result<[Article], Error>
```

看起来它像一整团类型语法，但其实可以拆成两层来看。

#### 先看最外层：`Result<Success, Failure>`

`Result` 可以先把它理解成：

- “要么成功，要么失败”的盒子

它有两个泛型位置：

- 前一个位置表示成功时装什么
- 后一个位置表示失败时装什么

也就是说：

```swift
Result<成功类型, 失败类型>
```

#### 再把这一行代进去

```swift
Result<[Article], Error>
```

它表达的就是：

- 成功时，里面装的是 `[Article]`
- 失败时，里面装的是 `Error`

所以这句可以直接翻译成人话：

- “这个 `result` 属性保存着一次预设的远程抓取结果，它要么是一组文章，要么是一个错误。”

#### 为什么成功类型是 `[Article]`

因为 `fetchArticles()` 这条远程接口成功时，本来就应该返回：

- 一个文章数组

所以 stub 想模拟远程成功，自然就要能预先装下：

- `[Article]`

#### 为什么失败类型写 `Error`

因为这里想让这个替身足够通用。

只要是符合 `Error` 协议的错误，都可以被塞进去，例如：

```swift
.failure(DemoRemoteError.offline)
```

这表示：

- 这次不是成功返回文章
- 而是预设成抛出 `DemoRemoteError.offline`

#### `result.get()` 又是在做什么

后面这句：

```swift
return try result.get()
```

本质上是在说：

- 如果 `result` 里装的是成功值，就把 `[Article]` 取出来
- 如果 `result` 里装的是失败值，就把那个错误抛出去

所以它刚好非常适合 stub：

- 你在初始化时决定“这次成功还是失败”
- 真正调用 `fetchArticles()` 时，再把这个预设结果兑现出来

这里它最重要的能力不是复杂逻辑，而是：

- 让测试自由指定远程成功还是失败

#### 2. Spy

它最关注：

- 被调了几次
- 调用时带了什么参数

本章的 `SpyCacheStore` 和 `SpyArticleStore` 都有这种性质：

```swift
private final class SpyCacheStore: CacheStore {
    var readResult: Result<Data?, Error> = .success(nil)
    private(set) var writeCalls: [(key: String, data: Data)] = []
    private(set) var removedKeys: [String] = []
    private(set) var persistedDataByKey: [String: Data] = [:]

    func read(key: String) throws -> Data? {
        try readResult.get()
    }

    func write(key: String, data: Data) throws {
        persistedDataByKey[key] = data
        writeCalls.append((key, data))
    }

    func remove(key: String) throws {
        persistedDataByKey[key] = nil
        removedKeys.append(key)
    }
}
```

你会发现它不只是“假缓存”，它还记录了：

- 写了几次
- 删除了哪个 key
- 最后缓存里剩什么

这就是 spy 价值。

#### 3. Fake

Fake 更像：

- 一个可运行但更简单的实现

本章 demo 没特意单独起名叫 fake，但如果你把 `SpyArticleStore` 改成真正的内存存储实现，它就会更接近 fake。

所以你不需要死背术语边界，但至少要有这个判断：

- “控制返回值”偏 stub
- “记录调用痕迹”偏 spy
- “用简化实现替代真实实现”偏 fake

### 模块 7A：给测试替身补函数文档时，重点写清“它控制什么”和“它记录什么”

如果你把这些替身只当成“测试里随手写的假对象”，那确实可以完全不写文档。

但只要出现下面任一情况，给它们补函数文档就开始有价值：

- 一个替身会在多条测试里反复复用
- 协作者需要快速看懂这个替身到底扮演什么角色
- 你希望在 Xcode 的 Quick Help 里直接看到方法语义

现阶段你可以先先记住：

- **替身方法的文档重点，不是业务流程本身，而是“这个替身会返回什么、记录什么、抛什么”。**

例如 `StubArticleRemoteSource` 里最关键的是：

- `init(result:)` 用来预设远程结果
- `fetchArticles()` 每次调用会增加计数，并返回预设结果

那文档就应该围绕这两点来写。

```swift
private final class StubArticleRemoteSource: ArticleRemoteSource {
    private let result: Result<[Article], Error>
    private(set) var fetchCallCount = 0

    /// 创建一个可预设返回结果的远程数据源替身。
    ///
    /// - Parameter result: 这条替身在 `fetchArticles()` 被调用时要返回的结果。
    init(result: Result<[Article], Error>) {
        self.result = result
    }

    /// 返回预设的文章抓取结果，并记录被调用次数。
    ///
    /// - Returns: 预设的文章数组。
    /// - Throws: `result` 中携带的错误。
    func fetchArticles() async throws -> [Article] {
        fetchCallCount += 1
        return try result.get()
    }
}
```

这里最值得注意的是三点：

#### 1. `- Parameter`

它用来解释调用方传进来的东西在这个替身里扮演什么角色。

例如这里的 `result` 不是泛泛地说“一个结果”，而是要明确写成：

- 这是预设给测试用的远程返回结果

#### 2. `- Returns`

它不是重复函数签名，而是说明：

- 这个返回值在测试语义里意味着什么

例如 `fetchArticles()` 的返回值重点不是“返回 `[Article]`”，因为类型签名已经看得见；更重要的是：

- 它返回的是预先配置好的结果

#### 3. `- Throws`

只要一个替身方法会把预设错误抛出来，就值得把错误来源写清楚。

观察 `SpyCacheStore.write(key:data:)`，它的文档重点就和 stub 不一样，因为`spy`更关心“记录了什么”：

```swift
private final class SpyCacheStore: CacheStore {
    /// 记录缓存写入，并把最新数据保存在内存字典里供断言使用。
    ///
    /// - Parameters:
    ///   - key: 写入缓存时使用的键。
    ///   - data: 要写入缓存的数据。
    func write(key: String, data: Data) throws {
        persistedDataByKey[key] = data
        writeCalls.append((key, data))
    }
}
```

这时文档说明的重点应该放在：

- 它会不会真的落盘
- 它把哪些调用痕迹留给测试断言

#### 写测试替身文档时，一个好用的判断方式

每次下笔前先问自己三个问题：

1. 这个方法是用来“预设结果”，还是“记录调用”，还是“提供简化实现”？
2. 调用方最需要知道它会保留哪些状态变化？
3. 如果它会抛错，这个错误到底来自哪里？

只要把这三件事写清楚，你的文档基本就够用了。

#### 固定格式不变，但解释重点要跟着替身角色走

和第 50 章一样，文档注释的固定格式还是这些：

```swift
///
/// - Parameter:
/// - Parameters:
/// - Returns:
/// - Throws:
```

但你在测试替身里真正要填写的内容，应该优先写：

- 预设结果
- 调用记录
- 内存状态变化
- 错误来源

而不是把真实生产实现那套业务说明原样照搬过来。

### 模块 8：测试验证了什么

再回到这条测试：

```swift
@Test("远程成功时会返回结果，并写入缓存和存储")
func refreshReturnsRemoteArticlesAndPersistsThem() async throws { ... }
```

它不是简单地在测：

- `received == remoteArticles`

它其实在验证四层事情：

1. 远程结果被返回
2. 远程被调用了一次
3. 存储层收到了 `replaceAll`
4. 缓存层收到了写入，并且写入内容可解码

这就是 service 层测试最重要的价值之一：

- 不只测“最终结果”
- 还测“关键协作是否发生”

如果你只测最终结果，很可能会漏掉这种回归：

- 结果看起来还是对
- 但缓存已经没写
- 或者存储已经没更新

### 模块 9：远程失败时，为什么测试应该显式验证缓存回退

第二条测试：

```swift
@Test("远程失败但缓存命中时，refresh 会回退到缓存")
func refreshFallsBackToCacheWhenRemoteFails() async throws {
    let cachedArticles = [
        Article(id: 10, title: "缓存里的文章"),
    ]
    let remote = StubArticleRemoteSource(result: .failure(DemoRemoteError.offline))
    let cache = SpyCacheStore()
    cache.readResult = .success(try JSONEncoder().encode(cachedArticles))
    let store = SpyArticleStore()
    let service = ArticleService(remote: remote, cache: cache, store: store)

    let received = try await service.refresh()

    #expect(received == cachedArticles)
    #expect(remote.fetchCallCount == 1)
    #expect(store.replaceAllCalls.isEmpty)
    #expect(cache.writeCalls.isEmpty)
}
```

这里需要值得注意的不是 `received == cachedArticles`，而是后面两条：

- `store.replaceAllCalls.isEmpty`
- `cache.writeCalls.isEmpty`

为什么这两条重要？

因为它们在说明：

- 这次结果来自缓存回退，而不是重新走了远程成功路径

这就是 spy 最典型的价值：

- 让你验证“业务分支到底走的是哪条路”

### 模块 10：坏缓存路径为什么值得单独测

第三条测试：

```swift
@Test("缓存损坏时会清理坏缓存，并把原始远程错误继续抛出")
func refreshRemovesCorruptedCacheBeforeRethrowingRemoteError() async {
    let remote = StubArticleRemoteSource(result: .failure(DemoRemoteError.offline))
    let cache = SpyCacheStore()
    cache.readResult = .success(Data("not json".utf8))
    let store = SpyArticleStore()
    let service = ArticleService(remote: remote, cache: cache, store: store)

    var capturedError: DemoRemoteError?

    do {
        _ = try await service.refresh()
    } catch let error as DemoRemoteError {
        capturedError = error
    } catch {
        #expect(Bool(false), "收到意料之外的错误：\(error)")
    }

    #expect(capturedError == .offline)
    #expect(cache.removedKeys == ["articles.json"])
}
```

这一条测试的意义远大于“多测一个异常 case”。

它在保护两个非常重要的工程判断：

1. 坏缓存不能继续留着
2. 远程错误不应该被坏缓存解码错误覆盖

如果你没有这类测试，后续代码重构很容易出这种回归：

- 一旦缓存损坏，抛出的不再是远程错误
- 或者坏缓存不被清理，下一次调用继续坏

### 模块 11：为什么这里用 `do-catch`，而不是一开始就引入更复杂的抛错匹配写法

你可能会问：

- “`Swift Testing`不是也能表达抛错断言吗？为什么这里手写 `do-catch`？”

答案很骨感：

- 因为这不是这章的重点
- ~~讲多了你们又消化不了~~

用 `do-catch` 有两个好处：

1. 读者不需要先学额外 API
2. 错误捕获逻辑非常显式

当前更重要的是让你看懂：

- 远程失败
- 缓存损坏
- 最终错误类型
- 删除动作是否发生

而不是在这里再加一层新语法心智负担。

### 模块 12：`#require` 在异步测试里依然有价值

本章第一条测试里有一句：

```swift
let cachedData = try #require(cache.persistedDataByKey["articles.json"])
```

显然它说明了:

- `#require`的价值并不会因为测试是异步的就消失

异步测试里照样会出现：

- 某个对象必须存在，后续断言才有意义

这就是`#require`的使用场景。

### 模块 13：如何把第 46 章的理念真正落地

我们现在可以把第 46 章的那句核心判断正式翻译成今天的测试代码了：

- **业务逻辑只依赖可替换边界时，测试就能在不访问真实世界的情况下稳定覆盖业务分支。**

在本章里，这句话不再是抽象口号，而已经具体变成：

- `ArticleRemoteSource` 可以用 stub 替代
- `CacheStore` 可以用 spy 替代
- `ArticleStore` 可以用 spy/fake 替代
- `ArticleService.refresh()` 的四条分支都能被稳定覆盖

### 模块 14：渐进迁移时，Swift Testing 和 XCTest 应该怎么分工

讲到这里，终于可以谈迁移策略了。

但这里必须先强调：

- 不要把“迁移”理解成“一次性重写全部测试”

更稳妥、更现实的建议是：

#### 建议 1：新写的 unit test 优先用 Swift Testing

原因很简单：

- 写法更贴近现代 Swift
- 参数化、traits、组织能力更统一
- 后续维护成本通常更低

#### 建议 2：已有 XCTest 不要为迁移而迁移

如果一条老 XCTest：

- 跑得稳定
- 可读性也还可以
- 近期没人要改它

那没必要为了“统一风格”立刻重写。

~~屎山能跑就不要去动它~~

#### 建议 3：只在真正碰到维护需求时顺手迁移

例如：

- 你要修改这条测试覆盖的新分支
- 你要重构这块业务逻辑
- 你要把一组重复 XCTest 改造成参数化测试

这时顺手迁到 Swift Testing，性价比更高。

#### 建议 4：UI tests 不迁到 Swift Testing 主线

这点必须先澄清：

- 本章讲的是 unit test 主线
- UI 自动化测试仍然主要属于 `XCTest / XCUI` 范畴

不要因为“Swift Testing 更新”，就把它误读成：

- 所有测试都应该迁过去

#### 建议 5：performance tests 也不要被错误归类

同样，本章不把性能测试写进 Swift Testing 主线。

这不是说 Swift Testing 永远碰不到性能相关话题，而是当前：

- 性能测试在工程实践里仍常见于 XCTest 体系

### 模块 15：`withKnownIssue()` 该怎么理解，但为什么本章不把它展开成专题

顺便提一嘴 `withKnownIssue()`，因为它确实属于 Swift Testing 工程能力的一部分。

你可以先把它理解成：

- “我知道这里存在已知问题，先把这个问题以显式形式记录下来”

但本章不打算把它扩展成更大的缺陷管理专题，原因有三：

1. 当前主线是异步测试和替身
2. 已知问题管理往往牵涉团队流程
3. 如果现在展开，会稀释本章重点

所以你只需要先记住：

- Swift Testing 不只会写断言，它也能表达“已知问题”这种工程语义

等你后续真的进入多人协作和复杂测试维护场景时，再把它作为进阶能力深入理解会更合适。

### 模块 16：本章明确不展开什么

为了保持边界清楚，本章依然不展开：

- UI tests 细节
- performance tests 细节
- Test Plans
- Xcode Cloud
- CI 配置
- 第三方 snapshot testing
- property-based testing

因为本章真正要解决的问题是：

- **如何把 Swift Testing 真正落到带异步和依赖边界的业务代码上**

### 模块 17：再读一遍demo
先看本章第一条测试：

```swift
@Test("远程成功时会返回结果，并写入缓存和存储")
func refreshReturnsRemoteArticlesAndPersistsThem() async throws {
    let remoteArticles = [
        Article(id: 1, title: "Swift Testing 入门"),
        Article(id: 2, title: "参数化测试"),
    ]
    let remote = StubArticleRemoteSource(result: .success(remoteArticles))
    let cache = SpyCacheStore()
    let store = SpyArticleStore()
    let service = ArticleService(remote: remote, cache: cache, store: store)

    let received = try await service.refresh()

    #expect(received == remoteArticles)
    #expect(remote.fetchCallCount == 1)
    #expect(store.replaceAllCalls == [remoteArticles])
    #expect(cache.writeCalls.count == 1)

    let cachedData = try #require(cache.persistedDataByKey["articles.json"])
    let decoded = try JSONDecoder().decode([Article].self, from: cachedData)
    #expect(decoded == remoteArticles)
}
```

它看起来稍长，但结构其实很规整。

#### 第一段：准备

前半段在做的事只有一个：

- 把环境完全控制住

具体来说：

- `remoteArticles`
  - 定义这次远程成功应该返回什么
- `StubArticleRemoteSource`
  - 保证远程层不会真的发请求
  - 同时确保返回结果可预测
- `SpyCacheStore`
  - 记录缓存写入发生了什么
- `SpyArticleStore`
  - 记录持久化替换发生了什么
- `ArticleService(...)`
  - 把这些依赖装配进被测对象

这一步是测试能否稳定的基础。

如果准备阶段不可控，后面的断言再漂亮也只是碰运气。

#### 第二段：执行

真正执行被测逻辑的语句只有一行：

```swift
let received = try await service.refresh()
```

它完成了两件事：

- 触发异步业务流程
- 捕获成功返回值

这正好说明为什么 `async throws` 测试函数很自然：

- 业务函数本来就是 `async throws`
- 测试函数也就应该直接用同样的异步和错误传播模型

#### 第三段：验证

后面的断言其实在验证三层结果：

1. 返回值对不对
2. 副作用有没有发生
3. 副作用内容对不对

所以它不是只测“拿到了文章列表”。

它还测了：

- 远程确实被调用了一次
- 存储层确实收到了整批文章
- 缓存层确实发生了写入
- 写入缓存的数据解码后仍然等于原始文章

这就是工程测试和演示测试的差异之一：

- 不只看最终返回
- 还要看其它操作是否符合预期

### 模块 18：为什么成功路径里要同时验证返回值、持久化和缓存写入

有些初学者会觉得：

- `#expect(received == remoteArticles)` 不就够了吗？

不够。

如果你只断言返回值，下面这些 bug 都有可能漏掉：

#### 漏洞 1：服务返回了正确结果，但忘了写入缓存

这时用户第一次刷新没问题，但下一次离线回退时就会失败。

#### 漏洞 2：服务返回了正确结果，但没有写入持久化存储

这时当前页面也许还能显示数据，但应用重启后读不到更新结果。

#### 漏洞 3：服务写入了缓存，但写入内容不对

例如：

- 编码错字段
- 键名错了
- 写入的是旧数据

这种问题只看 `writeCalls.count == 1` 也不够。

所以成功路径测试里才会进一步：

- 用 `#require` 先拿到缓存数据
- 再解码回 `[Article]`
- 最后断言解码结果和原始数据一致

这三步的意义是：

- 不只证明“写过”
- 还证明“写对了”

### 模块 19：缓存回退测试真正防的是什么

再看第二条测试：

```swift
@Test("远程失败但缓存命中时，refresh 会回退到缓存")
func refreshFallsBackToCacheWhenRemoteFails() async throws {
    let cachedArticles = [
        Article(id: 10, title: "缓存里的文章"),
    ]
    let remote = StubArticleRemoteSource(result: .failure(DemoRemoteError.offline))
    let cache = SpyCacheStore()
    cache.readResult = .success(try JSONEncoder().encode(cachedArticles))
    let store = SpyArticleStore()
    let service = ArticleService(remote: remote, cache: cache, store: store)

    let received = try await service.refresh()

    #expect(received == cachedArticles)
    #expect(remote.fetchCallCount == 1)
    #expect(store.replaceAllCalls.isEmpty)
    #expect(cache.writeCalls.isEmpty)
}
```

它防的不是“远程失败”这么简单，而是：

- 当远程失败时，业务是否能稳定走到既定降级路径

这类测试在真实项目里非常关键，因为失败路径最容易被未来改动无意破坏。

例如某次重构后，开发者可能：

- 忘了读取缓存
- 远程失败后直接抛错
- 远程失败后错误地覆盖本地存储
- 在回退到缓存时又重新写了一遍缓存

这条测试分别用四个断言把这些风险卡住：

- 返回结果应当来自缓存
- 远程仍然只调用一次
- 不应误写持久化存储
- 不应误写缓存

后两条特别重要，因为它们验证的是：

- 回退路径应该尽量只读，不要制造新的副作用

### 模块 20：坏缓存测试为什么要同时验证“清理”和“保留原始错误”

第三条测试是本章最有工程味的一条：

```swift
@Test("缓存损坏时会清理坏缓存，并把原始远程错误继续抛出")
func refreshRemovesCorruptedCacheBeforeRethrowingRemoteError() async {
    let remote = StubArticleRemoteSource(result: .failure(DemoRemoteError.offline))
    let cache = SpyCacheStore()
    cache.readResult = .success(Data("not json".utf8))
    let store = SpyArticleStore()
    let service = ArticleService(remote: remote, cache: cache, store: store)

    var capturedError: DemoRemoteError?

    do {
        _ = try await service.refresh()
    } catch let error as DemoRemoteError {
        capturedError = error
    } catch {
        #expect(Bool(false), "收到意料之外的错误：\(error)")
    }

    #expect(capturedError == .offline)
    #expect(cache.removedKeys == ["articles.json"])
}
```

这条测试看上去在处理错误，实际上同时覆盖了两条规则：

1. 坏缓存不能继续留着
2. 真正要暴露给调用方的仍然是原始远程错误

为什么两条都重要？

#### 只清理缓存，不保留原始错误，会发生什么

如果你把错误改成“缓存损坏”，调用方得到的信息就变了。

这可能导致：

- 调用方误判这次失败的真正原因
- 上层错误提示变得不准确
- 排查线上问题时失去最关键的远程失败线索

#### 只保留原始错误，不清理缓存，会发生什么

那下次再走到缓存回退路径时，仍然会再次读到坏数据。

这意味着：

- 同一个坏缓存会反复污染失败路径
- 用户每次离线都会触发同样的问题

所以这条测试不是“多测了一点点”，而是把一个很典型的工程修复闭环测完整了：

- 发现坏缓存
- 清理坏缓存
- 保留原始错误语义

### 模块 21：为什么这里同时用了 stub 和 spy，而不是只写一种万能替身

初学者很容易把测试替身统称成“mock”，然后只写一种大而全的假对象。

本章刻意没有这么做。

原因是：

- 不同替身承担的职责不同

`StubArticleRemoteSource` 更像是：

- 提供预设输入或错误
- 让测试稳定控制远程层返回什么

虽然它也顺手记录了 `fetchCallCount`，但它的主职责仍然是：

- **可控返回**

`SpyCacheStore` 和 `SpyArticleStore` 更像是：

- 记录交互过程
- 让测试事后验证副作用有没有发生

它们的主职责是：

- **可观察调用**

把这些职责混成一个超级替身，会出现几个问题：

- 一个类型同时负责太多事
- 每条测试都要配置很多无关状态
- 测试读起来不容易看出重点

所以更稳妥的做法是：

- 哪个依赖负责提供输入，就给它一个偏 stub 的替身
- 哪个依赖主要需要观察副作用，就给它一个偏 spy 的替身

这正是第 46 章“职责分离”在测试侧的具体体现。

### 模块 22：异步测试里最常见的四个误区

当你开始把 Swift Testing 用到真实异步业务时，最容易踩坑的会是下面这四类场景。

#### 误区 1：测试目标还是在真实访问网络或磁盘

这样写最大的问题不是“慢”，而是：

- 不稳定
- 不可预测
- 难以复现

测试最怕的不是失败，而是：

- 有时失败，有时成功

稳定可控才是最重要的

#### 误区 2：只测成功路径，不测降级路径

很多服务层 bug 恰恰都出在：

- 远程失败
- 缓存损坏
- 无缓存可用

如果这些路径不写测试，你以为自己覆盖了核心逻辑，其实只覆盖了“最理想情况”。

#### 误区 3：只断言返回值，不断言副作用

服务层几乎一定有副作用。

例如：

- 写缓存
- 更新存储
- 清理坏数据

如果这些副作用没断言，很多回归会直接漏掉。

#### 误区 4：为了少写几行，把太多规则塞进一条测试

异步测试本身已经比纯函数测试更复杂。

如果你再把：

- 成功路径
- 失败路径
- 缓存命中
- 缓存损坏

全塞进一条测试里，失败时会非常难定位。

所以本章 demo 才把它们拆成四条明确测试：

- 成功写入
- 失败回退
- 坏缓存清理
- 无缓存重抛

### 模块 23：回头看第 46 章，你会发现真正被复用的是“边界设计”

如果你把第 46 章和本章连起来看，会更容易理解为什么本教程没有一开始就猛讲测试语法。

今天这章之所以能写得顺，是因为我们复用了第 46 章已经讲过的几条设计原则：

- 依赖不要写死
- 依赖边界先抽成协议
- 业务类型通过初始化注入依赖
- 副作用留在边界外部

这几条原则看似是“设计”话题，但真正落到工程里时，它们直接决定：

- 你能不能写出稳定测试
- 你能不能只替换一层依赖而不碰其他逻辑
- 你能不能把失败路径测清楚

所以本章最重要的收获，某种程度上甚至不是新 API，而是：

- 你第一次真正看到“可测试设计”在工程里会怎么兑现

## 本章小结

经过了本章的学习，你已经拥有了一套足够强大的测试工具

到这里为止，你已经不是只会写：

- 纯函数的最小测试

而是已经能写：

- 异步 service 测试
- 成功 / 失败 / 回退 / 清理分支测试
- 基于 stub / spy / fake 的可控测试
