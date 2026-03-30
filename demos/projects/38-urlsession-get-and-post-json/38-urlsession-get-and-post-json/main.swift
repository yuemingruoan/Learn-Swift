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
    case invalidResponse
    case badStatusCode(Int)
    case requestEncodingFailed(Error)
    case responseDecodingFailed(Error)
}

func printDivider(title: String) {
    print("")
    print("======== \(title) ========")
}

func validateHTTPResponse(_ response: URLResponse) throws -> HTTPURLResponse {
    guard let httpResponse = response as? HTTPURLResponse else {
        throw NetworkError.invalidResponse
    }

    guard (200...299).contains(httpResponse.statusCode) else {
        throw NetworkError.badStatusCode(httpResponse.statusCode)
    }

    return httpResponse
}

func fetchTodo() async throws -> TodoDTO {
    guard let url = URL(string: "\(APIConfig.baseURLString)/todos/1") else {
        throw NetworkError.invalidURL
    }

    let (data, response) = try await URLSession.shared.data(from: url)
    let httpResponse = try validateHTTPResponse(response)
    print("GET /todos/1 状态码：\(httpResponse.statusCode)")

    do {
        return try JSONDecoder().decode(TodoDTO.self, from: data)
    } catch {
        throw NetworkError.responseDecodingFailed(error)
    }
}

func fetchTodoList(limit: Int) async throws -> [TodoDTO] {
    guard var components = URLComponents(string: "\(APIConfig.baseURLString)/todos") else {
        throw NetworkError.invalidURL
    }

    components.queryItems = [
        URLQueryItem(name: "limit", value: String(limit))
    ]

    guard let url = components.url else {
        throw NetworkError.invalidURL
    }

    let (data, response) = try await URLSession.shared.data(from: url)
    let httpResponse = try validateHTTPResponse(response)
    print("GET /todos?limit=\(limit) 状态码：\(httpResponse.statusCode)")

    do {
        return try JSONDecoder().decode([TodoDTO].self, from: data)
    } catch {
        throw NetworkError.responseDecodingFailed(error)
    }
}

func createStudyRecord(_ input: CreateStudyRecordRequestDTO) async throws -> StudyRecordResponseDTO {
    guard let url = URL(string: "\(APIConfig.baseURLString)/study-records") else {
        throw NetworkError.invalidURL
    }

    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")

    do {
        request.httpBody = try JSONEncoder().encode(input)
    } catch {
        throw NetworkError.requestEncodingFailed(error)
    }

    let (data, response) = try await URLSession.shared.data(for: request)
    let httpResponse = try validateHTTPResponse(response)
    print("POST /study-records 状态码：\(httpResponse.statusCode)")

    do {
        return try JSONDecoder().decode(StudyRecordResponseDTO.self, from: data)
    } catch {
        throw NetworkError.responseDecodingFailed(error)
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
        print("错误：URL 不合法。")
    case NetworkError.invalidResponse:
        print("错误：响应不是 HTTPURLResponse。")
    case let NetworkError.badStatusCode(statusCode):
        print("错误：HTTP 状态码异常 -> \(statusCode)")
    case let NetworkError.requestEncodingFailed(underlyingError):
        print("错误：请求体编码失败 -> \(underlyingError)")
    case let NetworkError.responseDecodingFailed(underlyingError):
        print("错误：响应体解码失败 -> \(underlyingError)")
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

    printDivider(title: "数组 GET：多个任务")
    do {
        let todos = try await fetchTodoList(limit: 3)
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
}

let demoSemaphore = DispatchSemaphore(value: 0)

Task {
    await runDemo()
    demoSemaphore.signal()
}

demoSemaphore.wait()
