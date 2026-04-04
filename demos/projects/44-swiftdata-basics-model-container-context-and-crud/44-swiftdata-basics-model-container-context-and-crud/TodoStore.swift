import Foundation
import SwiftData

struct TodoStore {
    let context: ModelContext

    func fetchAll() throws -> [TodoItem] {
        let descriptor = FetchDescriptor<TodoItem>(
            sortBy: [
                SortDescriptor(\TodoItem.priority, order: .reverse),
                SortDescriptor(\TodoItem.createdAt, order: .forward)
            ]
        )
        return try context.fetch(descriptor)
    }

    func fetchLists() throws -> [TodoList] {
        let descriptor = FetchDescriptor<TodoList>(
            sortBy: [SortDescriptor(\TodoList.name, order: .forward)]
        )
        return try context.fetch(descriptor)
    }

    @discardableResult
    func addList(name: String) throws -> TodoList {
        let list = TodoList(name: name)
        context.insert(list)
        try context.save()
        return list
    }

    func add(
        title: String,
        priority: Int = 0,
        notes: String? = nil,
        list: TodoList? = nil
    ) throws {
        let item = TodoItem(title: title, priority: priority, notes: notes, list: list)
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
