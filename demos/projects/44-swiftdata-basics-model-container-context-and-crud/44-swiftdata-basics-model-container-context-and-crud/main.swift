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
        print("\(index + 1). [\(status)] \(item.title)")
        print("   createdAt: \(item.createdAt)")
        print("   updatedAt: \(item.updatedAt)")
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

        try store1.add(title: "在本地新增一条待办")
        try store1.add(title: "修改单条记录而不是整份文件")

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

        printDivider("第 2 轮：重建容器，验证数据真的落盘")
        let container2 = try DemoPaths.makeContainer(storeURL: storeURL)
        let context2 = ModelContext(container2)
        let store2 = TodoStore(context: context2)

        let persistedItems = try store2.fetchAll()
        printItems(persistedItems, contextLabel: "container2/context2 重建后")

        print(persistedItems.isEmpty ? "持久化验证失败" : "持久化验证通过")
    } catch {
        print("Demo 运行失败：\(error)")
    }
}

runDemo()
