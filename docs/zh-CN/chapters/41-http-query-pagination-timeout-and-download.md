# 41. 更完整的 HTTP：查询、分页、超时与下载

## 阅读导航

- 前置章节：[36. Web 基础与状态管理入门：请求、响应与登录态](./36-web-basics-and-state-management.md)、[38. URLSession 网络请求入门：GET、POST 与 JSON 收发](./38-urlsession-get-and-post-json.md)、[39. 网络层分层与错误建模](./39-network-layer-architecture-and-error-modeling.md)、[40. 鉴权、Header 与登录态延续](./40-authentication-headers-and-session-continuity.md)
- 上一章：[40. 鉴权、Header 与登录态延续](./40-authentication-headers-and-session-continuity.md)
- 建议下一章：[42. 文件与目录：FileManager、URL 与本地读写](./42-filemanager-url-and-local-file-io.md)
- 下一章：[42. 文件与目录：FileManager、URL 与本地读写](./42-filemanager-url-and-local-file-io.md)
- 适合谁先读：已经完成第 `38-40` 章，手上有一个“可复用的网络层雏形”（哪怕很简单），并且准备开始处理更真实的 HTTP 细节：查询参数、分页、超时和下载的读者

## 本章目标

学完这一章后，你应该能够：

- 理解“查询参数、分页、超时、下载”这些场景，为什么往往需要从“最小 GET”升级到更完整的“请求描述 + 响应处理”模型
- 清楚区分：URL 查询参数（query）和请求体（body）分别适合表达什么信息
- 看懂并实现最常见的分页输入输出形态（page/limit、offset/limit、cursor）
- 把“分页元信息”和“列表数据”一起建模，并接回你的网络层返回值
- 在网络层里正确识别“超时”属于网络错误，而不是 HTTP 状态码
- 处理“下载返回的是二进制内容（Data 或文件 URL）”这种与 JSON API 完全不同的响应路径，并为第 `42` 章的“落盘保存”做认知铺垫

本章重点放在概念拆分，以及请求描述和响应处理到底哪里不一样。

本章不引入 UI，我们只聚焦网络层与数据建模。

本章的“下载”只走到“拿到数据或临时文件 URL，并检查响应信息”；真正的落盘保存、目录选择与文件移动将放到第 `42` 章展开。

## 本章怎么读

这一章最好按“差异点”来读，不要只背 API：

1. 先把“请求描述”统一起来
- 查询参数、分页参数、超时配置，本质上都是在补全请求描述：`URL + method + headers + query + body + timeout...`

2. 再把“响应处理”拆成策略
- JSON：拿到 `Data` 后解码
- 下载：拿到的是“原始字节”或“临时文件 URL”，处理路径不同

3. 最后把这些差异接回你的网络层
- 让网络层知道“这个 endpoint 返回的不是 JSON，而是 Data 或文件”
- 让网络层把“分页元信息”作为响应的一部分返回

## 正文

### 0. 开场：为什么鉴权之后还不够

第 `38` 章我们把最小的 GET / POST + JSON 收发跑通了；第 `39-40` 章又把请求分层、错误建模和鉴权信息补了上来。

但真实项目里，你会很快遇到下面四类“常见但不再最小”的需求：

- **查询参数**：同一个接口，用不同 query 表达筛选、排序、搜索关键字
- **分页**：列表永远不可能一次性返回全部数据，你必须表达“我要第几页/下一页”
- **超时**：某些请求应该设置较短的超时时间（例如搜索），某些请求容忍更久（例如下载）
- **下载**：响应不是 JSON，而是图片、压缩包、PDF、音频等二进制内容

这一章不打算把 HTTP 讲成一套大百科。我们只看这四类场景落到现有网络层以后，代码会多出哪些差异。

### 1. 查询参数：把“筛选/排序/搜索”放进 URL

#### 1.1 查询参数适合表达什么

一个更实用的判断是：当你表达的是“读取一个资源集合时的条件”，查询参数通常更合适，例如：

- 搜索关键字：`q=swift`
- 过滤条件：`completed=true`
- 排序：`sort=createdAt&order=desc`
- 分页：`page=2&limit=20`（下一节详讲）

这类信息的特点是：

- 不会改变服务器资源本身（仍然是读操作）
- 更像“读取条件”，适合在 URL 里可见、可复制、可缓存

与之对应，请求体（body）更适合表达：

- 新建/更新资源所需的“主体数据”（例如创建一条 todo 的 `title`、`dueAt` 等）
- 大型结构化数据（嵌套对象、数组等），尤其是需要 `Codable` 编码的内容

#### 1.2 在 Swift 里正确构造带查询参数的 URL

