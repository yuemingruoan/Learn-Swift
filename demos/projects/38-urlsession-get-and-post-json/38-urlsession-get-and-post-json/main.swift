//
//  main.swift
//  38-urlsession-get-and-post-json
//
//  Created by Codex on 2026/3/29.
//

import Foundation

enum APIConfig {
    static let baseURLString = "http://127.0.0.1:3456"
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
    case invalidURL
    case transportFailed(Error)
    case invalidResponse
    case badStatusCode(Int, Data?)
    case requestEncodingFailed(Error)
    case responseDecodingFailed(target: String, underlying: Error, body: Data)
}

func printDivider(title: String) {
    print("")
    print("======== \(title) ========")
}

func bodyPreview(_ data: Data?) -> String {
    guard
        let data,
        !data.isEmpty,
        let text = String(data: data, encoding: .utf8)
    else {
        return "<empty>"
    }

    return text.replacingOccurrences(of: "\n", with: " ")
}

func printRequestInfo(method: String, url: URL, decodeTarget: String) {
    print("请求方式：\(method)")
    print("URL：\(url.absoluteString)")
    print("解码目标：\(decodeTarget)")
}

func loadData(using request: URLRequest) async throws -> (Data, HTTPURLResponse) {
    let data: Data
    let response: URLResponse

    do {
        (data, response) = try await URLSession.shared.data(for: request)
    } catch {
        throw NetworkError.transportFailed(error)
    }

    let httpResponse = try validateHTTPResponse(response, body: data)
    return (data, httpResponse)
}

func validateHTTPResponse(_ response: URLResponse, body: Data?) throws -> HTTPURLResponse {
    guard let httpResponse = response as? HTTPURLResponse else {
        throw NetworkError.invalidResponse
    }

    guard (200...299).contains(httpResponse.statusCode) else {
        throw NetworkError.badStatusCode(httpResponse.statusCode, body)
    }

    return httpResponse
}

func fetchTodo() async throws -> TodoDTO {
    guard let url = URL(string: "\(APIConfig.baseURLString)/todos/1") else {
        throw NetworkError.invalidURL
    }

    printRequestInfo(method: "GET", url: url, decodeTarget: "TodoDTO")

    var request = URLRequest(url: url)
    request.httpMethod = "GET"

    let (data, httpResponse) = try await loadData(using: request)
    print("状态码：\(httpResponse.statusCode)")

    do {
        return try JSONDecoder().decode(TodoDTO.self, from: data)
    } catch {
        throw NetworkError.responseDecodingFailed(target: "TodoDTO", underlying: error, body: data)
    }
}

func fetchTodoWithExplicitRequest(limit: Int) async throws -> [TodoDTO] {
    guard var components = URLComponents(string: "\(APIConfig.baseURLString)/todos") else {
        throw NetworkError.invalidURL
    }

    components.queryItems = [
        URLQueryItem(name: "limit", value: String(limit))
    ]

    guard let url = components.url else {
        throw NetworkError.invalidURL
    }

    printRequestInfo(method: "GET", url: url, decodeTarget: "[TodoDTO]")

    var request = URLRequest(url: url)
    request.httpMethod = "GET"

    let (data, httpResponse) = try await loadData(using: request)
    print("状态码：\(httpResponse.statusCode)")

    do {
        return try JSONDecoder().decode([TodoDTO].self, from: data)
    } catch {
        throw NetworkError.responseDecodingFailed(target: "[TodoDTO]", underlying: error, body: data)
    }
}

func createStudyRecord(_ input: CreateStudyRecordRequestDTO) async throws -> StudyRecordResponseDTO {
    guard let url = URL(string: "\(APIConfig.baseURLString)/study-records") else {
        throw NetworkError.invalidURL
    }

    printRequestInfo(method: "POST", url: url, decodeTarget: "StudyRecordResponseDTO")

    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")

    do {
        request.httpBody = try JSONEncoder().encode(input)
    } catch {
        throw NetworkError.requestEncodingFailed(error)
    }

    let (data, httpResponse) = try await loadData(using: request)
    print("状态码：\(httpResponse.statusCode)")

    do {
        return try JSONDecoder().decode(StudyRecordResponseDTO.self, from: data)
    } catch {
        throw NetworkError.responseDecodingFailed(target: "StudyRecordResponseDTO", underlying: error, body: data)
    }
}

