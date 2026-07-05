import Foundation

public struct Patch<Root>: Sendable {
    public let apply: @Sendable (inout Root) -> Void

    public init(apply: @escaping @Sendable (inout Root) -> Void) {
        self.apply = apply
    }

    public static func set<Value: Sendable>(
        _ keyPath: WritableKeyPath<Root, Value> & Sendable,
        to value: Value
    ) -> Patch<Root> {
        Patch { obj in obj[keyPath: keyPath] = value }
    }

    public static func combined(_ patches: [Patch<Root>]) -> Patch<Root> {
        Patch { obj in patches.forEach { $0.apply(&obj) } }
    }
}

public func find<Root, Value: Equatable>(
    _ items: [Root],
    where keyPath: KeyPath<Root, Value>,
    equals value: Value
) -> Root? {
    items.first { $0[keyPath: keyPath] == value }
}

public func groupBy<Element, Key: Hashable>(
    _ items: [Element],
    by keyPath: KeyPath<Element, Key>
) -> [Key: [Element]] {
    Dictionary(grouping: items) { $0[keyPath: keyPath] }
}
