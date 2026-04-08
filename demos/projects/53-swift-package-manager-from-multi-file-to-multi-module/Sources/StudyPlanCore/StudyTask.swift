import Foundation

public struct StudyTask: Equatable, Sendable {
    public let id: Int
    public let title: String
    public let estimatedHours: Int
    public var isFinished: Bool

    public init(id: Int, title: String, estimatedHours: Int, isFinished: Bool) {
        self.id = id
        self.title = title
        self.estimatedHours = estimatedHours
        self.isFinished = isFinished
    }
}
