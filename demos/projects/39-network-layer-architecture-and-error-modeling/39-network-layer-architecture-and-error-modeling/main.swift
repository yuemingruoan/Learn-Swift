//
//  main.swift
//  39-network-layer-architecture-and-error-modeling
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

struct Endpoint {
    var path: String
    var method: HTTPMethod
    var queryItems: [URLQueryItem] = []
    var headers: [String: String] = [:]
    var body: Data? = nil
}

struct TodoDTO: Decodable {
    let userId: Int
    let id: Int
    let title: String
    let completed: Bool
}

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

enum NetworkError: Error {
    case urlConstructionFailed
    case requestBodyEncodingFailed(underlying: Error)
    case transportFailed(underlying: Error)
    case nonHTTPResponse
    case badStatusCode(code: Int, body: Data?)
    case decodingFailed(underlying: Error, body: Data)
}

extension Endpoint {
    func makeRequest(baseURL: URL) throws -> URLRequest {
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
        return request
    }

    static func todoDetail(id: Int) -> Endpoint {
        Endpoint(path: "/todos/\(id)", method: .get)
    }

    static func todoList(limit: Int) -> Endpoint {
        Endpoint(
            path: "/todos",
            method: .get,
            queryItems: [URLQueryItem(name: "limit", value: String(limit))]
        )
    }

    static func createStudyRecord(_ input: CreateStudyRecordRequestDTO) throws -> Endpoint {
        do {
            let body = try JSONEncoder().encode(input)
            return Endpoint(
                path: "/study-records",
                method: .post,
                headers: ["Content-Type": "application/json"],
                body: body
            )
        } catch {
            throw NetworkError.requestBodyEncodingFailed(underlying: error)
        }
    }

    static func badTodoJSON() -> Endpoint {
        Endpoint(path: "/diagnostics/bad-todo-json", method: .get)
    }

    static func serverError() -> Endpoint {
        Endpoint(path: "/diagnostics/server-error", method: .get)
    }
}

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

func printDivider(_ title: String) {
    print("")
    print("======== \(title) ========")
}

func printTodo(_ todo: TodoDTO) {
    print("任务 ID：\(todo.id)")
    print("标题：\(todo.title)")
    print("完成状态：\(todo.completed ? "已完成" : "未完成")")
}

func printStudyRecord(_ record: StudyRecordResponseDTO) {
    print("记录 ID：\(record.id)")
    print("章节：\(record.chapter)")
    print("标题：\(record.title)")
    print("时长：\(record.durationMinutes) 分钟")
    print("服务端状态：\(record.status)")
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

func printError(_ error: Error) {
    switch error {
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
    let client = NetworkClient(baseURL: APIConfig.baseURL)

    printDivider("沿用第 38 章能力，但不再复制粘贴请求代码")
    do {
        let detail: TodoDTO = try await client.send(.todoDetail(id: 1), as: TodoDTO.self)
        let list: [TodoDTO] = try await client.send(.todoList(limit: 3), as: [TodoDTO].self)

        print("详情接口：")
        printTodo(detail)
        print("")
        print("列表接口：")
        for todo in list {
            print("- \(todo.id) / \(todo.title)")
        }
    } catch {
        printError(error)
    }

    printDivider("POST 也走同一套模型")
    do {
        let input = CreateStudyRecordRequestDTO(
            chapter: 39,
            title: "把单接口请求函数升级成 NetworkClient",
            durationMinutes: 30
        )

        let record: StudyRecordResponseDTO = try await client.send(
            try .createStudyRecord(input),
            as: StudyRecordResponseDTO.self
        )
        printStudyRecord(record)
    } catch {
        printError(error)
    }

    printDivider("状态码错误：找不到任务")
    do {
        let _: TodoDTO = try await client.send(.todoDetail(id: 999), as: TodoDTO.self)
    } catch {
        printError(error)
    }

    printDivider("解码错误：接口返回的 JSON 结构不匹配")
    do {
        let _: TodoDTO = try await client.send(.badTodoJSON(), as: TodoDTO.self)
    } catch {
        printError(error)
    }

    printDivider("服务端错误：统一从 NetworkClient 往外抛")
    do {
        let _: TodoDTO = try await client.send(.serverError(), as: TodoDTO.self)
    } catch {
        printError(error)
    }

    printDivider("这一章的收益")
    print("调用方现在主要表达两件事：请求什么、解码成什么。")
    print("URL 拼装、状态码检查、解码失败分类，都已经收口到 NetworkClient。")
}

let demoSemaphore = DispatchSemaphore(value: 0)

Task {
    await runDemo()
    demoSemaphore.signal()
}

demoSemaphore.wait()
