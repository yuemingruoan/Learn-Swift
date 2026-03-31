# 40. 鉴权、Header 与登录态延续

## 阅读导航

- 前置章节：[36. Web 基础与状态管理入门：请求、响应与登录态](./36-web-basics-and-state-management.md)、[38. URLSession 网络请求入门：GET、POST 与 JSON 收发](./38-urlsession-get-and-post-json.md)、[39. 网络层分层与错误建模](./39-network-layer-architecture-and-error-modeling.md)
- 上一章：[39. 网络层分层与错误建模](./39-network-layer-architecture-and-error-modeling.md)
- 建议下一章：[41. 更完整的 HTTP：查询、分页、超时与下载](./41-http-query-pagination-timeout-and-download.md)
- 下一章：[41. 更完整的 HTTP：查询、分页、超时与下载](./41-http-query-pagination-timeout-and-download.md)
- 适合谁先读：已经完成第 38 章的 `URLSession + URLRequest` 基础，并且在第 39 章已经把“最小网络层 / 错误建模”搭出一个可复用形状的读者

## 本章目标

学完这一章后，你应该能够：

- 知道“鉴权信息为什么常放在 Header，而不是 JSON Body”这件事在客户端意味着什么
- 读懂并写出 `Authorization: Bearer <token>` 这种最常见的身份请求头
- 建立 Cookie / Session 与 Bearer Token 的最小差异心智模型：它们都能延续登录态，但携带方式不同
- 明确“登录态延续”在客户端侧的最小职责：登录后把身份信息带到后续请求里，并对 401/403 做出合理反应
- 把鉴权逻辑放在**网络层之上、业务调用之下**的合适位置：既不散落到每个请求函数里，也不引入过度工程化的拦截器体系

本章重点是教学级鉴权流程与“登录态延续”的最低限度实现，不设计真实生产级账号系统。

本章以控制台项目视角为主，重点放在请求头（Header）与身份如何随请求一起被发送。

### 在请求中传递身份

在第 38 章，我们已经熟悉了把请求发出去、拿到响应、检查状态码、解 JSON 这一整条流程

在第 39 章，我们把这些重复逻辑抽象成了一个网络层，让调用方不再关心 `URLSession` 的细节。

接下来会自然遇到一个问题：

- 我已经能“稳定地发请求”了，那**登录一次之后**，怎样让后续请求都带上“我是谁”？

这就是本章要解决的核心：**鉴权信息如何随着请求一起发送**，以及“登录态”在客户端应该怎样延续。

为了避免过早工程化，本章只讲你代码里需要做的三件事：

1. 知道身份信息通常放在 HTTP Header（以及 Cookie）里
2. 能在构造 `URLRequest` 的时候把这些信息正确地写进去
3. 能在收到 401/403 等响应时，知道应该在应用侧做什么（提示重新登录、清理本地状态等）

### 先把概念钉住：Header、Body 与 Cookie 分别负责什么

HTTP 请求里常见的两个载体是：

- Header：请求的“元信息”（鉴权、内容类型、语言、客户端信息等）
- Body：请求的“内容”（JSON、表单、二进制等）

这并不是说“Header 不能放业务字段，Body 不能放身份字段”，而是说：在多数 API 设计里，**身份**被视为一次请求的通用上下文，它更适合出现在 Header 或 Cookie 里，而不是作为某个 JSON Body 的字段出现。

~~(一般来讲你要是不这么写你家的前端会带着菜刀来问候你)~~

你可以先把它理解成一个约定俗成的分工：

- JSON Body 表达“你想做什么”（创建一条记录、提交表单、更新资料）
- Header / Cookie 表达“你是谁、你用什么方式发来、你能不能做这件事”

这会直接影响到客户端代码的落点：你不希望在每个 DTO 的 `Encodable` 里塞一个 `token` 字段；你希望在**发请求之前**，把鉴权信息作为请求配置加进去。

### Bearer Token：`Authorization` 请求头在做什么

最常见的一种方案是 Bearer Token：

- 你先调用“登录接口”
- 服务器返回一个 token（访问令牌）
- 之后的受保护接口需要你在 Header 里带上这个 token

最典型的请求头长这样：

```text
Authorization: Bearer <token>
```

其中：

