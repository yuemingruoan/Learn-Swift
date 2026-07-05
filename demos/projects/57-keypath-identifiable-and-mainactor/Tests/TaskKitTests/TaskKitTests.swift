import Testing
import Foundation
@testable import TaskKit

@Test("Identifiable 用 id 区分两条 task")
func identifiableUsesID() {
    let id = UUID()
    var a = TodoTask(id: id, title: "A", priority: 1)
    var b = a
    b.title = "B"
    #expect(a != b)
    #expect(a.id == b.id)
}

@Test("KeyPathComparator 按 priority 排序")
func keyPathComparatorSorts() {
    let tasks = [
        TodoTask(title: "low", priority: 1),
        TodoTask(title: "high", priority: 3),
        TodoTask(title: "mid", priority: 2),
    ]
    let sorted = tasks.sorted(using: KeyPathComparator(\.priority))
    #expect(sorted.map(\.priority) == [1, 2, 3])

    let reversed = tasks.sorted(using: KeyPathComparator(\.priority, order: .reverse))
    #expect(reversed.map(\.priority) == [3, 2, 1])
}

@Test("Patch.set 通过 KeyPath 修改单个字段")
func patchSetUpdatesField() {
    var task = TodoTask(title: "old", priority: 1)
    let patch: Patch<TodoTask> = .set(\.title, to: "new")
    patch.apply(&task)
    #expect(task.title == "new")
    #expect(task.priority == 1)
}

@Test("Patch.combined 按顺序应用多次修改")
func patchCombinedAppliesAll() {
    var task = TodoTask(title: "old", priority: 1)
    let patch: Patch<TodoTask> = .combined([
        .set(\.title, to: "new"),
        .set(\.priority, to: 9),
    ])
    patch.apply(&task)
    #expect(task.title == "new")
    #expect(task.priority == 9)
}

@Test("groupBy 用 KeyPath 把元素分组")
func groupByByKeyPath() {
    let tasks = [
        TodoTask(title: "a", priority: 1, isDone: true),
        TodoTask(title: "b", priority: 2, isDone: false),
        TodoTask(title: "c", priority: 3, isDone: true),
    ]
    let grouped = groupBy(tasks, by: \.isDone)
    #expect(grouped[true]?.count == 2)
    #expect(grouped[false]?.count == 1)
}

@Test("find 用 KeyPath + 等值查找")
func findByKeyPath() {
    let tasks = [
        TodoTask(title: "a", priority: 1),
        TodoTask(title: "b", priority: 2),
    ]
    #expect(find(tasks, where: \.title, equals: "b")?.priority == 2)
    #expect(find(tasks, where: \.title, equals: "z") == nil)
}

@Test("@MainActor 的 VM 在 MainActor 上修改 tasks")
@MainActor
func mainActorVMOperates() {
    let vm = TaskListVM()
    vm.add(TodoTask(title: "x", priority: 1))
    let id = vm.tasks[0].id
    vm.toggle(id: id)
    #expect(vm.tasks[0].isDone)
}

@Test("nonisolated 方法可以从非 MainActor 上下文调用")
func nonisolatedAccessibleFromAnywhere() async {
    // 这个测试本身不在 MainActor 上
    let vm = await TaskListVM()
    let task = TodoTask(title: "y", priority: 2, isDone: true)
    let s = vm.format(task)  // nonisolated，无需 await
    #expect(s.contains("[x]"))
    #expect(s.contains("y"))
    #expect(s.contains("P2"))
}