手写字符串拼接很容易出错（编码、可选项、数组、特殊字符），更推荐用 `URLComponents`：

```swift
var components = URLComponents(string: "http://127.0.0.1:3456/todos")!
components.queryItems = [
    URLQueryItem(name: "q", value: "swift"),
    URLQueryItem(name: "completed", value: "true"),
    URLQueryItem(name: "limit", value: "20")
]

guard let url = components.url else {
    throw NetworkError.invalidURL
}
```

这里你已经能看到第一个“请求描述差异”：

- 最小 GET 只需要一个 `URL`
- 带 query 的 GET 仍然是 GET，但你需要一个“更明确的 URL 构造过程”，并且要在网络层里把“query”作为 Endpoint 的一部分表达出来

#### 1.3 把 query 放进你的 Endpoint，而不是散落在调用点

如果你在第 `39` 章已经有类似 `Endpoint` / `makeRequest(baseURL:)` 的结构，那么最值得做的事情是：

- 让 `Endpoint` 直接携带 query（例如 `[URLQueryItem]` 或更强类型的 `Query`）
- 在 `Endpoint -> URLRequest` 的构造步骤里统一把 baseURL + path + query 组装成最终 URL

伪代码示意（你不需要和这里一字不差，只要抓住“责任归属”）。注意：这里**继续沿用第 39 章的 `Endpoint` 契约**，只是通过工厂方法把 query 写进去，而不是重新定义一套新的泛型 `Endpoint` 体系：

```swift
extension Endpoint {
    static func todoList(
        page: Int,
        limit: Int,
        keyword: String? = nil
    ) -> Endpoint {
        var endpoint = Endpoint(path: "/todos", method: .get)
        endpoint.queryItems = [
            URLQueryItem(name: "page", value: String(page)),
            URLQueryItem(name: "limit", value: String(limit))
        ]

        if let keyword {
            endpoint.queryItems.append(URLQueryItem(name: "q", value: keyword))
        }

        return endpoint
    }
}
```

这样一来，业务调用点只需要写：

- “我想要什么 endpoint”
- “我希望它解码成什么 DTO”

而不是每次都手工拼 URL 字符串。对于 JSON 列表分页，你仍然可以继续沿用第 39 章的调用方式：

```swift
let page: PageDTO<TodoDTO> = try await client.send(
    .todoList(page: 1, limit: 20, keyword: "swift"),
    as: PageDTO<TodoDTO>.self
)
```

### 2. 分页：请求里多了“我要哪一段”，响应里多了“还剩多少”

分页是这一章里最典型的“响应处理差异”：它不仅改了请求参数，也改了响应结构。

#### 2.1 为什么列表接口经常不是一次性全给完

这里不用背太多理论，先记三点就够了：

- 数据量可能很大，一次性返回会慢、会超时、会占内存
- 服务器通常需要保护自身，避免被“一次请求拉全量”打垮
- 客户端也不一定需要一次性拿全量（尤其是移动端）

#### 2.2 三种最常见的分页输入形态

1. `page` + `limit`
- 语义直观：第几页、每页多少条
- 示例：`/todos?page=2&limit=20`

2. `offset` + `limit`
- 更偏“从第几条开始取”
- 示例：`/todos?offset=40&limit=20`

3. `cursor`（游标/令牌）
- 服务器返回一个 `nextCursor`，客户端下次带上它
- 示例：`/todos?cursor=eyJpZCI6MTAwfQ&limit=20`

这三种写法放到网络层里，其实都能归到一件事上：**分页也是 query 的一部分**。

#### 2.3 最小分页响应：把“列表”和“元信息”一起建模

最常见的分页响应不是“裸数组”，而是“包一层”：

```json
{
  "items": [{ "id": 1, "title": "..." }],
  "page": 2,
  "limit": 20,
  "total": 153
}
```

或者 cursor 风格：

```json
{
  "items": [{ "id": 1, "title": "..." }],
  "nextCursor": "eyJpZCI6MTAwfQ",
  "hasMore": true
}
```

你在 Swift 里对应的 DTO 通常像这样：

```swift
struct PageDTO<Item: Decodable>: Decodable {
    let items: [Item]
    let page: Int?
    let limit: Int?
    let total: Int?

    let nextCursor: String?
    let hasMore: Bool?
}
```

这里的 `Item: Decodable` 和第 39 章的 `T: Decodable` 是一回事：

- `Item` 仍然是未知类型
- 但它必须满足 `Decodable`

原因也很直接：如果 `items` 里的单个元素都不能解码，那么整个 `PageDTO<Item>` 当然也无法从 JSON 解出来。

这里重点不在字段名，而在于你要意识到：

