import Foundation

public protocol ReadOnlyStorage<Element> {
    associatedtype Element
    var count: Int { get }
    func element(at index: Int) -> Element
}

public extension ReadOnlyStorage where Element: Equatable {
    func contains(_ value: Element) -> Bool {
        for i in 0..<count where element(at: i) == value {
            return true
        }
        return false
    }
}

public struct InMemoryNumberStorage: ReadOnlyStorage {
    public let items: [Int]
    public init(items: [Int]) { self.items = items }
    public var count: Int { items.count }
    public func element(at index: Int) -> Int { items[index] }
}

public struct InMemoryNameStorage: ReadOnlyStorage {
    public let items: [String]
    public init(items: [String]) { self.items = items }
    public var count: Int { items.count }
    public func element(at index: Int) -> String { items[index] }
}

public func evenNumbers(upTo n: Int) -> some Sequence<Int> {
    (0..<n).lazy.filter { $0 % 2 == 0 }
}

let numbers = InMemoryNumberStorage(items: [1, 2, 3])
print("numbers count = \(numbers.count)")
print("numbers contains 2? \(numbers.contains(2))")

let names = InMemoryNameStorage(items: ["A", "B"])
print("names contains \"B\"? \(names.contains("B"))")

print(Array(evenNumbers(upTo: 10)))
