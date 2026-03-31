# 39. 网络层分层与错误建模

## 阅读导航

- 前置章节：[23. 错误处理：让失败路径更清楚](./23-error-handling-clear-failure-paths.md)、[34. JSON 格式与解析](./34-json-format-and-parsing.md)、[35. JSON 进阶：字段映射与复杂结构](./35-json-advanced-field-mapping-and-nested-structures.md)、[38. URLSession 网络请求入门：GET、POST 与 JSON 收发](./38-urlsession-get-and-post-json.md)
- 上一章：[38. URLSession 网络请求入门：GET、POST 与 JSON 收发](./38-urlsession-get-and-post-json.md)
- 建议下一章：[40. 鉴权、Header 与登录态延续](./40-authentication-headers-and-session-continuity.md)
- 下一章：[40. 鉴权、Header 与登录态延续](./40-authentication-headers-and-session-continuity.md)
- 适合谁先读：已经能用 `URLSession` 写出一个“单接口请求函数”（例如第 38 章那样），并且开始觉得“每个接口都要复制一遍构造 URL、拼参数、查状态码、解码”的读者

## 本章目标

学完这一章后，你应该能够：

- 解释清楚：为什么第 38 章那种“一个接口一个请求函数”的写法，在接口变多后会迅速变得难维护
- 建立 `Endpoint -> URLRequest -> NetworkClient -> DTO` 的最小网络分层，并能说清每一层的职责边界
- 建立一套可读、可扩展的错误模型：区分 URL 构造错误、发送错误、响应错误、状态码错误、解码错误
- 判断哪些重复逻辑值得抽取（例如 URL 拼装、状态码检查、统一解码），哪些暂时不应过早抽象（例如重试、拦截器、复杂中间件）

本章内容以“控制台 + 最小网络层”为主，刻意避免 UI 干扰，也避免一上来就工程化到“通用网络框架”。

本章会作为后续鉴权（第 40 章）、更完整 HTTP 场景（第 41 章）等内容的共同网络基础。从本章开始，后续章节如果要补 `Header`、`query`、`timeout`、`download` 等能力，应默认在这套 `Endpoint -> URLRequest -> NetworkClient -> DTO` 契约上增量扩展，而不是各自重定义核心角色。

## 本章怎么读

这一章可以按三步读：

1. 先建立结构图：`Endpoint -> URLRequest -> NetworkClient -> DTO`，看清每层职责。
2. 再把错误模型补齐：把“失败发生在哪一步”变成代码里的类型信息。
3. 最后看调用方式：调用方应该只表达“请求什么”和“要什么 DTO”，而不需要重复关心发送细节。

如果你读完仍觉得抽象过早，这里有一个最简单的问题：

- 当你要新增第 11 个接口时，你更希望复制粘贴 30 行请求代码，还是只新增一个 `Endpoint` 描述？

## 模块 0：开场定位

第 38 章教的是“把一个请求发出去”，它很像你第一次学会开车：你能把车开起来了，但还没有一套“上路规则”和“仪表盘”。

当接口数量很少时，一个接口一个 `fetchXxx()` 函数完全没问题；但当接口变多、参数变复杂、失败路径变多时，你会开始遇到下面几类痛点：

- 同样的 URL 拼装、查询参数拼接、Header 设置，在每个函数里重复出现
- 同样的“先检查状态码，再解码”的流程，在每个函数里重复出现
- 错误被 `throw` 出去，但调用方拿到的只是一个不透明的 `Error`，不知道是“地址错了”还是“状态码不对”还是“解码失败”
- 调用方代码越来越长，既要描述业务（要请求哪个接口），又要描述技术细节（怎么发、怎么查状态、怎么解码）

本章的目标就是用**最小**的分层，把这些痛点收敛到一个可维护的结构里。

先给出本章最终要得到的最小结构图（先理解职责，不必一次记住所有类型细节）：

```text
Endpoint
-> 负责描述“请求长什么样”：路径、方法、参数、Header、请求体

URLRequest
-> 负责把描述变成系统可发送的请求对象

NetworkClient
-> 负责真正发送，并在一个地方统一处理：发送失败、响应类型、状态码、解码

DTO
-> 负责承接“服务端 JSON 长什么样”，是解码的目标
```

## 模块 1：为什么要做网络分层

先看一个常见的“增长中的问题”。假设你写了两个请求函数：一个取详情、一个取列表。它们通常会像下面这样高度相似：

