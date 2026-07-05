import Foundation

@MainActor
public final class TaskListVM {
    public private(set) var tasks: [TodoTask] = []

    public init(tasks: [TodoTask] = []) {
        self.tasks = tasks
    }

    public func add(_ t: TodoTask) {
        tasks.append(t)
    }

    public func sort(using comparator: KeyPathComparator<TodoTask>) {
        tasks.sort(using: comparator)
    }

    public func toggle(id: UUID) {
        guard let i = tasks.firstIndex(where: { $0.id == id }) else { return }
        tasks[i].isDone.toggle()
    }

    public func apply(_ patch: Patch<TodoTask>, to id: UUID) {
        guard let i = tasks.firstIndex(where: { $0.id == id }) else { return }
        patch.apply(&tasks[i])
    }

    public nonisolated func format(_ task: TodoTask) -> String {
        "\(task.isDone ? "[x]" : "[ ]") \(task.title) (P\(task.priority))"
    }
}
