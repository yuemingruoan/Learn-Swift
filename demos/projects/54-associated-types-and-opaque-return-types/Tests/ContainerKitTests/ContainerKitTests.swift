import Testing
@testable import ContainerKit

@Test("IntStack.contains 在元素存在时返回 true")
func intStackContainsExisting() {
    let stack = IntStack(items: [1, 2, 3])
    #expect(stack.contains(2))
}

@Test("IntStack.contains 在元素不存在时返回 false")
func intStackContainsMissing() {
    let stack = IntStack(items: [1, 2, 3])
    #expect(!stack.contains(99))
}

@Test("StringStack.contains 复用了 Container.where Item: Equatable 的默认实现")
func stringStackContains() {
    let stack = StringStack(items: ["a", "b"])
    #expect(stack.contains("a"))
    #expect(!stack.contains("z"))
}

@Test("makeUserSource 返回的 source 能拉到第一页")
func makeUserSourceReturnsFirstPage() async throws {
    let source = makeUserSource()
    let page = try await source.fetch(page: 0)
    #expect(page.count == 20)
    #expect(page.first == User(id: 0, name: "User 0-0"))
}

@Test("any Container 可以放进异构数组")
func heterogeneousContainerArray() {
    let arr: [any Container] = [
        IntStack(items: [1, 2]),
        StringStack(items: ["x"]),
    ]
    #expect(arr[0].count == 2)
    #expect(arr[1].count == 1)
}