```swift
struct TodoDTO: Decodable {
    let userId: Int
    let id: Int
    let title: String
    let completed: Bool
}

enum LegacyNetworkError: Error {
    case invalidResponse
    case badStatusCode(Int)
}

func fetchTodoDetail(id: Int) async throws -> TodoDTO {
    let url = URL(string: "http://127.0.0.1:3456/todos/\(id)")!
    let (data, response) = try await URLSession.shared.data(from: url)

    guard let httpResponse = response as? HTTPURLResponse else {
        throw LegacyNetworkError.invalidResponse
    }
    guard (200...299).contains(httpResponse.statusCode) else {
        throw LegacyNetworkError.badStatusCode(httpResponse.statusCode)
    }

    return try JSONDecoder().decode(TodoDTO.self, from: data)
}

func fetchTodoList() async throws -> [TodoDTO] {
    let url = URL(string: "http://127.0.0.1:3456/todos")!
    let (data, response) = try await URLSession.shared.data(from: url)

    guard let httpResponse = response as? HTTPURLResponse else {
        throw LegacyNetworkError.invalidResponse
    }
    guard (200...299).contains(httpResponse.statusCode) else {
        throw LegacyNetworkError.badStatusCode(httpResponse.statusCode)
    }

    return try JSONDecoder().decode([TodoDTO].self, from: data)
}
```

重复点很明显：

- URL 怎么构造
- 怎么发送
- 怎么判断是不是 HTTP 响应
- 怎么检查状态码
- 怎么解码

其中有些重复点应该被抽出来，因为它们是“**每个接口都必须一致**”的规则：

- 状态码检查策略（例如 2xx 才允许解码）
- 非 HTTP 响应的处理（避免把它当成 HTTP 读状态码）
- 解码失败的错误信息保留（否则调试很痛苦）

但也有一些东西，在这个阶段不值得抽得太深，否则会把“教学最小网络层”做成一个网络框架：

- 自动重试、退避（backoff）
- 请求拦截器、插件系统、中间件链
- 通用缓存策略、离线策略

本章只做“刚好能规模化到十几个接口”的抽取：不多也不少。

## 模块 2：`Endpoint` 负责描述什么

我们先把“每个接口的差异”抽出来。一个接口的差异通常体现在：

- 请求路径（`/todos/1`）
- HTTP 方法（GET/POST/...）
- 查询参数（`?page=1&pageSize=20`）
- Header（例如 `Content-Type`、后续章节会讲的 `Authorization`）
- 请求体（通常是 JSON）

把这些差异描述成一个类型，我们称它为 `Endpoint`。它的核心原则是：

- `Endpoint` 只回答“**请求长什么样**”
- `Endpoint` 不负责发送（不触碰 `URLSession`）

下面是一份教学级、最小可用的 `Endpoint` 形状（注意：这是示例写法，不要求你在本章就追求完美泛型设计）：

```swift
enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
}

struct Endpoint {
    var path: String
    var method: HTTPMethod

    var queryItems: [URLQueryItem] = []
    var headers: [String: String] = [:]
    var body: Data? = nil
}
```

为了让它更像“接口目录”，我们通常会用工厂方法（或静态属性）来创建具体接口：

```swift
extension Endpoint {
    static func todoDetail(id: Int) -> Endpoint {
        Endpoint(path: "/todos/\(id)", method: .get)
    }

    static func todoList() -> Endpoint {
        Endpoint(path: "/todos", method: .get)
    }
}
```

到这里为止，我们还没有发送任何请求，但我们已经把“接口差异”收纳到一个明确的数据结构里了。

## 模块 3：从 `Endpoint` 到 `URLRequest`

系统真正发送请求时需要的是 `URLRequest`。所以我们需要做一次转换：

```text
Endpoint + baseURL
-> URLComponents 拼装
-> URL
-> URLRequest
```

这一步看起来只是“拼 URL”，但它是错误最集中的地方之一。典型错误包括：

- baseURL 不合法（缺 scheme/host）
- path 拼接导致 URLComponents 生成失败
- 查询参数包含需要编码的字符
- 请求体编码失败（例如 JSONEncoder 编码报错）

因此，“从 Endpoint 构造 URLRequest”这一步应该是 `throws` 的，并且错误应该能表达“失败发生在构造阶段”。

先定义本章的错误模型（先读一遍即可，后面会逐条解释）：

```swift
enum NetworkError: Error {
    case urlConstructionFailed
    case requestBodyEncodingFailed(underlying: Error)

    case transportFailed(underlying: Error) // 发送阶段失败（含 URLError）
    case nonHTTPResponse
    case badStatusCode(code: Int, body: Data?)
    case decodingFailed(underlying: Error, body: Data)
}
```

然后写 `Endpoint -> URLRequest` 的转换：

