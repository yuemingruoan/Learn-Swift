//
//  main.swift
//  45-swiftdata-advanced-query-sort-relationships-and-boundaries
//
//  Created by Codex on 2026/4/4.
//

import Foundation
import SwiftData

func printDivider(_ title: String) {
    print("\n======== \(title) ========")
}

func printTodos(_ items: [TodoItem], label: String) {
    print(label)
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

        let container = try DemoPaths.makeContainer(storeURL: storeURL)
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
        printTodos(allTodos, label: "当前全部待办：")

        printDivider("读取 Today 列表下未完成待办，按优先级再按创建时间排序")
        let todayUndone = try store.fetchUndoneTodos(in: "Today")
        printTodos(todayUndone, label: "查询结果：")

        printDivider("读取未归类待办")
        let inboxBeforeDelete = try store.fetchInboxTodos()
        printTodos(inboxBeforeDelete, label: "当前 inbox：")

        printDivider("删除 Today 列表，观察 nullify 结果")
        try store.deleteList(today)
        let todayAfterDelete = try store.fetchUndoneTodos(in: "Today")
        let inboxAfterDelete = try store.fetchInboxTodos()

        printTodos(todayAfterDelete, label: "删除后，Today 列表下未完成待办：")
        printTodos(inboxAfterDelete, label: "删除后，未归类待办：")
    } catch {
        print("Demo 运行失败：\(error)")
    }
}

runDemo()