- **分页改变了响应结构**：不再是 `[Item]`，而是 `PageDTO<Item>`
- 因此你的网络层在 `decode` 阶段要么支持泛型容器，要么允许 endpoint 指定不同的解码目标

#### 2.4 接回网络层：分页的输入输出差异分别落在哪里

把分页接回网络层时，你可以用两句话自检：

- 输入：分页参数应该进入 `Endpoint.queryItems`（或你的 query 模型）
- 输出：网络层的返回值不应该直接丢掉分页元信息（例如 `total` / `nextCursor`）

如果你当前网络层的调用点只允许返回 `T: Decodable`，分页照样能接，只是这时的 `T` 要变成 `PageDTO<ItemDTO>`，而不是 `ItemDTO`。也就是说：**分页扩展的是 DTO 形状，不是第 39 章的核心契约。**

### 3. 超时：它属于网络错误，不是 HTTP 状态码

#### 3.1 为什么“超时不是状态码”

HTTP 状态码来自服务器响应报文（例如 `HTTP/1.1 200 OK`）。如果请求在到达服务器之前就失败了（断网、DNS 失败、握手失败、超时），那么：

- 你可能根本拿不到 `HTTPURLResponse`
- 因此也就没有 `statusCode` 可以检查

这类问题在你的错误建模里通常应该落在“传输层/网络层错误”（例如 `URLError`）而不是“HTTP 错误”。

#### 3.2 两个常用超时：request vs resource

在 `URLSessionConfiguration` 中有两个容易混淆的超时：

- `timeoutIntervalForRequest`
  - 通常理解为：单次请求在“等待响应/数据”时的超时策略（更偏交互体验）
- `timeoutIntervalForResource`
  - 通常理解为：整个资源加载的总时长上限（更偏资源传输）

这里先不往细节里钻，记住一个实践判断就够了：

- 搜索、列表、普通 JSON API：更短的 request timeout
- 下载、弱网容忍任务：更长的 resource timeout，或采用更合适的下载方案

#### 3.3 在请求描述里表达超时

超时既可以通过 session 配置统一设置，也可以按请求设置。按请求设置时，常见做法是用 `URLRequest.timeoutInterval`：

```swift
var request = URLRequest(url: url)
request.httpMethod = "GET"
request.timeoutInterval = 10 // 秒
```

这又回到了“请求描述差异”：

- 你不再只是“拿着 URL 发请求”
- 你需要用 `URLRequest` 把 method、headers、timeout 等信息描述完整

如果你已经有 `Endpoint -> URLRequest` 的构建流程，那么一个可控的做法是：

- 让 `Endpoint` 增加一个可选字段，例如 `timeout: TimeInterval?`
- 在 `makeRequest(baseURL:)` 这一步把它落到 `URLRequest.timeoutInterval`

#### 3.4 在错误处理里识别超时

超时通常会以 `URLError` 体现（例如 `.timedOut`）。你可以在网络层统一把它映射到你自己的错误类型，例如：

- `NetworkError.transport(URLError)`
- 或者更细：`NetworkError.timeout`

重点是，不要把它归到 `badStatusCode`，也不要试图从 `HTTPURLResponse.statusCode` 去判断超时。

### 4. 响应头与下载信息：下载场景经常需要看 header

当响应是 JSON 时，你最关心的是：

- 状态码是不是 2xx
- `data` 能不能 decode 成 DTO

但当响应是“下载文件/二进制内容”时，你通常还需要读一些 header 来做判断或显示信息，最常见的是：

- `Content-Type`
  - 服务器声明的媒体类型，例如 `application/pdf`、`image/png`
  - 它决定你后续怎么处理这份字节内容（预览、解析、保存扩展名等）

- `Content-Disposition`
  - 有时会包含建议的文件名（例如 `attachment; filename="report.pdf"`）
  - 客户端可以把它当作“默认保存名”，但仍要做好缺失/非法的兜底

注意：本章只做“识别与读取”，不在这里实现完整的“从 header 推导文件名 + 落盘保存”的流程；那属于第 `42` 章的文件系统内容。

### 5. 下载：当响应不是 JSON，你的网络层要换一条处理路径

#### 5.1 JSON 请求与二进制下载的核心差异

把“JSON API”和“下载”放在一起看，差异几乎都落在“响应处理”阶段：

1. JSON API（第 38 章的主线）
- 请求：通常 `data(for:)` 或 `data(from:)`
- 响应：拿到 `Data` 后 `JSONDecoder().decode(T.self, from: data)`
- 产物：一个强类型 `T`

2. 下载
- 请求：可能仍然是 GET，但响应体不是 JSON
- 响应：你要么直接拿到 `Data`，要么拿到一个“临时文件 URL”
- 产物：`Data` 或 “文件位置 + 响应信息”，而不是 DTO

