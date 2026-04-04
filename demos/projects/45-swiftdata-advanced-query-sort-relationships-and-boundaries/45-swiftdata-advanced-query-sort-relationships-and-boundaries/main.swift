//
//  main.swift
//  45-swiftdata-advanced-query-sort-relationships-and-boundaries
//
//  Created by Codex on 2026/3/31.
//

import Foundation
import SwiftData

// 这里开始引入第二个模型，目的是把“关系、筛选、删除规则”讲清楚。
@Model
final class TodoList {
    var name: String

    // 删除列表时使用 `.nullify`：
    // 列表被删掉，但待办不跟着删，而是回到“未归类”状态。
    @Relationship(deleteRule: .nullify, inverse: \TodoItem.list)
    var items: [TodoItem] = []

    init(name: String) {
        self.name = name
    }
}

@Model
final class TodoItem {
    var title: String
    var isDone: Bool
    var priority: Int
    var createdAt: Date
    var updatedAt: Date
    var list: TodoList?

    init(
        title: String,
        isDone: Bool = false,
        priority: Int = 0,
        createdAt: Date = .now,
        updatedAt: Date = .now,
        list: TodoList? = nil
    ) {
        self.title = title
        self.isDone = isDone
        self.priority = priority
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.list = list
    }
}

// 这一层继续作为“存储入口”存在，让 demo 的读取需求更接近文稿里的描述方式。
struct TodoStore {
    let context: ModelContext

    func addList(name: String) throws -> TodoList {
        let list = TodoList(name: name)
        context.insert(list)
        try context.save()
        return list
    }

    func addTodo(title: String, priority: Int, isDone: Bool = false, list: TodoList?) throws {
        let item = TodoItem(title: title, isDone: isDone, priority: priority, list: list)
        context.insert(item)
        try context.save()
    }

    func fetchAllTodos() throws -> [TodoItem] {
        // 先给一个最朴素的稳定顺序，方便观察初始数据。
        let descriptor = FetchDescriptor<TodoItem>(
            sortBy: [SortDescriptor(\TodoItem.createdAt, order: .forward)]
        )
        return try context.fetch(descriptor)
    }

    func fetchUndoneTodos(in listName: String) throws -> [TodoItem] {
        // `#Predicate` 负责筛选“读哪些”，
        // `SortDescriptor` 负责定义“按什么顺序返回”。
        let predicate = #Predicate<TodoItem> { item in
            item.isDone == false && item.list?.name == listName
        }

        let descriptor = FetchDescriptor<TodoItem>(
            predicate: predicate,
            sortBy: [
                SortDescriptor(\TodoItem.priority, order: .reverse),
                SortDescriptor(\TodoItem.createdAt, order: .forward)
            ]
        )
        return try context.fetch(descriptor)
    }

    func fetchInboxTodos() throws -> [TodoItem] {
        // 这里把“未归类”明确建模成 `list == nil`。
        let predicate = #Predicate<TodoItem> { item in
            item.list == nil
        }

        let descriptor = FetchDescriptor<TodoItem>(
            predicate: predicate,
            sortBy: [SortDescriptor(\TodoItem.createdAt, order: .forward)]
        )
        return try context.fetch(descriptor)
    }

    func deleteList(_ list: TodoList) throws {
        context.delete(list)
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
            .appendingPathComponent("45-swiftdata-demo", isDirectory: true)

        try fm.createDirectory(at: folder, withIntermediateDirectories: true)
        return folder.appendingPathComponent("todos.store")
    }

    static func cleanStoreFiles(at storeURL: URL) {
        // 避免和其他 SwiftData demo 共享默认 store，保证关系 schema 独立。
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
    // 这里显式传入两个模型类型，因为这章已经进入“列表 + 待办”的关系场景。
    let configuration = ModelConfiguration(url: storeURL)
    return try ModelContainer(for: TodoList.self, TodoItem.self, configurations: configuration)
}

func printDivider(_ title: String) {
    print("\n======== \(title) ========")
}

func printTodos(_ items: [TodoItem]) {
    if items.isEmpty {
        print("(空)")
        return
    }

    for (index, item) in items.enumerated() {
        let status = item.isDone ? "已完成" : "未完成"
        let listName = item.list?.name ?? "未归类"
        print("\(index + 1). [\(status)] priority=\(item.priority) list=\(listName) title=\(item.title)")
    }
}

func runDemo() {
    do {
        let storeURL = try DemoPaths.storeURL()

        printDivider("准备阶段")
        DemoPaths.cleanStoreFiles(at: storeURL)
        print("SwiftData store 文件：\(storeURL.path)")
        print("已清理旧 store，确保演示从空库开始")

        // 本章还是同一条主线：
        // 先有 `ModelContainer`，再有承接读写的 `ModelContext`。
        let container = try makeContainer(storeURL: storeURL)
        let context = ModelContext(container)
        let store = TodoStore(context: context)

        printDivider("创建列表与待办")
        // 先准备两个列表，再准备一个未归类待办，方便后面观察 `nullify`。
        let today = try store.addList(name: "Today")
        let work = try store.addList(name: "Work")

        try store.addTodo(title: "先做高优先级任务", priority: 3, list: today)
        try store.addTodo(title: "再看低优先级任务", priority: 1, list: today)
        try store.addTodo(title: "已完成的工作任务", priority: 2, isDone: true, list: work)
        try store.addTodo(title: "还没归类的待办", priority: 2, list: nil)

        let allTodos = try store.fetchAllTodos()
        print("当前全部待办：")
        printTodos(allTodos)

        printDivider("读取 Today 列表下未完成待办，按优先级再按创建时间排序")
        let todayUndone = try store.fetchUndoneTodos(in: "Today")
        printTodos(todayUndone)

        printDivider("读取未归类待办")
        let inboxBeforeDelete = try store.fetchInboxTodos()
        printTodos(inboxBeforeDelete)

        printDivider("删除 Today 列表，观察 nullify 结果")
        // 删除父对象后，不是把子对象也删掉，而是让它们回到 `list == nil`。
        try store.deleteList(today)
        let todayAfterDelete = try store.fetchUndoneTodos(in: "Today")
        let inboxAfterDelete = try store.fetchInboxTodos()

        print("删除后，Today 列表下未完成待办：")
        printTodos(todayAfterDelete)
        print("删除后，未归类待办：")
        printTodos(inboxAfterDelete)
    } catch {
        print("Demo 运行失败：\(error)")
    }
}

runDemo()
