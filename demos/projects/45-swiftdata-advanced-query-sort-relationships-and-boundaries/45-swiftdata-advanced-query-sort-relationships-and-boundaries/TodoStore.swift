import Foundation
import SwiftData

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
