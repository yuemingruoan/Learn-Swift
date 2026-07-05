import Foundation

public func groupBy<Element, Key: Hashable>(
    _ items: [Element],
    by keyPath: KeyPath<Element, Key>
) -> [Key: [Element]] {
    Dictionary(grouping: items) { $0[keyPath: keyPath] }
}

public struct User: Equatable {
    public let name: String
    public let country: String
    public init(name: String, country: String) {
        self.name = name
        self.country = country
    }
}

public struct Message: Identifiable, Equatable {
    public let id: UUID
    public let text: String
    public init(id: UUID = UUID(), text: String) {
        self.id = id
        self.text = text
    }
}

@MainActor
public final class Counter {
    public private(set) var value: Int = 0
    public init() {}
    public func increment() { value += 1 }

    public nonisolated func formatTimestamp(_ d: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd HH:mm"
        return f.string(from: d)
    }
}

let users = [
    User(name: "Tim", country: "US"),
    User(name: "Cook", country: "US"),
    User(name: "Wang", country: "CN"),
]
let grouped = groupBy(users, by: \.country)
print("US 用户数: \(grouped["US"]?.count ?? 0)")
print("CN 用户数: \(grouped["CN"]?.count ?? 0)")

let messages = [
    Message(text: "hello"),
    Message(text: "hello"),
]
print("两条同文消息的 id 是否相同: \(messages[0].id == messages[1].id)")
