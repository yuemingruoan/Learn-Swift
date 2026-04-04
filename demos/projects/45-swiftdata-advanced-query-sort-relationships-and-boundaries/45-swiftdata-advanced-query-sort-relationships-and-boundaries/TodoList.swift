import Foundation
import SwiftData

@Model
final class TodoList {
    var name: String

    @Relationship(deleteRule: .nullify, inverse: \TodoItem.list)
    var items: [TodoItem] = []

    init(name: String) {
        self.name = name
    }
}
