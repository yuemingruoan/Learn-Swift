import Foundation

@propertyWrapper
public struct Trimmed {
    private var storage: String

    public init(wrappedValue: String) {
        self.storage = wrappedValue.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    public var wrappedValue: String {
        get { storage }
        set { storage = newValue.trimmingCharacters(in: .whitespacesAndNewlines) }
    }
}

@propertyWrapper
public struct Capitalized {
    private var storage: String

    public init(wrappedValue: String) {
        self.storage = Self.capitalize(wrappedValue)
    }

    public var wrappedValue: String {
        get { storage }
        set { storage = Self.capitalize(newValue) }
    }

    private static func capitalize(_ s: String) -> String {
        guard let first = s.first else { return s }
        return first.uppercased() + s.dropFirst()
    }
}

@propertyWrapper
public struct ClampedHalfOpen<Value: Comparable & Strideable> where Value.Stride: SignedInteger {
    private var value: Value
    public let range: Range<Value>

    public init(wrappedValue: Value, _ range: Range<Value>) {
        self.range = range
        self.value = Self.clamp(wrappedValue, to: range)
    }

    public var wrappedValue: Value {
        get { value }
        set { value = Self.clamp(newValue, to: range) }
    }

    private static func clamp(_ v: Value, to range: Range<Value>) -> Value {
        let upperInclusive = range.upperBound.advanced(by: -1)
        if v < range.lowerBound { return range.lowerBound }
        if v > upperInclusive { return upperInclusive }
        return v
    }
}

@propertyWrapper
public struct UserDefaultCodable<Value: Codable> {
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
            guard let data = store.data(forKey: key),
                  let decoded = try? JSONDecoder().decode(Value.self, from: data) else {
                return defaultValue
            }
            return decoded
        }
        nonmutating set {
            guard let data = try? JSONEncoder().encode(newValue) else { return }
            store.set(data, forKey: key)
        }
    }

    public var projectedValue: UserDefaultCodable<Value> { self }

    public func reset() {
        store.removeObject(forKey: key)
    }
}

public struct Profile {
    @Trimmed public var nickname: String = "  Tim  "
    @Capitalized public var displayName: String = "tim cook"
    @ClampedHalfOpen(0..<100) public var score: Int = 50

    public init() {}
}

public struct Address: Codable, Equatable {
    public let city: String
    public let zip: String
    public init(city: String, zip: String) {
        self.city = city
        self.zip = zip
    }
}

var p = Profile()
print("[\(p.nickname)]")
print("[\(p.displayName)]")
p.score = 250
print(p.score)
