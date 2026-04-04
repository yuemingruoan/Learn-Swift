//
//  main.swift
//  40-authentication-headers-and-session-continuity
//
//  Created by Codex on 2026/4/4.
//

import Foundation

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

func printRequestPreview(_ request: URLRequest, mode: String) {
    print("鉴权模式：\(mode)")
    print("方法：\(request.httpMethod ?? "<none>")")
    print("URL：\(request.url?.absoluteString ?? "<invalid>")")
    print("Authorization：\(request.value(forHTTPHeaderField: "Authorization") ?? "<none>")")
    print("Cookie：\(request.value(forHTTPHeaderField: "Cookie") ?? "<none>")")
}

func printError(_ error: Error) {
    switch error {
    case let NetworkError.notLoggedIn(requirement):
        print("错误：\(requirement.rawValue) 所需登录态还没准备好。")
    case NetworkError.urlConstructionFailed:
        print("错误：URL 构造失败。")
    case let NetworkError.requestBodyEncodingFailed(underlying):
        print("错误：请求体编码失败 -> \(underlying)")
    case let NetworkError.transportFailed(underlying):
        print("错误：发送阶段失败 -> \(underlying)")
    case NetworkError.nonHTTPResponse:
        print("错误：响应不是 HTTPURLResponse。")
    case let NetworkError.unauthorized(requirement, body):
        print("错误：401 未认证 -> \(requirement.rawValue)")
        print("响应体预览：\(bodyPreview(from: body))")
    case let NetworkError.forbidden(requirement, body):
        print("错误：403 权限不足 -> \(requirement.rawValue)")
        print("响应体预览：\(bodyPreview(from: body))")
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
    let tokenClient = AuthenticatedNetworkClient(baseURL: APIConfig.baseURL, authState: tokenState)

    let sessionState = AuthState()
    let sessionClient = AuthenticatedNetworkClient(baseURL: APIConfig.baseURL, authState: sessionState)

    printDivider("先证明：未鉴权接口仍沿用第 39 章主线")
    do {
        let request = try tokenClient.previewRequest(for: .todoList(limit: 2))
        printRequestPreview(request, mode: "无需鉴权")
        let todos: [TodoDTO] = try await tokenClient.send(.todoList(limit: 2), as: [TodoDTO].self)
        for todo in todos {
            print("- \(todo.id) / \(todo.title)")
        }
    } catch {
        printError(error)
    }

    printDivider("Bearer Token：未登录直接访问受保护接口")
    do {
        let request = try tokenClient.previewRequest(for: .tokenMe())
        printRequestPreview(request, mode: "Bearer Token")
        let _: UserProfileDTO = try await tokenClient.send(.tokenMe(), as: UserProfileDTO.self)
    } catch {
        printError(error)
    }

    printDivider("Bearer Token：登录后把 token 收口到 AuthState")
    do {
        let login = try await tokenClient.send(
            try .tokenLogin(username: "swift-demo", password: "123456"),
            as: TokenLoginResponseDTO.self
        )
        tokenState.bearerToken = login.accessToken
        print("tokenType：\(login.tokenType)")
        print("expiresIn：\(login.expiresIn)")
        print("当前 bearerToken：\(tokenState.bearerToken ?? "<none>")")
        printUser(login.user)
    } catch {
        printError(error)
    }

    printDivider("Bearer Token：后续请求沿当前网络层自动带身份")
    do {
        let request = try tokenClient.previewRequest(for: .tokenMe())
        printRequestPreview(request, mode: "Bearer Token")
        let me: UserProfileDTO = try await tokenClient.send(.tokenMe(), as: UserProfileDTO.self)
        printUser(me)
    } catch {
        printError(error)
    }

    printDivider("401：token 失效后清理本地状态，并提示重新登录")
    tokenState.bearerToken = "expired-demo-token"
    do {
        let request = try tokenClient.previewRequest(for: .tokenMe())
        printRequestPreview(request, mode: "Bearer Token")
        let _: UserProfileDTO = try await tokenClient.send(.tokenMe(), as: UserProfileDTO.self)
    } catch {
        printError(error)
        print("401 后 bearerToken 是否已清空：\(tokenState.bearerToken == nil ? "是" : "否")")
    }

    printDivider("403：已登录，不等于有权限")
    tokenState.bearerToken = "swift-demo-token"
    do {
        let request = try tokenClient.previewRequest(for: .adminReport())
        printRequestPreview(request, mode: "Bearer Token")
        let _: UserProfileDTO = try await tokenClient.send(.adminReport(), as: UserProfileDTO.self)
    } catch {
        printError(error)
        print("调用方结论：这是权限不足，不是未登录。")
    }

    printDivider("Cookie / Session：登录后保存 Cookie，而不是散落到每个请求函数")
    do {
        let (sessionLogin, httpResponse): (SessionLoginResponseDTO, HTTPURLResponse) = try await sessionClient.sendWithResponse(
            try .sessionLogin(username: "swift-demo", password: "123456"),
            as: SessionLoginResponseDTO.self
        )
        sessionState.sessionCookie = parseCookieHeader(from: httpResponse)
        print("session 登录结果：\(sessionLogin.message)")
        print("当前 sessionCookie：\(sessionState.sessionCookie ?? "<none>")")
        printUser(sessionLogin.user)
    } catch {
        printError(error)
    }

    printDivider("Cookie / Session：再次请求时走同一条发送链路")
    do {
        let request = try sessionClient.previewRequest(for: .sessionMe())
        printRequestPreview(request, mode: "Cookie / Session")
        let me: UserProfileDTO = try await sessionClient.send(.sessionMe(), as: UserProfileDTO.self)
        printUser(me)
    } catch {
        printError(error)
    }

    printDivider("这一章的收益")
    print("AuthState 负责保存登录态，AuthRequestDecorator 负责把身份写进请求。")
    print("AuthenticatedNetworkClient 继续负责统一发送、查状态码、解码，而不是把 token/cookie 逻辑散落到每个 endpoint。")
}

let demoSemaphore = DispatchSemaphore(value: 0)

Task {
    await runDemo()
    demoSemaphore.signal()
}

demoSemaphore.wait()
