import Testing
import Foundation
@testable import WrapperKit

@Test("Clamped 把超出上限的值裁剪到上限")
func clampedClipsAboveMax() {
    var s = AppSettings()
    s.brightness = 250
    #expect(s.brightness == 100)
}

@Test("Clamped 把低于下限的值裁剪到下限")
func clampedClipsBelowMin() {
    var s = AppSettings()
    s.brightness = -10
    #expect(s.brightness == 0)
}

@Test("Clamped 的 projectedValue 暴露原始值")
func clampedProjectionExposesRaw() {
    var s = AppSettings()
    s.brightness = 250
    #expect(s.$brightness == 250)
}

@Test("Trimmed 写入时去掉首尾空白")
func trimmedRemovesWhitespace() {
    var s = AppSettings()
    s.nickname = "  Tim  "
    #expect(s.nickname == "Tim")
}

@Test("Trimmed 在初始化时也会去掉空白")
func trimmedRemovesOnInit() {
    struct A {
        @Trimmed var name: String = "  hello "
    }
    let a = A()
    #expect(a.name == "hello")
}

@Test("UserDefault 把写入持久化到给定的 store")
func userDefaultPersists() {
    let suite = UserDefaults(suiteName: "wrapperkit.test.persist")!
    suite.removeObject(forKey: "k")

    @UserDefault("k", default: "fallback", store: suite) var v: String
    #expect(v == "fallback")
    v = "hello"
    #expect(suite.string(forKey: "k") == "hello")
    suite.removeObject(forKey: "k")
}

@Test("UserDefault 的 projectedValue 提供 reset")
func userDefaultProjectionReset() {
    let suite = UserDefaults(suiteName: "wrapperkit.test.reset")!
    suite.removeObject(forKey: "k")

    @UserDefault("k", default: 0, store: suite) var v: Int
    v = 99
    #expect(v == 99)
    $v.reset()
    #expect(v == 0)
}
