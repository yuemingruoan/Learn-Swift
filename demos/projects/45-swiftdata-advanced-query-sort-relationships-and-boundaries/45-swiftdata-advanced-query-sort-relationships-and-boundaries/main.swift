//
//  main.swift
//  45-swiftdata-advanced-query-sort-relationships-and-boundaries
//
//  Created by Codex on 2026/3/31.
//

import Foundation
import SwiftData

@Model
final class TodoList {
    var name: String

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
        let descriptor = FetchDescriptor<TodoItem>(
            sortBy: [SortDescriptor(\TodoItem.createdAt, order: .forward)]
        )
        return try context.fetch(descriptor)
    }

    func fetchUndoneTodos(in listName: String) throws -> [TodoItem] {
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

func makeContainer() throws -> ModelContainer {
    try ModelContainer(for: TodoList.self, TodoItem.self)
}

func resetStore(context: ModelContext) throws {
    let todoItems = try context.fetch(FetchDescriptor<TodoItem>())
    for item in todoItems {
        context.delete(item)
    }

    let todoLists = try context.fetch(FetchDescriptor<TodoList>())
    for list in todoLists {
        context.delete(list)
    }

    try context.save()
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
        printDivider("准备阶段")
        let setupContainer = try makeContainer()
        let setupContext = ModelContext(setupContainer)
        try resetStore(context: setupContext)
        print("已清空旧数据，确保演示从空库开始")

        let container = try makeContainer()
        let context = ModelContext(container)
        let store = TodoStore(context: context)

        printDivider("创建列表与待办")
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