func fetchMissingTodoStatusDemo() async throws {
    guard let url = URL(string: "\(APIConfig.baseURLString)/todos/999999") else {
        throw NetworkError.invalidURL
    }

    printRequestInfo(method: "GET", url: url, decodeTarget: "TodoDTO")

    var request = URLRequest(url: url)
    request.httpMethod = "GET"

    let (_, httpResponse) = try await loadData(using: request)
    print("状态码：\(httpResponse.statusCode)")
}

func fetchTodoWithWrongDecodeTarget() async throws {
    guard let url = URL(string: "\(APIConfig.baseURLString)/todos/1") else {
        throw NetworkError.invalidURL
    }

    printRequestInfo(method: "GET", url: url, decodeTarget: "[TodoDTO]（故意写错）")

    var request = URLRequest(url: url)
    request.httpMethod = "GET"

    let (data, httpResponse) = try await loadData(using: request)
    print("状态码：\(httpResponse.statusCode)")

    do {
        let _: [TodoDTO] = try JSONDecoder().decode([TodoDTO].self, from: data)
    } catch {
        throw NetworkError.responseDecodingFailed(target: "[TodoDTO]（故意写错）", underlying: error, body: data)
    }
}

func printTodo(_ todo: TodoDTO) {
    let status = todo.completed ? "已完成" : "未完成"
    print("任务 ID：\(todo.id)")
    print("用户 ID：\(todo.userId)")
    print("标题：\(todo.title)")
    print("完成状态：\(status)")
}

func printStudyRecord(_ record: StudyRecordResponseDTO) {
    print("记录 ID：\(record.id)")
    print("章节：\(record.chapter)")
    print("标题：\(record.title)")
    print("时长：\(record.durationMinutes) 分钟")
    print("服务端状态：\(record.status)")
}

func printError(_ error: Error) {
    switch error {
    case NetworkError.invalidURL:
        print("失败层：URL 构造")
        print("错误：URL 不合法。")
    case let NetworkError.transportFailed(underlying):
        print("失败层：发送")
        print("错误：请求没有成功发出去 -> \(underlying)")
    case NetworkError.invalidResponse:
        print("失败层：响应类型")
        print("错误：响应不是 HTTPURLResponse。")
    case let NetworkError.badStatusCode(statusCode, body):
        print("失败层：状态码检查")
        print("错误：HTTP 状态码异常 -> \(statusCode)")
        print("响应体预览：\(bodyPreview(body))")
    case let NetworkError.requestEncodingFailed(underlyingError):
        print("失败层：请求体编码")
        print("错误：请求体编码失败 -> \(underlyingError)")
    case let NetworkError.responseDecodingFailed(target, underlyingError, body):
        print("失败层：响应体解码")
        print("解码目标：\(target)")
        print("错误：响应体解码失败 -> \(underlyingError)")
        print("原始响应体：\(bodyPreview(body))")
    default:
        print("错误：\(error)")
    }
}

func runDemo() async {
    printDivider(title: "最小 GET：单个对象")
    do {
        let todo = try await fetchTodo()
        printTodo(todo)
    } catch {
        printError(error)
    }

    printDivider(title: "显式 URLRequest 的 GET：同样的 GET，但请求描述更完整")
    do {
        let todos = try await fetchTodoWithExplicitRequest(limit: 3)
        print("一共拿到 \(todos.count) 条任务。")
        for todo in todos {
            let status = todo.completed ? "已完成" : "未完成"
            print("- \(todo.id) / \(todo.title) / \(status)")
        }
    } catch {
        printError(error)
    }

    printDivider(title: "为什么只会 GET 还不够")
    print("GET 更擅长“拿数据”。")
    print("但真实 App 里还经常要“交数据”，例如提交学习记录。")
    print("一旦要提交 JSON，就要开始控制 method、header、body。")
    print("这也是 URLRequest 出场的时机。")

    printDivider(title: "最小 POST：提交学习记录")
    let request = CreateStudyRecordRequestDTO(
        chapter: 38,
        title: "完成 URLSession POST 练习",
        durationMinutes: 25
    )

    do {
        let record = try await createStudyRecord(request)
        printStudyRecord(record)
    } catch {
        printError(error)
    }

    printDivider(title: "失败路径 1：先查状态码，再决定是否解码")
    do {
        try await fetchMissingTodoStatusDemo()
    } catch {
        printError(error)
    }

    printDivider(title: "失败路径 2：状态码没问题，但解码目标写错")
    do {
        try await fetchTodoWithWrongDecodeTarget()
    } catch {
        printError(error)
    }
}

let demoSemaphore = DispatchSemaphore(value: 0)

Task {
    await runDemo()
    demoSemaphore.signal()
}

demoSemaphore.wait()
