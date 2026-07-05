import Foundation

public struct IntStack: Container {
    public private(set) var items: [Int]

    public init(items: [Int] = []) {
        self.items = items
    }

    public var count: Int { items.count }

    public subscript(index: Int) -> Int {
        items[index]
    }

    public mutating func push(_ value: Int) {
        items.append(value)
    }
}

public struct StringStack: Container {
    public private(set) var items: [String]

    public init(items: [String] = []) {
        self.items = items
    }

    public var count: Int { items.count }

    public subscript(index: Int) -> String {
        items[index]
    }

    public mutating func push(_ value: String) {
        items.append(value)
    }
}
