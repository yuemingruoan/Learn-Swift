import Foundation

@propertyWrapper
public struct Clamped<Value: Comparable> {
    private var value: Value
    public private(set) var rawValue: Value
    public let range: ClosedRange<Value>

    public init(wrappedValue: Value, _ range: ClosedRange<Value>) {
        self.range = range
        self.rawValue = wrappedValue
        self.value = Self.clamp(wrappedValue, to: range)
    }

    public var wrappedValue: Value {
        get { value }
        set {
            rawValue = newValue
            value = Self.clamp(newValue, to: range)
        }
    }

    public var projectedValue: Value { rawValue }

    private static func clamp(_ v: Value, to range: ClosedRange<Value>) -> Value {
        min(max(v, range.lowerBound), range.upperBound)
    }
}
