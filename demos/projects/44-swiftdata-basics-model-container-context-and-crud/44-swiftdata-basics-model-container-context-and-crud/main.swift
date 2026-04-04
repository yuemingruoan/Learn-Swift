//
//  main.swift
//  44-swiftdata-basics-model-container-context-and-crud
//
//  Created by Codex on 2026/4/4.
//

import Foundation
import SwiftData

func printDivider(_ title: String) {
    print("\n======== \(title) ========")
}

func printItems(_ items: [TodoItem], contextLabel: String) {
    print("上下文：\(contextLabel)")
    if items.isEmpty {
        print("(空)")
        return
    }

    for (index, item) in items.enumerated() {
        let status = item.isDone ? "已完成" : "未完成"
        let listName = item.list?.name ?? "未归类"
        print("\(index + 1). [\(status)] \(item.title)")
        print("   list: \(listName)")
        print("   priority: \(item.priority)")
        print("   notes: \(item.notes ?? "<none>")")
        print("   createdAt: \(item.createdAt)")
        print("   updatedAt: \(item.updatedAt)")
    }
}

func printLists(_ lists: [TodoList], contextLabel: String) {
    print("上下文：\(contextLabel)")
    if lists.isEmpty {
        print("(空)")
        return
    }

    for (index, list) in lists.enumerated() {
        print("\(index + 1). 列表：\(list.name)")
        print("   items.count: \(list.items.count)")
        for item in list.items.sorted(by: { $0.priority > $1.priority }) {
            print("   - \(item.title) [priority: \(item.priority)]")
        }
    }
}

func runDemo() {
    do {
        let storeURL = try DemoPaths.storeURL()

        printDivider("准备阶段")
        DemoPaths.cleanStoreFiles(at: storeURL)
        print("SwiftData store 文件：\(storeURL.path)")
        print("已清理旧 store，确保演示从空库开始")

        printDivider("第 1 轮：当前 context 内做最小 CRUD")
        let container1 = try DemoPaths.makeContainer(storeURL: storeURL)
        let context1 = ModelContext(container1)
        let store1 = TodoStore(context: context1)

        try store1.add(
            title: "在本地新增一条待办",
            priority: 2,
            notes: "演示默认值之外，也可以保存附加说明"
        )
        try store1.add(
            title: "修改单条记录而不是整份文件",
            priority: 1
        )

        var items = try store1.fetchAll()
        printItems(items, contextLabel: "container1/context1 新增后")

        if let first = items.first {
            try store1.toggle(first)
        }
        items = try store1.fetchAll()
        printItems(items, contextLabel: "container1/context1 切换状态后")

        if let last = items.last {
            try store1.delete(last)
        }
        items = try store1.fetchAll()
        printItems(items, contextLabel: "container1/context1 删除后")

        printDivider("第 1.5 轮：建立最小一对多关系")
        let workList = try store1.addList(name: "工作")
        let lifeList = try store1.addList(name: "生活")

        try store1.add(
            title: "整理 Sprint 计划",
            priority: 3,
            notes: "演示记录直接归属到某个 TodoList",
            list: workList
        )
        try store1.add(
            title: "预约体检",
            priority: 2,
            list: lifeList
        )
        try store1.add(
            title: "收集未归类灵感",
            priority: 1,
            notes: "演示可选关系：list 可以为空"
        )

        let lists = try store1.fetchLists()
        printLists(lists, contextLabel: "container1/context1 建立关系后")

        items = try store1.fetchAll()
        printItems(items, contextLabel: "container1/context1 关系建模后")

        printDivider("第 2 轮：重建容器，验证数据真的落盘")
        let container2 = try DemoPaths.makeContainer(storeURL: storeURL)
        let context2 = ModelContext(container2)
        let store2 = TodoStore(context: context2)

        let persistedLists = try store2.fetchLists()
        printLists(persistedLists, contextLabel: "container2/context2 重建后（列表）")

        let persistedItems = try store2.fetchAll()
        printItems(persistedItems, contextLabel: "container2/context2 重建后（待办）")

        let hasPersistedRelation = persistedLists.contains(where: { !$0.items.isEmpty })
        print(!persistedItems.isEmpty && hasPersistedRelation ? "持久化验证通过" : "持久化验证失败")
    } catch {
        print("Demo 运行失败：\(error)")
    }
}

runDemo()
