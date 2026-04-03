//
//  main.swift
//  44-swiftdata-basics-model-container-context-and-crud
//
//  Created by Codex on 2026/3/31.
//

import Foundation
import SwiftData

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

struct TodoStore {
    let context: ModelContext

    func fetchAll() throws -> [TodoItem] {
        let descriptor = FetchDescriptor<TodoItem>(
            sortBy: [SortDescriptor(\TodoItem.createdAt, order: .forward)]
        )
        return try context.fetch(descriptor)
    }

    func add(title: String) throws {
        let item = TodoItem(title: title)
        context.insert(item)
        try context.save()
    }

    func toggle(_ item: TodoItem) throws {
        item.isDone.toggle()
        item.updatedAt = .now
        try context.save()
    }

    func delete(_ item: TodoItem) throws {
        context.delete(item)
        try context.save()
    }
}

func makeContainer() throws -> ModelContainer {
    try ModelContainer(for: TodoItem.self)
}

func resetStore(context: ModelContext) throws {
    let descriptor = FetchDescriptor<TodoItem>()
    let items = try context.fetch(descriptor)

    for item in items {
        context.delete(item)
    }

    try context.save()
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
        printDivider("准备阶段")
        let setupContainer = try makeContainer()
        let setupContext = ModelContext(setupContainer)
        try resetStore(context: setupContext)
        print("已清空旧数据，确保演示从空库开始")

        printDivider("第 1 轮：把待办当本地记录做 CRUD")
        let container1 = try makeContainer()
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
        let container2 = try makeContainer()
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
