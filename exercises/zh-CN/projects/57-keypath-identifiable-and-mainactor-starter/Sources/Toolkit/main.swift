import Foundation

// 任务 1：用 KeyPath 实现一个通用 groupBy
//
// 签名：
//
//     func groupBy<Element, Key: Hashable>(
//         _ items: [Element],
//         by keyPath: KeyPath<Element, Key>
//     ) -> [Key: [Element]]
//
// 应当能这样用：
//
//     let g = groupBy(users, by: \.country)
//     g["CN"]   // [...]

// 任务 2：为会重复的数据设计稳定 id
//
// 有一批消息，内容可能重复（比如两条都是 "hello"）。
// 如果拿"内容本身"当身份，这两条会被当成同一个，
// 做差量比对、缓存或列表渲染时就会出错。
//
// 请设计一个 Message 类型，让它遵守 Identifiable，
// 用一个稳定且独立的 id（而不是内容本身）作为身份，
// 使内容相同的两条消息也能被区分开。

// 任务 3：给一个标了 @MainActor 的类增加一个 nonisolated 方法
//
// 下面的 Counter 是 @MainActor 隔离的。
// 请补一个 nonisolated 的方法 formatTimestamp(_:)：
//
//     - 接受 Date
//     - 返回简短字符串
//     - 不依赖 Counter 的任何受隔离状态
// 然后写一个不在 MainActor 上的测试函数调用它。

@MainActor
public final class Counter {
    public private(set) var value: Int = 0
    public init() {}
    public func increment() { value += 1 }
}

// 任务 4（思考题）：
//
// 在练习答案文档里回答：
// - 什么时候应该用 Task.detached 把重活扔出去？
// - 什么时候应该让某个独立的 actor 来跑这些重活？
// - 这两者对内存、对并发安全模型的影响有什么区别？

print("starter 已就绪，请按任务完成实现。")
