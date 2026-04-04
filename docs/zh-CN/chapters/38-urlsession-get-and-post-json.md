# 38. URLSession 网络请求入门：GET、POST 与 JSON 收发

## 阅读导航

- 前置章节：[29. 并发入门：async/await 与 Task](./29-concurrency-basics-async-await-and-task.md)、[34. JSON 格式与解析](./34-json-format-and-parsing.md)、[35. JSON 进阶：字段映射与复杂结构](./35-json-advanced-field-mapping-and-nested-structures.md)、[36. Web 基础与状态管理入门：请求、响应与登录态](./36-web-basics-and-state-management.md)、[37. 本地教学 API 准备：安装环境并启动服务](./37-local-teaching-api-setup.md)
- 上一章：[37. 本地教学 API 准备：安装环境并启动服务](./37-local-teaching-api-setup.md)
- 适合谁先读：已经理解 JSON、错误处理和 `async/await`，并且已经把本地教学 API 跑起来，准备第一次真正把请求发出去的读者

## 本章目标

学完这一章后，你应该能够：

- 理解 `URLSession` 负责发送请求，`data(from:)` 只是最小 GET 的便捷入口
- 看懂 `URL -> URLSession -> (Data, URLResponse) -> HTTPURLResponse -> JSONDecoder` 这条最小链路
- 理解 `URLRequest` 才是更通用的请求描述模型
- 使用 `URLRequest + URLSession.shared.data(for:)` 统一组织 GET 和 POST
- 在解码前先检查 HTTP 状态码
- 使用 `JSONEncoder` 和 `JSONDecoder` 处理请求体与响应体 JSON
- 区分 URL 错误、网络错误、HTTP 错误、请求体编码错误、响应体解码错误

## 本章对应资源

- 文稿：`docs/zh-CN/chapters/38-urlsession-get-and-post-json.md`
- 示例项目：`demos/projects/38-urlsession-get-and-post-json`
- 练习起始工程：`exercises/zh-CN/projects/38-urlsession-get-and-post-json-starter`
- 练习答案：`exercises/zh-CN/answers/38-urlsession-get-and-post-json.md`
- 练习参考工程：`exercises/zh-CN/answers/38-urlsession-get-and-post-json`
- 配套本地服务：`teaching-api/`

阅读前请先确认：

- 第 `37` 章里的本地教学 API 已经启动
- `http://127.0.0.1:3456/health` 可以访问

## 简单了解接下来会接触的概念

这一章会反复出现以下名词：

- `URL`
- `URLSession`
- `Data`
- `URLResponse`
- `HTTPURLResponse`
- `JSONDecoder`
- `JSONEncoder`

为了不在阅读时引起困惑，当前我们这么理解即可：

- `URL` 负责表示“请求发到哪里”
- `URLSession` 负责真正把请求发出去
- `Data` 是原始响应体
- `URLResponse` 是响应外壳
- `HTTPURLResponse` 用来读取状态码
- `JSONDecoder` 用来把响应 JSON 解成 Swift 类型
- `JSONEncoder` 用来把 Swift 类型编码成请求 JSON

也就是说，网络请求需要经过一下几层处理：

```text
URL
-> URLSession 发请求
-> 拿到 Data 和 URLResponse
-> 检查 HTTP 状态
-> 再决定是否解码 JSON
```

## 本章怎么读

你可以先把这一章分成三步来读：

1. 先看 `URLSession`
- 理解最小请求是怎样被发出去的

2. 再看 `URLRequest`
- 理解一份请求应该怎样被完整描述

3. 最后再把 GET、POST 和 JSON 串起来
- 看清哪些部分是共通的
- 哪些部分只是请求配置不同

如果你能跟着教程完成这三个步骤，你后面再看网络请求代码时，就不会只觉得是在记 API 名字，而是能够知道：

- 请求是怎么发出去的
- 请求里哪些信息是地址，哪些是配置
- 响应回来后又该先检查什么、再处理什么

## 第一部分：URLSession 模块

这一部分只解决一个问题：

- **一个最简单的GET请求是怎样被发出去的**

在很多时候，我们的请求并不需要那么地“正式”

而在`Swift`中，也预留了`URLSession`类，让你用最少的代码把请求发出去

### 先看完整实现

