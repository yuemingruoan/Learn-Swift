//
//  main.swift
//  40-authentication-headers-and-session-continuity
//
//  Created by Codex on 2026/3/31.
//

import Foundation

enum APIConfig {
    static let baseURL = URL(string: "http://127.0.0.1:3456")!
}

enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
}

enum AuthRequirement {
    case none
    case bearerToken
    case cookieSession
}

final class AuthState {
    var bearerToken: String?
    var sessionCookie: String?
}

struct Endpoint {
    var path: String
    var method: HTTPMethod
    var queryItems: [URLQueryItem] = []
    var headers: [String: String] = [:]
    var body: Data? = nil
    var auth: AuthRequirement = .none
}

struct TodoDTO: Decodable {
    let userId: Int
    let id: Int
    let title: String
    let completed: Bool
}

struct LoginRequestDTO: Encodable {
    let username: String
    let password: String
}

struct UserProfileDTO: Decodable {
    let id: Int
    let username: String
    let name: String
    let role: String
    let preferredTrack: String
}

struct TokenLoginResponseDTO: Decodable {
    let accessToken: String
    let tokenType: String
    let expiresIn: Int
    let user: UserProfileDTO
}

struct SessionLoginResponseDTO: Decodable {
    let message: String
    let user: UserProfileDTO
}

enum NetworkError: Error {
    case urlConstructionFailed
    case requestBodyEncodingFailed(underlying: Error)
    case transportFailed(underlying: Error)
    case nonHTTPResponse
    case badStatusCode(code: Int, body: Data?)
    case decodingFailed(underlying: Error, body: Data)
    case notLoggedIn
}

extension Endpoint {
    func makeRequest(baseURL: URL, authState: AuthState?) throws -> URLRequest {
        guard var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: false) else {
            throw NetworkError.urlConstructionFailed
        }

        let normalizedPath = path.hasPrefix("/") ? path : "/" + path
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

        for (key, value) in headers {
            request.setValue(value, forHTTPHeaderField: key)
        }

        request.httpBody = body

        switch auth {
        case .none:
            break
        case .bearerToken:
            guard let token = authState?.bearerToken else {
                throw NetworkError.notLoggedIn
            }
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        case .cookieSession:
            guard let sessionCookie = authState?.sessionCookie else {
                throw NetworkError.notLoggedIn
            }
            request.setValue(sessionCookie, forHTTPHeaderField: "Cookie")
        }

        return request
    }

    static func todoList(limit: Int) -> Endpoint {
        Endpoint(
            path: "/todos",
            method: .get,
            queryItems: [URLQueryItem(name: "limit", value: String(limit))]
        )
    }

    static func tokenLogin(username: String, password: String) throws -> Endpoint {
        do {
            let body = try JSONEncoder().encode(LoginRequestDTO(username: username, password: password))
            return Endpoint(
                path: "/auth/token-login",
                method: .post,
                headers: ["Content-Type": "application/json"],
                body: body
            )
        } catch {
            throw NetworkError.requestBodyEncodingFailed(underlying: error)
        }
    }

    static func tokenMe() -> Endpoint {
        Endpoint(path: "/auth/token-me", method: .get, auth: .bearerToken)
    }

    static func adminReport() -> Endpoint {
        Endpoint(path: "/auth/admin-report", method: .get, auth: .bearerToken)
    }

    static func sessionLogin(username: String, password: String) throws -> Endpoint {
        do {
            let body = try JSONEncoder().encode(LoginRequestDTO(username: username, password: password))
            return Endpoint(
                path: "/auth/session-login",
                method: .post,
                headers: ["Content-Type": "application/json"],
                body: body
            )
        } catch {
            throw NetworkError.requestBodyEncodingFailed(underlying: error)
        }
    }

    static func sessionMe() -> Endpoint {
        Endpoint(path: "/auth/session-me", method: .get, auth: .cookieSession)
    }
}

struct NetworkClient {
    let baseURL: URL
    let session: URLSession
    let authState: AuthState
    let decoder: JSONDecoder

    init(
        baseURL: URL,
        session: URLSession = .shared,
        authState: AuthState,
        decoder: JSONDecoder = JSONDecoder()
    ) {
        self.baseURL = baseURL
        self.session = session
        self.authState = authState
        self.decoder = decoder
    }

    func send<T: Decodable>(_ endpoint: Endpoint, as type: T.Type) async throws -> T {
        let request = try endpoint.makeRequest(baseURL: baseURL, authState: authState)
        return try await send(request, as: type)
    }

    func sendWithResponse<T: Decodable>(_ endpoint: Endpoint, as type: T.Type) async throws -> (T, HTTPURLResponse) {
        let request = try endpoint.makeRequest(baseURL: baseURL, authState: authState)
        let (data, httpResponse) = try await loadData(for: request)

        do {
            return (try decoder.decode(T.self, from: data), httpResponse)
        } catch {
            throw NetworkError.decodingFailed(underlying: error, body: data)
        }
    }

    func send<T: Decodable>(_ request: URLRequest, as type: T.Type) async throws -> T {
        let (data, _) = try await loadData(for: request)

        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw NetworkError.decodingFailed(underlying: error, body: data)
        }
    }

    private func loadData(for request: URLRequest) async throws -> (Data, HTTPURLResponse) {
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

        return (data, httpResponse)
    }
}

