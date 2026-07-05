import Foundation

public protocol Container<Item> {
    associatedtype Item
    var count: Int { get }
    subscript(index: Int) -> Item { get }
}

public extension Container where Item: Equatable {
    func contains(_ value: Item) -> Bool {
        for i in 0..<count where self[i] == value {
            return true
        }
        return false
    }
}