```swift
struct TodoDTO: Decodable {
    let userId: Int
    let id: Int
    let title: String
    let completed: Bool
}

enum NetworkError: Error {
    case invalidResponse
    case badStatusCode(Int)
}

func fetchTodo() async throws -> TodoDTO {
    let url = URL(string: "http://127.0.0.1:3456/todos/1")!
    let (data, response) = try await URLSession.shared.data(from: url)

    guard let httpResponse = response as? HTTPURLResponse else {
        throw NetworkError.invalidResponse
    }

    guard (200...299).contains(httpResponse.statusCode) else {
        throw NetworkError.badStatusCode(httpResponse.statusCode)
    }

    return try JSONDecoder().decode(TodoDTO.self, from: data)
}
```

这段代码做了下面几件事：

- 发请求
- 拿响应
- 查状态
- 解 JSON

下面再按执行顺序，把它一点点拆开。

### 1. 这段代码整体在做什么

显然这里的重点是`fetchTodo`函数，按照执行顺序来看，它做了这些事：

1. 构造一个 `URL`
2. 用 `URLSession` 对这个地址发请求
3. 拿回 `Data` 和 `URLResponse`
4. 把响应确认成 `HTTPURLResponse`
5. 检查状态码是否处于成功区间
6. 最后把响应 JSON 解码成 `TodoDTO`

<a id="urlsession-shared-data-from-basics"></a>

### 2. `URLSession.shared.data(from:)` 是做什么的

这一句：

```swift
let (data, response) = try await URLSession.shared.data(from: url)
```

可以直接先理解成：

- **让系统用默认共享的 `URLSession`，对这个 `url` 发出一次最简单的请求**

这里的：

- `URLSession`
  - 是专门负责发送网络请求的对象类型

- `shared`
  - 是系统已经准备好的一份默认共享 session

- `data(from:)`
  - 是这份 session 提供的最简请求方法

当前阶段先用 `shared`，是因为我们只想先把“请求是怎样发出去的”这件事看清，不想一开始就分心去学更复杂的 session 配置。

### 3. 为什么返回的是 `(Data, URLResponse)`

`data(from:)` 的函数声明如下：

```swift
func data(from url: URL) async throws -> (Data, URLResponse)
```

如果你想查看这个方法更完整的官方说明，可以参考 `Apple Developer` 文档：

