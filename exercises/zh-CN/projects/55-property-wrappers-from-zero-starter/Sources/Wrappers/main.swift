import Foundation

// 任务 1：实现 @Trimmed
//
// 要求：
// - 标 @propertyWrapper
// - 写入时自动去掉首尾空白与换行
// - 给一个能让 var name: String = "  hi " 直接初始化的 init(wrappedValue:)

// 任务 2：实现 @Capitalized
//
// 要求：
// - 写入时自动把字符串的首字母大写（其他字符保持原样）
// - 例如 "tim cook" -> "Tim cook"
// - 空字符串保持空字符串

// 任务 3：实现支持 Range 的 ClampedHalfOpen
//
// 要求：
// - 行为类似 @Clamped，但接受 Range（半开区间），上界不包含
// - 例如 ClampedHalfOpen<Int>(0..<10) 时，最大允许值是 9
// - 不要求实现 projectedValue

// 任务 4：实现 @UserDefaultCodable<T: Codable>
//
// 要求：
// - 用 JSONEncoder 序列化值，存入 UserDefaults 的 Data
// - 读出时用 JSONDecoder 反序列化
// - 失败（不存在 / 解码失败）时返回默认值
// - setter 必须是 nonmutating（参考 demo 里的 @UserDefault）
// - 提供 reset() 方法清除该 key

// 任务 5（思考题）
//
// 在练习答案文档里回答：
// - @Clamped 能不能用在 let 字段上？为什么？
// - 怎么改才能让它行？

// ===== 入口：把你的实现挂上去后取消下面的注释跑一遍 =====

// struct Profile {
//     @Trimmed var nickname: String = "  Tim  "
//     @Capitalized var displayName: String = "tim cook"
//     @ClampedHalfOpen(0..<100) var score: Int = 50
// }
//
// var p = Profile()
// print("[\(p.nickname)]")          // [Tim]
// print("[\(p.displayName)]")       // [Tim cook]
// p.score = 250
// print(p.score)                    // 99

print("starter 已就绪，请按照注释完成各任务。")
