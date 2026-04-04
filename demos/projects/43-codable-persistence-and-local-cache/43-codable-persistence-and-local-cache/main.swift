//
//  main.swift
//  43-codable-persistence-and-local-cache
//
//  Created by Codex on 2026/4/4.
//

import Foundation

func printTodos(_ todos: [TodoSnapshot], source: String) {
    print("来源：\(source)")
    for todo in todos {
        let status = todo.isDone ? "已完成" : "未完成"
        print("- [\(status)] #\(todo.id) \(todo.title)")
    }
}

func printDivider(_ title: String) {
    print("\n======== \(title) ========")
}

func runDemo() async {
    do {
        let cacheURL = try AppPaths.cacheFileURL(fileName: "todos.json")
        let api = FakeRemoteAPI()

        printDivider("准备阶段")
        print("缓存文件：\(cacheURL.path)")
        deleteFileIfExists(cacheURL)
        print("已清理旧缓存，确保演示从 miss 开始")

        printDivider("第 1 次读取：miss -> remote -> write")
        let first = try await getTodos(api: api)
        switch first {
        case .cache(let todos):
            printTodos(todos, source: "cache")
        case .remote(let todos):
            printTodos(todos, source: "remote")
        }

        printDivider("第 2 次读取：hit -> 直接返回快照")
        let second = try await getTodos(api: api)
        switch second {
        case .cache(let todos):
            printTodos(todos, source: "cache")
        case .remote(let todos):
            printTodos(todos, source: "remote")
        }

        printDivider("模拟缓存损坏")
        try "not a valid json".write(to: cacheURL, atomically: true, encoding: .utf8)
        print("已手动写入损坏内容")

        printDivider("第 3 次读取：corrupted -> delete bad file -> remote")
        let third = try await getTodos(api: api)
        switch third {
        case .cache(let todos):
            printTodos(todos, source: "cache")
        case .remote(let todos):
            printTodos(todos, source: "remote")
        }
    } catch {
        print("Demo 运行失败：\(error)")
    }
}

let demoSemaphore = DispatchSemaphore(value: 0)
Task {
    await runDemo()
    demoSemaphore.signal()
}
demoSemaphore.wait()
