import Testing
import Foundation
@testable import Wrappers

@Test("Trimmed 在 init 与 set 时都去掉首尾空白")
func trimmedWorks() {
    var p = Profile()
    #expect(p.nickname == "Tim")
    p.nickname = "   Cook  "
    #expect(p.nickname == "Cook")
}

@Test("Capitalized 把首字母大写，其余不动")
func capitalizedWorks() {
    var p = Profile()
    #expect(p.displayName == "Tim cook")
    p.displayName = "alex"
    #expect(p.displayName == "Alex")
    p.displayName = ""
    #expect(p.displayName == "")
}

@Test("ClampedHalfOpen 上界不包含")
func clampedHalfOpenUpperExclusive() {
    var p = Profile()
    p.score = 250
    #expect(p.score == 99)
    p.score = -10
    #expect(p.score == 0)
    p.score = 99
    #expect(p.score == 99)
}

@Test("UserDefaultCodable 序列化结构体")
func userDefaultCodableSerializes() {
    let suite = UserDefaults(suiteName: "answers55.codable")!
    suite.removeObject(forKey: "addr")

    @UserDefaultCodable("addr", default: Address(city: "BJ", zip: "100000"), store: suite)
    var address: Address
    #expect(address == Address(city: "BJ", zip: "100000"))
    address = Address(city: "SH", zip: "200000")
    #expect(address == Address(city: "SH", zip: "200000"))

    // 重新读一次也是 SH
    @UserDefaultCodable("addr", default: Address(city: "BJ", zip: "100000"), store: suite)
    var addressReread: Address
    #expect(addressReread == Address(city: "SH", zip: "200000"))

    suite.removeObject(forKey: "addr")
}

@Test("UserDefaultCodable.reset 清掉 key 并回到默认值")
func userDefaultCodableReset() {
    let suite = UserDefaults(suiteName: "answers55.reset")!
    suite.removeObject(forKey: "addr")

    @UserDefaultCodable("addr", default: Address(city: "BJ", zip: "100000"), store: suite)
    var address: Address
    address = Address(city: "SH", zip: "200000")
    $address.reset()
    #expect(address == Address(city: "BJ", zip: "100000"))
}
