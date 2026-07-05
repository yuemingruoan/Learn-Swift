import Testing
@testable import Storage

@Test("InMemoryNumberStorage 应当能 contains 一个已有元素")
func numberStorageContains() {
    // 当你完成任务 1 后，这条断言应该能通过
    let storage = InMemoryNumberStorage(items: [1, 2, 3])
    #expect(storage.count == 3)
    // 取消注释以验证 contains:
    // #expect(storage.contains(2))
}
