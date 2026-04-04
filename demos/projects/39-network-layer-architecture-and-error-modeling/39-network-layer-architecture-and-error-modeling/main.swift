//
//  main.swift
//  39-network-layer-architecture-and-error-modeling
//
//  Created by Codex on 2026/4/4.
//

import Foundation

func printDivider(_ title: String) {
    print("\n======== \(title) ========")
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

func printStageHeader(endpoint: Endpoint, expectation: String) {
    let request = try? endpoint.makeRequest(baseURL: APIConfig.baseURL)
    print("期望：\(expectation)")
    print("方法：\(endpoint.method.rawValue)")
    print("URL：\(request?.url?.absoluteString ?? "<invalid>")")
}

func runDemo() async {
    let client = NetworkClient(baseURL: APIConfig.baseURL)

    printDivider("成功 GET：调用方只关心 endpoint 和 DTO")
    do {
        let endpoint = Endpoint.todoDetail(id: 1)
        printStageHeader(endpoint: endpoint, expectation: "成功解码单个 TodoDTO")
        let detail: TodoDTO = try await client.send(endpoint, as: TodoDTO.self)
        printTodo(detail)
    } catch {
        printError(error)
    }

    printDivider("成功 POST：同一套客户端负责请求体编码后的发送")
    do {
        let input = CreateStudyRecordRequestDTO(
            chapter: 39,
            title: "把请求结构收口到 Endpoint + NetworkClient",
            durationMinutes: 30
        )
        let endpoint = try Endpoint.createStudyRecord(input)
        printStageHeader(endpoint: endpoint, expectation: "成功解码 StudyRecordResponseDTO")
        let record: StudyRecordResponseDTO = try await client.send(endpoint, as: StudyRecordResponseDTO.self)
        printStudyRecord(record)
    } catch {
        printError(error)
    }

    printDivider("状态码错误：失败发生在 transport 之后、decode 之前")
    do {
        let endpoint = Endpoint.todoDetail(id: 999)
        printStageHeader(endpoint: endpoint, expectation: "触发 badStatusCode")
        let _: TodoDTO = try await client.send(endpoint, as: TodoDTO.self)
    } catch {
        printError(error)
    }

    printDivider("解码错误：请求成功，但 DTO 结构不匹配")
    do {
        let endpoint = Endpoint.badTodoJSON()
        printStageHeader(endpoint: endpoint, expectation: "触发 decodingFailed")
        let _: TodoDTO = try await client.send(endpoint, as: TodoDTO.self)
    } catch {
        printError(error)
    }
}

let semaphore = DispatchSemaphore(value: 0)
Task {
    await runDemo()
    semaphore.signal()
}
semaphore.wait()
