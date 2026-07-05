import Foundation
import TaskKit

@MainActor
func runDemo() async {
    let vm = TaskListVM()
    vm.add(TodoTask(title: "学习 KeyPath", priority: 1))
    vm.add(TodoTask(title: "学习 Identifiable", priority: 2))
    vm.add(TodoTask(title: "学习 @MainActor", priority: 3))

    print("--- 原始顺序 ---")
    for t in vm.tasks {
        print(vm.format(t))
    }

    vm.sort(using: KeyPathComparator(\.priority, order: .reverse))
    print("--- 按 priority 倒序 ---")
    for t in vm.tasks {
        print(vm.format(t))
    }

    if let first = vm.tasks.first {
        vm.toggle(id: first.id)
        vm.apply(.set(\.title, to: "学习 KeyPath（已加深）"), to: first.id)
    }
    print("--- 第一条 toggle + patch 后 ---")
    for t in vm.tasks {
        print(vm.format(t))
    }

    let grouped = groupBy(vm.tasks, by: \.isDone)
    print("--- 按是否完成分组 ---")
    for (key, group) in grouped.sorted(by: { !$0.key && $1.key }) {
        print("isDone=\(key): \(group.count) 条")
    }
}

await runDemo()
