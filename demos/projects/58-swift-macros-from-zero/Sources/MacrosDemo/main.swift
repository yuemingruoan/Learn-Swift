import MacrosKit

let (v1, s1) = #stringify(1 + 2 * 3)
print("表达式：\(s1)")
print("结果：\(v1)")

let name = "Swift"
let (v2, s2) = #stringify("Hello, " + name)
print("---")
print("表达式：\(s2)")
print("结果：\(v2)")

func add(_ a: Int, _ b: Int) -> Int { a + b }
let (v3, s3) = #stringify(add(3, 4))
print("---")
print("表达式：\(s3)")
print("结果：\(v3)")
