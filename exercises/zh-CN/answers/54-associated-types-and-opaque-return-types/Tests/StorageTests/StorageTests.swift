import Testing
@testable import Storage

@Test("InMemoryNumberStorage 满足 ReadOnlyStorage 协议且 contains 可用")
func numberStorageContains() {
    let storage = InMemoryNumberStorage(items: [1, 2, 3])
    #expect(storage.count == 3)
    #expect(storage.contains(2))
    #expect(!storage.contains(99))
}

@Test("InMemoryNameStorage 复用 ReadOnlyStorage 的默认 contains")
func nameStorageContains() {
    let storage = InMemoryNameStorage(items: ["A", "B"])
    #expect(storage.contains("A"))
    #expect(!storage.contains("Z"))
}

@Test("evenNumbers 改成 some Sequence<Int> 后仍然能正确生成偶数")
func evenNumbersWorks() {
    let result = Array(evenNumbers(upTo: 10))
    #expect(result == [0, 2, 4, 6, 8])
}