```swift
extension Endpoint {
    func makeRequest(baseURL: URL) throws -> URLRequest {
        guard var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: false) else {
            throw NetworkError.urlConstructionFailed
        }

        // 保守策略：确保 endpoint.path 以 "/" 开头。
        let normalizedPath = path.hasPrefix("/") ? path : "/" + path

        // 让 baseURL 是否以 "/" 结尾都能得到稳定结果，避免出现 "//todos" 这类双斜杠路径。
        let basePath = components.path.hasSuffix("/") ? String(components.path.dropLast()) : components.path
        components.path = basePath + normalizedPath
        if !queryItems.isEmpty {
            components.queryItems = queryItems
        }

        guard let url = components.url else {
            throw NetworkError.urlConstructionFailed
        }

        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue

        for (k, v) in headers {
            request.setValue(v, forHTTPHeaderField: k)
        }

        request.httpBody = body
        return request
    }
}
```

这里有两个“边界意识”值得强调：

- 这一层**不发送**，所以它不应该关心 `URLSession` 或“请求失败重试”等策略。
- 这一层要把“URL 构造失败”和“请求体编码失败”这类错误明确暴露出来，因为它们往往是**代码错误/配置错误**，不是网络波动。

### 请求体编码失败应该在哪一层出现？

如果你的 `Endpoint` 需要携带 JSON 请求体（POST），你会做类似这样的编码：

```swift
struct CreateTodoBody: Encodable {
    let title: String
}

extension Endpoint {
    static func createTodo(title: String) throws -> Endpoint {
        let body = CreateTodoBody(title: title)
        do {
            let data = try JSONEncoder().encode(body)
            var endpoint = Endpoint(path: "/todos", method: .post)
            endpoint.headers["Content-Type"] = "application/json"
            endpoint.body = data
            return endpoint
        } catch {
            throw NetworkError.requestBodyEncodingFailed(underlying: error)
        }
    }
}
```

注意我们这里把“编码失败”变成了 `NetworkError.requestBodyEncodingFailed`，并保留了 `underlying`，这样后续排查会更直接。

你可能会问：这是不是更像“业务层错误”？其实它属于“请求构造阶段”，并且它的失败往往来自：

- 你写的 `Encodable` 类型不符合预期（例如包含不可编码字段）
- 你配置的编码策略与服务端不一致

所以我们把它归为网络层错误

## 模块 4：`NetworkClient` 负责发送与统一处理

现在我们把“真正发送”和“统一处理”放进一个 `NetworkClient`。它的职责边界是：

- 输入：`URLRequest` 或 `Endpoint`
- 输出：某个 `Decodable` DTO
- 统一处理：发送失败、响应类型、状态码检查、解码失败

在看代码前，先补充一个在这一章第一次出现的语法：

```swift
func send<T: Decodable>(_ request: URLRequest, as type: T.Type) async throws -> T
```

这一行里有两层意思：

- `T`
  - 这是一个**泛型类型参数**，表示“这里先留一个类型占位，调用时再决定具体是什么类型”。
- `T: Decodable`
  - 这不是把 `T` 变成某个固定类型，而是给这个“未知类型”加一个**能力约束**：
  - 无论你传进来的具体类型是什么，它都必须遵守 `Decodable`，因为下面要调用 `decoder.decode(T.self, from: data)`。

你可以把它理解成：

- `T` 是“先不知道是什么类型”
- `: Decodable` 是“虽然不知道具体是什么，但我要求它至少会被 `JSONDecoder` 解码”

所以这里不是在说“模板只能接收未知类型，为什么又写成 `Decodable`”。更准确地说是：

- 它接收的仍然是未知类型
- 只是这个未知类型不能毫无约束，而必须满足“可解码”这个条件

这样调用时你既可以传：

- `TodoDTO.self`
- `[TodoDTO].self`

只要这些类型都满足 `Decodable`，这一个 `send` 函数就能复用。

这种写法更多地是为了方便讲解，因而即使没有被归在标准库内，你仍然可以看到许多的文稿用了这种写法

最小实现如下：

```swift
struct NetworkClient {
    let baseURL: URL
    let session: URLSession
    let decoder: JSONDecoder

    init(baseURL: URL, session: URLSession = .shared, decoder: JSONDecoder = JSONDecoder()) {
        self.baseURL = baseURL
        self.session = session
        self.decoder = decoder
    }

    func send<T: Decodable>(_ endpoint: Endpoint, as type: T.Type) async throws -> T {
        let request = try endpoint.makeRequest(baseURL: baseURL)
        return try await send(request, as: type)
    }

    func send<T: Decodable>(_ request: URLRequest, as type: T.Type) async throws -> T {
        let data: Data
        let response: URLResponse

        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw NetworkError.transportFailed(underlying: error)
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.nonHTTPResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            throw NetworkError.badStatusCode(code: httpResponse.statusCode, body: data)
        }

        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw NetworkError.decodingFailed(underlying: error, body: data)
        }
    }
}
```