- `Authorization` 是 HTTP 标准语义里用于表达认证信息的请求头字段名
- `Bearer` 是一种认证方案名（代表“拿着这个 token 的人就是当前身份”）
- `<token>` 是服务端发给你的那串凭证

#### 在 Swift 里最小怎么写

如果你已经在先前的章节里掌握了如何使用 `URLRequest`，那么把 Header 写进去只需要一行：

```swift
var request = URLRequest(url: url)
request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
```

这一行的位置很重要：

- 它应该发生在“把请求发出去”之前
- 通常发生在 `Endpoint -> URLRequest` 这一步，或者在构造 `URLRequest` 的上层（由调用方提供 token）

#### 401 / 403：你该如何解读

当你不带 token、token 不合法、token 过期时，服务端通常会返回：

- `401 Unauthorized`：多数情况下意味着“你还没通过认证”或“凭证无效”
- `403 Forbidden`：多数情况下意味着“你是谁我知道，但你没有权限做这件事”

对客户端来说，这两者的处理策略通常不同：

- 401 更倾向于触发“重新登录/重新获取凭证”的流程
- 403 更倾向于提示“权限不足”，而不是反复让用户登录

注意：不同服务端实现可能会有差异，但你至少要在代码结构上给这两类情况留出分支空间，而不是把它们混成“请求失败”一个笼统错误。

### Cookie / Session：登录态也可以通过 Cookie 延续

另一条常见路线是 Cookie / Session：

- 你调用登录接口
- 服务端在响应里通过 `Set-Cookie` 下发一个 Cookie（或 Session ID）
- 后续请求只要把 Cookie 带上，服务端就能在服务器侧找到对应 session，从而识别你的身份

它在 HTTP 里的样子通常是：

- 响应（服务端下发）：

```text
Set-Cookie: session_id=...; Path=/; HttpOnly
```

- 请求（客户端带回去）：

```text
Cookie: session_id=...
```

#### Cookie的持久化

在 `URLSession` 体系里，Cookie 通常由系统的 Cookie 存储（`HTTPCookieStorage`）来管理。

你可以先记住一个“足够初学者”的结论：

- 如果服务端正确下发 Cookie，并且你的 `URLSession` 允许使用 Cookie 存储，那么后续请求可能会自动携带 Cookie

但这件事会受很多配置影响（例如使用的 session 配置、是否持久化、是否允许 Cookie 等），本章不会展开讲到底层配置细节；我们只需要知道：

- Cookie 模式下，“登录态延续”可能不需要你手写 `Authorization`，但你仍然需要知道它是通过 Header（`Cookie` 头）在发生的

### Token vs Cookie：在客户端的最低差异认知
 
从“我怎样把身份带到后续请求里”这个角度看：

- Bearer Token：你要显式在请求里加 `Authorization` 头
- Cookie / Session：系统可能帮你自动带 Cookie，但本质仍是请求头层面的携带

从“状态存放在哪里”这个角度看：

- Bearer Token：token 通常在客户端保存一份（内存、磁盘、钥匙串等）
- Cookie / Session：session 的权威状态通常在服务端，客户端更多是保存一个 session 标识（Cookie）

### 登录态延续：客户端侧的最小职责是什么

对客户端来说，“登录态延续”至少包括两部分：

1. 登录成功后，把“身份材料”保存到某个可被后续请求访问的位置
2. 每次访问受保护接口时，把身份材料写到请求里（Header 或 Cookie）

本章会刻意把“保存到哪里”保持在最小实现：

- **先用内存保存**（例如进程内的 `AuthState`）
- 不讨论 Keychain、安全持久化与 token 刷新

原因很简单：如果这些基础职责边界不清晰，你很容易在工程里把鉴权逻辑散落一地；而如果你一上来就引入完整的安全与刷新体系，又会把学习重心从“HTTP 请求到底怎么被构造”带偏。

### 这些东西在代码里应该放在哪里（衔接第 39 章）

在第 39 章，我们希望形成一种稳定结构：

```text
Endpoint -> URLRequest -> NetworkClient -> DTO
```

那么“鉴权”应该插在哪里？

- 它应该发生在 **URLRequest 被发送之前**
- 它不应该污染 DTO（DTO 只管 JSON 结构）
- 它最好不要散落到每个具体 API 方法里重复写

