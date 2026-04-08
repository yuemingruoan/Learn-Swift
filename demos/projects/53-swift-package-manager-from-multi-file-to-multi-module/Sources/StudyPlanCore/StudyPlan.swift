import Foundation

public struct StudyPlan: Equatable, Sendable {
    public let title: String
    public private(set) var tasks: [StudyTask]

    public init(title: String, tasks: [StudyTask]) {
        self.title = title
        self.tasks = tasks
    }

    public var unfinishedTaskCount: Int {
        tasks.filter { !$0.isFinished }.count
    }

    public var totalEstimatedHours: Int {
        tasks.reduce(0) { $0 + $1.estimatedHours }
    }

    public mutating func markTaskFinished(id: Int) -> Bool {
        guard let index = tasks.firstIndex(where: { $0.id == id }) else {
            return false
        }

        tasks[index].isFinished = true
        return true
    }
}