这段代码做了一件非常重要的事情：它把“每个接口都必须一致执行的规则”集中到了一个地方：

- `URLSession` 的发送逻辑只写一次
- 状态码检查只写一次
- 解码逻辑只写一次
- 错误分类也只写一次

这就是“最小网络层”的意义：它不追求功能堆叠，而是追求**一致性**和**可读性**。

## 模块 5：错误建模：把失败路径变成类型信息

第 38 章你已经见过“分几类错误”的思路，本章要做的是把它落到更稳定的分层结构里。

我们把一次请求按时间顺序拆成五个阶段：

```text
1) URL 构造
2) 发送
3) 响应类型确认（是不是 HTTP）
4) 状态码检查
5) 解码
```

本章的 `NetworkError` 就是让调用方能回答这样的问题：

- “这次失败发生在哪个阶段？”
- “有没有必要重试？”
- “这是我代码写错了（URL/编码），还是服务端/网络问题（状态码/发送）？”

再来复习一下前面声明的错误：

```swift
enum NetworkError: Error {
    case urlConstructionFailed
    case requestBodyEncodingFailed(underlying: Error)

    case transportFailed(underlying: Error)
    case nonHTTPResponse
    case badStatusCode(code: Int, body: Data?)
    case decodingFailed(underlying: Error, body: Data)
}
```

### 为什么不要把所有失败都压成一个 `requestFailed`？

很多初学者会写：

```swift
enum NetworkError: Error { case requestFailed }
```

它的问题不是“简洁”，而是“你把排查难度推给了调用方和未来的自己”：

- URL 拼错了也是 `requestFailed`
- 断网也是 `requestFailed`
- 状态码 401/500 也是 `requestFailed`
- 解码失败也是 `requestFailed`

当你要打印日志或做 UI 提示时，你会发现你只能写一堆 `print(error)`，而没有任何结构化信息可用。

本章的做法并不是为了“类型很多”，而是为了让错误的维度与现实世界对齐：

- 发送失败：常见是网络波动、DNS、超时等（后续章节会进一步讲超时）
- 状态码错误：常见是服务端返回了“可读的失败结果”，这通常不是网络问题
- 解码失败：常见是 DTO 不匹配、字段类型不一致、服务端响应结构变了

### 一个建议：保留 `underlying` 和必要的 `body`

你会注意到我们在错误里保留了：

- `transportFailed(underlying:)`：保留系统给的底层错误（比如 `URLError`）
- `decodingFailed(underlying:, body:)`：保留解码失败原因和原始响应体
- `badStatusCode(code:, body:)`：保留状态码和响应体，方便打印服务端错误信息

这些错误信息能够帮你避免“只能猜哪里错了”这样的尴尬境界

## 模块 6：完整示例串联：调用方应该变短

当你有了 `Endpoint` 和 `NetworkClient` 后，调用方理想上只需要做两件事：

1. 选择要调用的接口（哪个 `Endpoint`）
2. 指定要解码成什么 DTO（`TodoDTO.self` 或 `[TodoDTO].self`）

示例调用如下：

```swift
let client = NetworkClient(baseURL: URL(string: "http://127.0.0.1:3456")!)

let detail: TodoDTO = try await client.send(.todoDetail(id: 1), as: TodoDTO.self)
let list: [TodoDTO] = try await client.send(.todoList(), as: [TodoDTO].self)
```

当请求失败时，调用方可以按错误类型做分支处理，而不是只能 `print(error)`：

```swift
do {
    let todo: TodoDTO = try await client.send(.todoDetail(id: 999), as: TodoDTO.self)
    print(todo)
} catch let error as NetworkError {
    switch error {
    case .urlConstructionFailed:
        print("URL 构造失败：检查 baseURL/path/queryItems")
    case .requestBodyEncodingFailed(let underlying):
        print("请求体编码失败：\(underlying)")
    case .transportFailed(let underlying):
        print("发送失败（网络/系统）：\(underlying)")
    case .nonHTTPResponse:
        print("不是 HTTP 响应：检查是否请求了正确的 scheme/服务")
    case .badStatusCode(let code, let body):
        print("状态码错误：\(code)，bodyBytes=\(body?.count ?? 0)")
    case .decodingFailed(let underlying, let body):
        print("解码失败：\(underlying)，bodyBytes=\(body.count)")
    }
} catch {
    print("未知错误：\(error)")
}
```

这就是“错误建模”的直接收益：失败路径不再是一个黑盒。