这里给出一个“最小但可读”的方案：**不推翻第 39 章的 `Endpoint` 契约**，只是在原有请求描述上增加“是否需要鉴权”的意图字段；“具体 token 是什么”仍由调用方（或上层服务）提供。

#### 1) 给 Endpoint 增加最小鉴权意图

```swift
enum AuthRequirement {
    case none
    case bearerToken
    case cookieSession
}
```

你可以把第 39 章的 `Endpoint` 扩展成下面这个版本，用来表达“这个接口是否受保护”：

```swift
struct Endpoint {
    var path: String
    var method: HTTPMethod
    var queryItems: [URLQueryItem] = []
    var headers: [String: String] = [:]
    var body: Data? = nil
    var auth: AuthRequirement = .none
}
```

这里 `auth` 表达的是“意图”，不是“实现细节”。这样做的好处是：

- 调用方一眼就知道哪些接口需要登录态
- 网络层仍然保持最小职责，不会引入复杂的拦截器/中间件体系

#### 2) 在构造 URLRequest 时写入鉴权信息

假设你有一个 `AuthState` 用于保存当前登录态：

```swift
struct AuthState {
    var bearerToken: String?
    // Cookie/session 模式通常由系统 Cookie 存储承担，这里先不人为重复保存。
}
```

当你把 `Endpoint` 转成 `URLRequest` 时，可以**先沿用第 39 章已有的 `makeRequest(baseURL:)`**，再按 `auth` 决定要不要加头：

```swift
enum AuthError: Error {
    case notLoggedIn
}

extension Endpoint {
    func makeAuthenticatedRequest(baseURL: URL, authState: AuthState) throws -> URLRequest {
        var request = try makeRequest(baseURL: baseURL)

        switch auth {
        case .none:
            break
        case .bearerToken:
            guard let token = authState.bearerToken else {
                throw AuthError.notLoggedIn
            }
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        case .cookieSession:
            // 通常不需要手动写 Cookie 头，交给 URLSession / HTTPCookieStorage。
            // 这里保留分支是为了让“受保护接口”的意图在代码结构中可见。
            break
        }

        return request
    }
}
```

这段代码刻意保持“最小而直白”：

- 它没有引入通用拦截器链
- 它把鉴权头的写入放在了请求构造阶段
- 它对“未登录”的情况给了一个明确错误（方便上层做 UI/提示）

你后续当然可以抽象得更优雅，但本章优先保证你能读懂“身份信息到底什么时候被放进请求”。

#### 3) 401 的处理：清理状态还是保留？

当某个受保护接口返回 401 时，通常意味着你持有的凭证已经失效。

在“只做最小实现”的前提下，一个合理策略是：

- 将 `AuthState.bearerToken` 置空
- 上层捕获到错误后提示重新登录

但请注意：这只是教学级策略。真实生产环境里，你可能会有“刷新 token”流程，可能会需要更谨慎的并发处理。本章不覆盖这些内容。

### 小结：把边界讲清楚，才能写出不散架的代码

到这里，你应该能把下面这句话落到代码上：

- “鉴权信息是请求的通用上下文，通常通过 Header/Cookie 携带；登录态延续就是把这份信息稳定地带到后续请求里。”

当你在第 41 章继续扩展查询参数、分页、超时与下载时，你会发现：

- 这些能力本质上仍然发生在“构造请求 / 发送请求 / 读取响应”的链路上
- 只要你把每一类变化放在合适的位置，网络层就不会越写越乱

## 边界说明

为了避免让读者误以为“鉴权体系已经完整覆盖”，本章明确不包含以下内容：

- 不实现注册、找回密码、多角色权限系统等账号体系内容
- 不讲 token 安全存储（Keychain 等）、持久化策略、token 刷新/续期策略
- 不讲 CSRF、防重放、会话固定等更深入的安全议题
- 不讲在 UI 层如何做登录页、全局路由守卫、自动跳转等界面工程问题
- 不引入复杂拦截器链、通用中间件体系；本章只给出“最小可读”的落点

~~(真写了你们又看不懂)~~

如果你准备把这章的思路用于真实应用，请把它当作“理解请求构造与职责边界”的起点，而不是终点。
