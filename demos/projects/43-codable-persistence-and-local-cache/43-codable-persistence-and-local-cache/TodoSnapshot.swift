import Foundation

struct TodoSnapshot: Codable, Equatable {
    let id: Int
    let title: String
    let isDone: Bool

    init(dto: TodoDTO) {
        self.id = dto.id
        self.title = dto.title
        self.isDone = dto.completed
    }
}
