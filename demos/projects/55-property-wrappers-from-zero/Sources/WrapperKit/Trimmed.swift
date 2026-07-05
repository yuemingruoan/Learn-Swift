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
