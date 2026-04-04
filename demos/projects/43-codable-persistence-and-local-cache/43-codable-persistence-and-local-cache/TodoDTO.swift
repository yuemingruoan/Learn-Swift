import Foundation

struct TodoDTO: Decodable {
    let id: Int
    let title: String
    let completed: Bool
}