func printDivider(_ title: String) {
    print("")
    print("======== \(title) ========")
}

func bodyPreview(from data: Data?) -> String {
    guard
        let data,
        !data.isEmpty,
        let text = String(data: data, encoding: .utf8)
    else {
        return "<empty>"
    }

    return text.replacingOccurrences(of: "\n", with: " ")
}

func printUser(_ user: UserProfileDTO) {
    print("用户：\(user.name) (@\(user.username))")
    print("角色：\(user.role)")
    print("偏好主线：\(user.preferredTrack)")
}

func parseCookieHeader(from httpResponse: HTTPURLResponse) -> String? {
    guard let setCookie = httpResponse.value(forHTTPHeaderField: "Set-Cookie") else {
        return nil
    }

    return setCookie.split(separator: ";").first.map(String.init)
}

func printError(_ error: Error) {
    switch error {
    case NetworkError.notLoggedIn:
        print("错误：当前 endpoint 需要登录态，但本地还没有 token。")
    case NetworkError.urlConstructionFailed:
        print("错误：URL 构造失败。")
    case let NetworkError.requestBodyEncodingFailed(underlying):
        print("错误：请求体编码失败 -> \(underlying)")
    case let NetworkError.transportFailed(underlying):
        print("错误：发送阶段失败 -> \(underlying)")
    case NetworkError.nonHTTPResponse:
        print("错误：响应不是 HTTPURLResponse。")
    case let NetworkError.badStatusCode(code, body):
        print("错误：状态码异常 -> \(code)")
        print("响应体预览：\(bodyPreview(from: body))")
    case let NetworkError.decodingFailed(underlying, body):
        print("错误：响应体解码失败 -> \(underlying)")
        print("原始响应体：\(bodyPreview(from: body))")
    default:
        print("错误：\(error)")
    }
}

func runDemo() async {
    let tokenState = AuthState()
    let tokenClient = NetworkClient(baseURL: APIConfig.baseURL, authState: tokenState)

    let sessionState = AuthState()
    let sessionClient = NetworkClient(baseURL: APIConfig.baseURL, authState: sessionState)

    printDivider("沿用第 39 章建模：不需要鉴权的接口照常工作")
    do {
        let todos: [TodoDTO] = try await tokenClient.send(.todoList(limit: 2), as: [TodoDTO].self)
        for todo in todos {
            print("- \(todo.id) / \(todo.title)")
        }
    } catch {
        printError(error)
    }

    printDivider("Bearer Token：本地还没登录")
    do {
        let _: UserProfileDTO = try await tokenClient.send(.tokenMe(), as: UserProfileDTO.self)
    } catch {
        printError(error)
    }

    printDivider("Bearer Token：登录并保存访问令牌")
    do {
        let login = try await tokenClient.send(
            try .tokenLogin(username: "swift-demo", password: "123456"),
            as: TokenLoginResponseDTO.self
        )
        tokenState.bearerToken = login.accessToken
        print("tokenType：\(login.tokenType)")
        print("expiresIn：\(login.expiresIn)")
        printUser(login.user)
    } catch {
        printError(error)
    }

    printDivider("Bearer Token：访问受保护接口")
    do {
        let me: UserProfileDTO = try await tokenClient.send(.tokenMe(), as: UserProfileDTO.self)
        printUser(me)
    } catch {
        printError(error)
    }

    printDivider("401：token 失效或不合法")
    tokenState.bearerToken = "expired-demo-token"
    do {
        let _: UserProfileDTO = try await tokenClient.send(.tokenMe(), as: UserProfileDTO.self)
    } catch {
        printError(error)
    }
    tokenState.bearerToken = "swift-demo-token"

    printDivider("403：已登录，但没有权限")
    do {
        let _: UserProfileDTO = try await tokenClient.send(.adminReport(), as: UserProfileDTO.self)
    } catch {
        printError(error)
    }

    printDivider("Cookie / Session：登录后由 URLSession 自动带回 cookie")
    do {
        let (sessionLogin, httpResponse): (SessionLoginResponseDTO, HTTPURLResponse) = try await sessionClient.sendWithResponse(
            try .sessionLogin(username: "swift-demo", password: "123456"),
            as: SessionLoginResponseDTO.self
        )
        sessionState.sessionCookie = parseCookieHeader(from: httpResponse)
        print("session 登录结果：\(sessionLogin.message)")
        print("收到的 Cookie：\(sessionState.sessionCookie ?? "<none>")")
        printUser(sessionLogin.user)
    } catch {
        printError(error)
    }

    printDivider("Cookie / Session：再次请求，不手写 Authorization")
    do {
        let me: UserProfileDTO = try await sessionClient.send(.sessionMe(), as: UserProfileDTO.self)
        printUser(me)
    } catch {
        printError(error)
    }

    printDivider("这一章的收益")
    print("第 39 章的 Endpoint / NetworkClient 没有被推翻，只是增加了 auth 意图。")
    print("Bearer Token 和 Cookie / Session 只是“请求怎么带身份”不同，主线建模仍然一致。")
}

let demoSemaphore = DispatchSemaphore(value: 0)

Task {
    await runDemo()
    demoSemaphore.signal()
}

demoSemaphore.wait()