- [URLSession.data(from:)](https://developer.apple.com/documentation/foundation/urlsession/data(from:))

这表示：

- 你给它一个 `URL`
- 它异步发出请求
- 成功后返回一个元组：`(Data, URLResponse)`

这里的两个返回值分别代表：

- `Data`
  - 响应体的原始字节内容
  - 如果服务端返回的是 JSON，这份 JSON 通常会先以 `Data` 的形式出现

- `URLResponse`
  - 这次响应的通用描述信息
  - 它先告诉你“响应回来了”，但还没有进入 HTTP 专属视角

如果你只想快速查阅，这里最值得先记住的是：

- `URLSession` 负责发送请求
- `data(from:)` 是最小 GET 的便捷入口
- 返回值是 `Data + URLResponse`

### 4. 为什么要转成 `HTTPURLResponse`

前面的完整代码里有这样一段：

```swift
guard let httpResponse = response as? HTTPURLResponse else {
    throw NetworkError.invalidResponse
}
```

这时才需要解释这两个类型的关系：

```swift
class URLResponse: NSObject
class HTTPURLResponse: URLResponse
```

也就是说：

- `URLResponse` 是通用响应类型
- `HTTPURLResponse` 是 HTTP 专属子类型
- `statusCode` 只定义在 `HTTPURLResponse` 上

所以你不能直接写：

```swift
let response: URLResponse = ...
print(response.statusCode)
```

因为 `URLResponse` 的类型声明里根本没有 `statusCode` 这个成员。

### 5. `statusCode` 的值从哪里来

这个值不是 Swift 在现场凭空造出来的，它来自服务器返回的 HTTP 响应报文，例如：

```text
HTTP/1.1 200 OK
```

系统在内部解析这份报文后，会创建一个 `HTTPURLResponse` 对象，并把解析出的状态码存进它的 `statusCode` 属性里。

也就是说：

- 状态码来自服务器返回的报文
- 系统解析后把它存进 `HTTPURLResponse.statusCode`
- `as? HTTPURLResponse` 不是创造属性，而是把同一个响应对象按更具体类型取出来

另外还要注意一个边界：

- 只有在请求真正拿到一份有效的 HTTP 响应时，才会有状态码
- 如果请求更早就失败了，例如断网、超时、连不上服务器，那就根本没有可读的状态码

如果你想顺手对照官方文档，这里最值得一起看的是：

- [URLResponse](https://developer.apple.com/documentation/foundation/urlresponse)
- [HTTPURLResponse](https://developer.apple.com/documentation/foundation/httpurlresponse)

当前阶段最常用的成员，你先认识这些就够了。

`URLResponse` 常用成员：

- `url`
  - 这次响应最终对应的地址

- `mimeType`
  - 响应内容的 MIME 类型，例如 `application/json`

- `expectedContentLength`
  - 系统预计这次响应内容有多长

- `textEncodingName`
  - 响应文本使用的编码名称

- `suggestedFilename`
  - 系统建议的文件名，下载场景更常见

`HTTPURLResponse` 常用成员：

- `statusCode`
  - HTTP 状态码

- `allHeaderFields`
  - 这次响应里的所有响应头

- `value(forHTTPHeaderField:)`
  - 读取某一个响应头的值

### 6. 为什么最后才解码 JSON

回到完整代码里最后两步：

```swift
guard (200...299).contains(httpResponse.statusCode) else {
    throw NetworkError.badStatusCode(httpResponse.statusCode)
}

return try JSONDecoder().decode(TodoDTO.self, from: data)
```

顺序之所以是“先查状态，再解码”，是因为这两步处理的是不同层的问题：

- 状态码不对：这是 HTTP 层的问题
- JSON 解不出来：这是数据模型层的问题

如果你不先检查状态码，而是直接进入 `decode`，那服务器返回 `404`、`500` 或错误 JSON 时，你最后看到的往往只是一个模糊的“解码失败”，但那并不是问题真正发生的第一层。

所以即使是在`URLSession`这条最小链路里，最稳妥的顺序始终是：

1. 构造 `URL`
2. `URLSession.shared.data(from:)`
3. 拿到 `Data` 和 `URLResponse`
4. 转成 `HTTPURLResponse`
5. 检查 `statusCode`
6. 解码 JSON

到这里，你已经知道“请求是怎样被发出去的”了。下一步才轮到另一个问题：

- **这份请求本身该怎样被统一描述**

这时才进入 `URLRequest` 模块。

## 第二部分：URLRequest 模块

前面的 `data(from:)` 很适合建立第一印象，但它只是一个：

- **最简、最省事的入口**

而在实际的编码中，最常用的形式还是：

- **先构造 `URLRequest`，再交给 `URLSession` 发送**

因为无论是 GET 还是 POST，本质上都只是：

- 一份请求配置
- 再加上一次发送动作

所以不要把 `URLRequest` 理解成“POST 才需要的特殊工具”。更准确的理解是：

- `URLSession` 负责发送
- `URLRequest` 负责描述请求

### `URLRequest` 的最小通用语法

先看最小外形：

```swift
var request = URLRequest(url: url)
request.httpMethod = "POST"
request.setValue("application/json", forHTTPHeaderField: "Content-Type")
request.httpBody = body
```

这里每一行都只是在给这份请求补充信息：

- `URLRequest(url: url)`：先基于地址创建请求
- `httpMethod`：指定请求方法
- `setValue(..., forHTTPHeaderField: ...)`：设置请求头
- `httpBody`：放入请求体

如果你想查看 `URLRequest` 更完整的说明，可以参考 `Apple Developer` 文档：

- [URLRequest](https://developer.apple.com/documentation/foundation/urlrequest)

当前阶段最值得先认识的是下面这些常用成员：

- `url`
  - 这份请求最终要发到哪个地址

- `httpMethod`
  - 请求方法，例如 `GET`、`POST`

- `httpBody`
  - 请求体数据，常见于 `POST` / `PUT` / `PATCH`

- `setValue(_:forHTTPHeaderField:)`
  - 用来设置请求头
  - 正如我们在12章时讲解过的，这是一种文稿常用的简写
  - 实际的声明应该是：`func setValue(_ value: String?, forHTTPHeaderField field: String)`
`
- `value(forHTTPHeaderField:)`
  - 用来读取某个请求头当前的值

- `allHTTPHeaderFields`
  - 用字典形式查看当前有哪些请求头

- `timeoutInterval`
  - 这份请求最多等多久

- `cachePolicy`
  - 这份请求怎样和缓存交互

- `httpShouldHandleCookies`
  - 这份请求是否让系统处理 Cookie

### 为什么 GET 也应该使用 `URLRequest` 

这里要澄清一个常见误区：

- 不是“GET 也可以用 `URLRequest`”

而是：

- **GET 本身就应该放在 `URLRequest` 这套模型里理解**

只是系统另外提供了：

```swift
URLSession.shared.data(from: url)
```

这样一个最简入口，方便你在最小 GET 场景里先少写一点代码。

也就是说：

- `data(from:)` 是便捷方式
- `URLRequest + data(for:)` 才是更通用、更模块化的主线

### `data(for:)` 的函数声明

和前面的 `data(from:)` 对照来看，`data(for:)` 最关键的外形是：

```swift
func data(for request: URLRequest) async throws -> (Data, URLResponse)
```

如果你想查看这个方法更完整的官方说明，可以参考 `Apple Developer` 文档：

- [URLSession.data(for:)](https://developer.apple.com/documentation/foundation/urlsession/data(for:))

它和 `data(from:)` 的返回值是一样的，区别只在参数：

- `data(from:)` 收一个简单 `URL`
- `data(for:)` 收一份完整的 `URLRequest`

所以：

```swift
URLSession.shared.data(for: request)
```

应该直接读成：

- **按这份已经配置好的请求去发**

## 第三部分：用 `URLRequest` 统一理解 GET 和 POST

从这里开始，本章主线统一切到：

- `URLRequest + URLSession.shared.data(for:)`

因为这样最容易看出 GET 和 POST 的共性。

### 用 `URLRequest` 写 GET

请求数组接口时，我们可以这样写：

```swift
func fetchTodoList() async throws -> [TodoDTO] {
    var components = URLComponents(string: "http://127.0.0.1:3456/todos")!
    components.queryItems = [
        URLQueryItem(name: "limit", value: "3")
    ]

    let url = components.url!
    var request = URLRequest(url: url)
    request.httpMethod = "GET"

    let (data, response) = try await URLSession.shared.data(for: request)
    _ = try validateHTTPResponse(response)
    return try JSONDecoder().decode([TodoDTO].self, from: data)
}
```

这里最值得注意的是：

- 查询参数仍然可以用 `URLComponents`
- 但最终把它们收束成一个 `URLRequest`
- 然后统一交给 `data(for:)`函数

也就是说`GET`也可以使用`URLRequest`，甚至在实现链路上与`POST`几乎无差异

这样一套统一的接口正是规范开发所需要的

### 为什么建议用 `URLComponents` 来拼接GET请求体

如果地址里有查询参数，我们更推荐

- 通过 `URLComponents` 和 `queryItems` 来组织

这样以后参数一多时，会更容易看清：

- 路径是什么
- 参数是什么

而不会把所有东西都硬拼在一个字符串里。

~~(然后发现哪漏了一个`=`就老实了)~~

### 用 `URLRequest` 写 POST

再看 POST：

```swift
struct CreateStudyRecordRequestDTO: Encodable {
    let chapter: Int
    let title: String
    let durationMinutes: Int
}

struct StudyRecordResponseDTO: Decodable {
    let id: Int
    let chapter: Int
    let title: String
    let durationMinutes: Int
    let status: String
}

func createStudyRecord(_ input: CreateStudyRecordRequestDTO) async throws -> StudyRecordResponseDTO {
    let url = URL(string: "http://127.0.0.1:3456/study-records")!
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.httpBody = try JSONEncoder().encode(input)

    let (data, response) = try await URLSession.shared.data(for: request)
    _ = try validateHTTPResponse(response)
    return try JSONDecoder().decode(StudyRecordResponseDTO.self, from: data)
}
```

这时你就能很直观地看出：

- GET 和 POST 的发送骨架几乎一样
- 真正变化的主要只是请求配置

更准确地说，统一骨架基本就是：

```swift
var request = URLRequest(url: url)
request.httpMethod = ...
request.setValue(..., forHTTPHeaderField: ...)
request.httpBody = ...

let (data, response) = try await URLSession.shared.data(for: request)
_ = try validateHTTPResponse(response)
```

在这个骨架里：

- GET 通常不用请求体
- POST 通常需要 `Content-Type` 和 `httpBody`

所以这两者的差别，不应该再被理解成“两套完全不同的技术路线”，而应该理解成：

- **同一个请求模块下，不同的配置组合**

## 第四部分：JSON 收发模块

当请求发送层稳定之后，JSON 这层其实就很好理解了：

- 响应 JSON：用 `JSONDecoder`
- 请求 JSON：用 `JSONEncoder`

例如：

- GET 常见是“解响应”
- POST 常见是“编请求体 + 解响应”

这里也要建立一个重要边界：

- 请求体模型和响应体模型不一定完全一样

例如当前 POST 例子里：

- 发送时没有 `id`
- 返回时多了 `id` 和 `status`

所以把请求模型和响应模型拆开，会更清楚。

## 错误处理

既然讲完了请求链路，接下来我们该看如何处理过程中的错误了

我们可以建立这样一个模型：

```swift
enum NetworkError: Error {
    case invalidURL
    case requestEncodingFailed
    case invalidResponse
    case badStatusCode(Int)
    case responseDecodingFailed
}
```

### 一次网络请求中排查错误的顺序

1. 地址对不对
- URL 有没有拼错

2. 服务通不通
- 对于当前场景是本地教学 API 有没有启动

3. 状态码对不对
- 是不是在 `200...299` 范围内

4. 请求体是否编码成功
- POST 的 `JSONEncoder` 有没有报错

5. 响应 JSON 是否匹配模型
- `TodoDTO` 或 `StudyRecordResponseDTO` 是否和 JSON 外形一致

如果能将这五层边界进行区分，后面你`Debug`时就不会只剩下一个模糊印象：

- “好像网络请求坏了”

## 一个很重要的习惯：先查状态，再解码

这件事值得单独强调一次。

很多初学者第一次写请求时，会不自觉地把顺序写成：

- 先解码
- 失败了再猜是不是接口出问题

但更稳妥的顺序应该是：

1. 先确认响应是不是 HTTP 响应
2. 再确认状态码是不是成功区间
3. 最后才解码 JSON

因为如果服务器回的是：

- `404`
- `500`

你直接进入 `decode`，最后看到的很可能只是一个“解码失败”，但这并不是问题真正发生的第一层。

## 本章 demo 在做什么

配套 demo 工程里会完整演示三件事：

1. 请求单个 Todo
2. 用显式 `URLRequest` 再做一次 GET
3. 提交一条学习记录
4. 演示“状态码失败”和“解码失败”这两条不同失败路径

你在运行 demo 时，最值得观察的是：

- `URLSession` 在最小 GET 里扮演的“发送器”角色
- `URLRequest` 怎样作为统一请求模型同时承接 GET 和 POST
- `POST` 只是在同一套请求骨架上增加了 method、header、body 配置

## 常见误区与排错顺序

常见误区：

- 以为 `data(from:)` 就等于“网络请求的全部形态”，结果一碰到 POST 和 Header 就开始重写整条链路
- 还没看状态码就直接解码，最后把 404/500 看成“JSON 解码失败”
- 把“请求发不出去”和“服务端回错状态码”混成同一种错误

排错顺序建议固定成这样：

1. 先看 URL 是否正确
2. 再看请求有没有真正发出去
3. 再看响应是不是 `HTTPURLResponse`
4. 再看状态码是不是 `200...299`
5. 最后才看 DTO 与 JSON 是否匹配

## 本章小结

再来回顾一下开始时讲到的那些概念：

- `URL` 负责请求发到哪（地址）
- `URLSession` 负责发请求
- `data(from:)` 是最简单 GET 的便捷入口
- `URLRequest + data(for:)` 才是更通用的主线
- `JSONDecoder` 负责解响应
- `JSONEncoder` 负责编请求体

同时也要记住本章最重要的请求流程：

1. 构造请求
2. 发请求
3. 拿响应
4. 查状态码
5. 再解码

相信经过了这一章的学习，你应该能够熟练处理网络请求了
