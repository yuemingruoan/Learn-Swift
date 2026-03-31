//
//  main.swift
//  43-codable-persistence-and-local-cache
//
//  Created by Codex on 2026/3/31.
//

import Foundation

struct TodoDTO: Decodable {
    let id: Int
    let title: String
    let completed: Bool
}

struct TodoSnapshot: Codable, Equatable {
    let id: Int
    let title: String
    let isDone: Bool

    init(dto: TodoDTO) {
        self.id = dto.id
        self.title = dto.title
        self.isDone = dto.completed
    }
}

struct CacheEnvelope<Value: Codable>: Codable {
    let cachedAt: Date
    let value: Value
}

enum CacheWriteError: Error {
    case encodeFailed(underlying: Error)
    case writeFailed(underlying: Error)
}

enum CacheReadError: Error {
    case readFailed(underlying: Error)
    case decodeFailed(underlying: Error)
}

enum CacheLoadResult<Value> {
    case hit(Value)
    case miss
    case corrupted(underlying: Error)
}

enum DataSource<Value> {
    case cache(Value)
    case remote(Value)
}

enum AppPaths {
    static func cacheFileURL(fileName: String) throws -> URL {
        let fm = FileManager.default
        let base = try fm.url(
            for: .cachesDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )

        let folder = base
            .appendingPathComponent("learn-swift", isDirectory: true)
            .appendingPathComponent("43-cache-demo", isDirectory: true)

        try fm.createDirectory(at: folder, withIntermediateDirectories: true)
        return folder.appendingPathComponent(fileName)
    }
}

func saveSnapshot<T: Encodable>(_ value: T, to fileURL: URL) throws {
    do {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(value)
        try data.write(to: fileURL, options: [.atomic])
    } catch let error as EncodingError {
        throw CacheWriteError.encodeFailed(underlying: error)
    } catch {
        throw CacheWriteError.writeFailed(underlying: error)
    }
}

func loadSnapshot<T: Decodable>(_ type: T.Type, from fileURL: URL) throws -> T? {
    do {
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            return nil
        }

        let data = try Data(contentsOf: fileURL)
        return try JSONDecoder().decode(T.self, from: data)
    } catch let error as DecodingError {
        throw CacheReadError.decodeFailed(underlying: error)
    } catch {
        throw CacheReadError.readFailed(underlying: error)
    }
}

func loadCacheOrReportCorruption<T: Decodable>(_ type: T.Type, from fileURL: URL) -> CacheLoadResult<T> {
    do {
        if let value = try loadSnapshot(T.self, from: fileURL) {
            return .hit(value)
        }
        return .miss
    } catch {
        return .corrupted(underlying: error)
    }
}

func deleteFileIfExists(_ url: URL) {
    do {
        if FileManager.default.fileExists(atPath: url.path) {
            try FileManager.default.removeItem(at: url)
        }
    } catch {
        print("[warn] 删除缓存失败：\(error)")
    }
}

actor FakeRemoteAPI {
    private var requestCount = 0

    func fetchTodos() async throws -> [TodoDTO] {
        requestCount += 1
        try await Task.sleep(for: .milliseconds(200))

        return [
            TodoDTO(id: 1, title: "查看今天列表（第 \(requestCount) 次远程请求）", completed: false),
            TodoDTO(id: 2, title: "保留上次成功结果", completed: true),
            TodoDTO(id: 3, title: "判断缓存是否损坏", completed: false)
        ]
    }
}

func getTodos(api: FakeRemoteAPI) async throws -> DataSource<[TodoSnapshot]> {
    let cacheURL = try AppPaths.cacheFileURL(fileName: "todos.json")

    switch loadCacheOrReportCorruption(CacheEnvelope<[TodoSnapshot]>.self, from: cacheURL) {
    case .hit(let envelope):
        print("缓存命中：读取上次成功快照，cachedAt = \(envelope.cachedAt)")
        return .cache(envelope.value)

    case .miss:
        print("缓存缺失：本地没有快照，准备走远程")

    case .corrupted(let error):
        print("缓存损坏：\(error)")
        print("执行恢复：删除坏文件，再重新请求远程")
        deleteFileIfExists(cacheURL)
    }

    let dtos = try await api.fetchTodos()
    let snapshots = dtos.map(TodoSnapshot.init(dto:))

    do {
        let envelope = CacheEnvelope(cachedAt: Date(), value: snapshots)
        try saveSnapshot(envelope, to: cacheURL)
        print("远程成功：已把最新待办快照写回缓存")
    } catch {
        print("[warn] 回写缓存失败，但不影响主流程：\(error)")
    }

    return .remote(snapshots)
}

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

        printDivider("第 1 次读取：缓存缺失 -> 远程 -> 回写缓存")
        let first = try await getTodos(api: api)
        switch first {
        case .cache(let todos):
            printTodos(todos, source: "cache")
        case .remote(let todos):
            printTodos(todos, source: "remote")
        }

        printDivider("第 2 次读取：缓存命中 -> 直接返回快照")
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

        printDivider("第 3 次读取：损坏 -> 删除坏文件 -> 重新拉远程")
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
