//
//  main.swift
//  44-swiftdata-basics-model-container-context-and-crud
//
//  Created by Codex on 2026/3/31.
//

import Foundation
import SwiftData

// `@Model` 让这个类型进入 SwiftData 的持久化系统。
// 这里故意只保留最小字段，让 demo 焦点放在 CRUD 闭环本身。
@Model
final class TodoItem {
    var title: String
    var isDone: Bool
    var createdAt: Date
    var updatedAt: Date

    init(
        title: String,
        isDone: Bool = false,
        createdAt: Date = .now,
        updatedAt: Date = .now
    ) {
        self.title = title
        self.isDone = isDone
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

// 这层 store 不是 SwiftData 强制要求的。
// 它只是把“怎么读、怎么写”收口，避免调用点直接散落 `insert/fetch/delete/save`。
struct TodoStore {
    let context: ModelContext

    func fetchAll() throws -> [TodoItem] {
        // 用 `FetchDescriptor + SortDescriptor` 明确读取顺序，
        // 避免“看起来能跑，但顺序其实不稳定”。
        let descriptor = FetchDescriptor<TodoItem>(
            sortBy: [SortDescriptor(\TodoItem.createdAt, order: .forward)]
        )
        return try context.fetch(descriptor)
    }

    func add(title: String) throws {
        // 先创建模型对象，再插入上下文，最后显式保存。
        let item = TodoItem(title: title)
        context.insert(item)
        try context.save()
    }

    func toggle(_ item: TodoItem) throws {
        // SwiftData 管理的是对象本身；修改对象属性后再 `save()` 即可持久化。
        item.isDone.toggle()
        item.updatedAt = .now
        try context.save()
    }

    func delete(_ item: TodoItem) throws {
        context.delete(item)
        try context.save()
    }
}

enum DemoPaths {
    static func storeURL() throws -> URL {
        let fm = FileManager.default
        let caches = try fm.url(
            for: .cachesDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )

        let folder = caches
            .appendingPathComponent("learn-swift", isDirectory: true)
            .appendingPathComponent("44-swiftdata-demo", isDirectory: true)

        try fm.createDirectory(at: folder, withIntermediateDirectories: true)
        return folder.appendingPathComponent("todos.store")
    }

    static func cleanStoreFiles(at storeURL: URL) {
        // SQLite store 可能伴随 `-shm` / `-wal` 辅助文件，一起清理更稳妥。
        let fm = FileManager.default
        let candidates = [
            storeURL,
            URL(fileURLWithPath: storeURL.path + "-shm"),
            URL(fileURLWithPath: storeURL.path + "-wal")
        ]

        for url in candidates where fm.fileExists(atPath: url.path) {
            try? fm.removeItem(at: url)
        }
    }
}

func makeContainer(storeURL: URL) throws -> ModelContainer {
    // demo 这里显式指定 store 文件位置，方便每个章节互不污染。
    // 文稿正文里的最小主线仍然是：
    // `let container = try ModelContainer(for: TodoItem.self)`
    let configuration = ModelConfiguration(url: storeURL)
    return try ModelContainer(for: TodoItem.self, configurations: configuration)
}

func printDivider(_ title: String) {
    print("\n======== \(title) ========")
}

func printItems(_ items: [TodoItem]) {
    if items.isEmpty {
        print("(空)")
        return
    }

    for (index, item) in items.enumerated() {
        let status = item.isDone ? "已完成" : "未完成"
        print("\(index + 1). [\(status)] \(item.title)")
        print("   createdAt: \(item.createdAt)")
        print("   updatedAt: \(item.updatedAt)")
    }
}

func runDemo() {
    do {
        let storeURL = try DemoPaths.storeURL()

        printDivider("准备阶段")
        // 先清理旧数据，确保每次运行都从空库开始，输出更容易和文稿对应。
        DemoPaths.cleanStoreFiles(at: storeURL)
        print("SwiftData store 文件：\(storeURL.path)")
        print("已清理旧 store，确保演示从空库开始")

        printDivider("第 1 轮：把待办当本地记录做 CRUD")
        // `ModelContainer` 承载整套本地数据系统；
        // `ModelContext` 承接当前这次读写操作。
        let container1 = try makeContainer(storeURL: storeURL)
        let context1 = ModelContext(container1)
        let store1 = TodoStore(context: context1)

        try store1.add(title: "在本地新增一条待办")
        try store1.add(title: "修改单条记录而不是整份文件")

        var items = try store1.fetchAll()
        print("新增后：")
        printItems(items)

        if let first = items.first {
            try store1.toggle(first)
        }
        items = try store1.fetchAll()
        print("切换第一条完成状态后：")
        printItems(items)

        if let last = items.last {
            try store1.delete(last)
        }
        items = try store1.fetchAll()
        print("删除最后一条后：")
        printItems(items)

        printDivider("第 2 轮：重建容器，验证数据真的落盘")
        // 关键验证点：不是继续复用旧 context，
        // 而是重新创建 container/context，再读一次。
        let container2 = try makeContainer(storeURL: storeURL)
        let context2 = ModelContext(container2)
        let store2 = TodoStore(context: context2)

        let persistedItems = try store2.fetchAll()
        print("重建容器后读回：")
        printItems(persistedItems)

        if persistedItems.isEmpty {
            print("持久化验证失败：重建容器后没有数据")
        } else {
            print("持久化验证通过：重建容器后仍能读到数据")
        }
    } catch {
        print("Demo 运行失败：\(error)")
    }
}

runDemo()
