import Foundation

public struct TodoTask: Identifiable, Sendable, Equatable {
    public let id: UUID
    public var title: String
    public var priority: Int
    public var isDone: Bool

    public init(id: UUID = UUID(), title: String, priority: Int, isDone: Bool = false) {
        self.id = id
        self.title = title
        self.priority = priority
        self.isDone = isDone
    }
}
