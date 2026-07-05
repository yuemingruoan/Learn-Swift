import Foundation

public struct AppSettings {
    @Clamped(0...100) public var brightness: Int = 80
    @Trimmed public var nickname: String = ""
    @UserDefault("settings.theme", default: "light") public var theme: String
    @UserDefault("settings.fontSize", default: 14) public var fontSize: Int

    public init() {}
}