这要求你的网络层至少支持两种“解码策略”：

- `Decodable` 解码（JSON）
- 原始数据返回（Data / 文件 URL）

#### 5.2 两种下载方式：拿 Data vs 拿临时文件 URL

1. `data(for:)`：直接拿到 `Data`
- 适合：体积较小的二进制内容（小图片、小配置文件）
- 风险：数据会进内存，文件越大越不合适

2. `download(for:)`：拿到临时文件 URL
- 适合：体积较大、需要保存到磁盘的内容
- 好处：避免把整个文件一次性塞进内存
- 注意：返回的文件通常在系统临时目录，你需要在后续把它移动到合适的位置（第 42 章讲）

示意代码（只展示“响应处理差异”）：

```swift
let (tempFileURL, response) = try await URLSession.shared.download(for: request)
guard let http = response as? HTTPURLResponse else { throw NetworkError.invalidResponse }
guard (200...299).contains(http.statusCode) else { throw NetworkError.badStatusCode(http.statusCode) }

let contentType = http.value(forHTTPHeaderField: "Content-Type")
// 本章只读取信息，不在这里实现落盘移动（第 42 章会做）
print("Downloaded to temp file:", tempFileURL)
print("Content-Type:", contentType ?? "<none>")
```

#### 5.3 接回网络层：让 Endpoint 能表达“我想要下载”

如果你现在的网络层主线还是第 39 章的：

- `func send<T: Decodable>(_ endpoint: Endpoint, as type: T.Type) async throws -> T`

这里的 `T: Decodable` 仍然是“泛型占位 + 可解码约束”：

- `T` 可以是 `TodoDTO`
- 也可以是 `[TodoDTO]`
- 还可以是 `PageDTO<TodoDTO>`

那么它天然适合 JSON。要支持下载，你通常会**在这个主线之上增补第二个入口**，而不是把整个 `Endpoint` / `NetworkClient` 重新定义成另一套体系，例如：

- `func sendData(_ endpoint: Endpoint) async throws -> Data`
- `func download(_ endpoint: Endpoint) async throws -> (temporaryFileURL: URL, response: HTTPURLResponse)`

这里真正要抓的是：

- JSON endpoint 仍然沿用“`Endpoint + Decodable`”这条主线
- 下载 endpoint 只是多了一条“返回原始内容或临时文件 URL”的分支能力

### 6. 把这些能力接回前两章的网络层

这一节只讨论“怎么接回去”，不要求你把网络层改写成某种固定模板。

跟着前面的章节走到这里，你手里应该已经有一个能用的网络层了。接下来就看它还缺哪些口子。

#### 6.1 请求描述维度：query / timeout / headers

你的 `Endpoint`（或等价抽象）是否能表达：

- `path`
- `method`
- `headers`
- `queryItems`
- `timeout`（可选）

如果缺了其中某一项，在业务调用点就会开始出现“手工拼 URL / 临时改 request / 到处塞 header”的散乱写法，网络层也就失去了复用价值。

#### 6.2 响应处理维度：JSON 解码 vs 原始数据 vs 下载结果

你的网络层是否能表达至少两种响应处理策略：

- JSON：`Data -> Decodable`
- 下载：`(tempFileURL, HTTPURLResponse) -> DownloadResult` 或 `Data`

一个简单可行的方向是：

- 保持第 39 章的 `send(_:as:)` 继续服务 JSON
- 为下载新增单独入口，让网络层统一处理 transport / invalidResponse / badStatusCode
- 让分页继续通过 `PageDTO<ItemDTO>` 这类 `Decodable` 容器承接

#### 6.3 你现在不需要做的事情

为了保持复杂度可控，这一章不要求你引入：

- 多层缓存策略
- 复杂重试（指数退避、熔断、幂等性判断）
- 断点续传、后台下载、下载进度回调

把请求描述和响应处理的差异放对位置，就已经足够给后面的章节铺路了。

## 边界说明（本章明确不做什么）

这一章有意收敛范围，避免把网络内容写成“框架大全”。本章不覆盖：

- 断点续传（Range、resume data）与后台下载
- 上传（multipart/form-data）、上传进度与流式传输
- 复杂重试策略（指数退避、幂等性、熔断等）
- UI 层分页交互（无限滚动、分页控件、下拉刷新）
- 复杂缓存策略与离线同步

本章只保证你能把以下差异正确落到网络层：

- query 与 body 的职责差异
- 分页既改变请求参数也改变响应结构
- 超时属于网络错误，不是 HTTP 状态码
- 下载与 JSON API 的响应处理路径不同，需要读取必要的响应头信息
