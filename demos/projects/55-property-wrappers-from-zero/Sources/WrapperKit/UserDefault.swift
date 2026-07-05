import Foundation

@propertyWrapper
public struct UserDefault<Value> {
    public let key: String
    public let defaultValue: Value
    public let store: UserDefaults

    public init(
        wrappedValue: Value,
        _ key: String,
        store: UserDefaults = .standard
    ) {
        self.key = key
        self.defaultValue = wrappedValue
        self.store = store
    }

    public init(
        _ key: String,
        default defaultValue: Value,
        store: UserDefaults = .standard
    ) {
        self.key = key
        self.defaultValue = defaultValue
        self.store = store
    }

    public var wrappedValue: Value {
        get {
            store.object(forKey: key) as? Value ?? defaultValue
        }
        nonmutating set {
            store.set(newValue, forKey: key)
        }
    }

    public var projectedValue: UserDefault<Value> { self }

    public func reset() {
        store.removeObject(forKey: key)
    }
}
