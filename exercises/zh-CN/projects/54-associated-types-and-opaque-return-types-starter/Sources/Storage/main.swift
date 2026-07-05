import Foundation

// 任务 1
//
// 这个协议描述"只读存储"。
// 它有一个 associatedtype Element，由实现方决定。
//
// 你需要：
// 1. 让 InMemoryNumberStorage 遵守 ReadOnlyStorage，元素类型为 Int
// 2. 让 InMemoryNameStorage 遵守 ReadOnlyStorage，元素类型为 String
// 3. 给 ReadOnlyStorage 加一个 where Element: Equatable 的扩展，
//    实现 contains(_:) 方法
public protocol ReadOnlyStorage<Element> {
    associatedtype Element
    var count: Int { get }
    func element(at index: Int) -> Element
}

public struct InMemoryNumberStorage {
    public let items: [Int]
    public init(items: [Int]) { self.items = items }
}

public struct InMemoryNameStorage {
    public let items: [String]
    public init(items: [String]) { self.items = items }
}

// 任务 2
//
// 下面这个工厂函数返回的是 any Sequence<Int>，调用方因此承担了装箱开销。
// 请把它改造成 some Sequence<Int>，并在练习答案文档里解释哪些调用方代码可能受影响。
public func evenNumbers(upTo n: Int) -> any Sequence<Int> {
    (0..<n).filter { $0 % 2 == 0 }
}

// 任务 3（思考题）
//
// 阅读下面这段纯 Swift 代码（本章正文里出现过）：
//
//     public protocol PaginatedSource<Element> {
//         associatedtype Element
//         var pageSize: Int { get }
//         func fetch(page: Int) async throws -> [Element]
//     }
//
//     public func makeUserSource() -> some PaginatedSource<User> {
//         UserRemoteSource()
//     }
//
// 请用注释回答以下问题：
// - makeUserSource() 为什么返回 some 而不是 any？
// - 把返回类型从 some 改成 any 会失去什么？
// - PaginatedSource 里哪一个声明用到了 associatedtype？哪一行依赖 some？

// 入口：在你完成任务 1 之后，把下面的注释打开来检查你的实现。
let numbers = InMemoryNumberStorage(items: [1, 2, 3])
print("numbers items count = \(numbers.items.count)")

let names = InMemoryNameStorage(items: ["A", "B"])
print("names items count = \(names.items.count)")

// 完成任务 1 后取消下面这段注释，验证 contains 是否生效：
// print("numbers contains 2? \(numbers.contains(2))")
// print("names contains \"B\"? \(names.contains("B"))")

print(Array(evenNumbers(upTo: 10)))
