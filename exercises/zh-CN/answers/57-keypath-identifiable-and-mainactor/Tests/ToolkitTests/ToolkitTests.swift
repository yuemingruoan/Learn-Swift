import Testing
import Foundation
@testable import Toolkit

@Test("groupBy 用 KeyPath 按字段分组")
func groupByByCountry() {
    let users = [
        User(name: "Tim", country: "US"),
        User(name: "Cook", country: "US"),
        User(name: "Wang", country: "CN"),
    ]
    let g = groupBy(users, by: \.country)
    #expect(g["US"]?.count == 2)
    #expect(g["CN"]?.count == 1)
}

@Test("Identifiable 让同文消息也能被区分")
func identifiableDistinguishesSameText() {
    let messages = [
        Message(text: "hello"),
        Message(text: "hello"),
    ]
    #expect(messages[0].id != messages[1].id)
    #expect(messages[0].text == messages[1].text)
}

@Test("nonisolated 方法可以从非 MainActor 上下文直接调用")
func nonisolatedFromOutside() async {
    let counter = await Counter()
    let s = counter.formatTimestamp(Date(timeIntervalSince1970: 0))
    #expect(!s.isEmpty)
}

@Test("@MainActor 隔离的 increment 在 MainActor 上工作")
@MainActor
func mainActorIncrement() {
    let counter = Counter()
    counter.increment()
    counter.increment()
    #expect(counter.value == 2)
}
