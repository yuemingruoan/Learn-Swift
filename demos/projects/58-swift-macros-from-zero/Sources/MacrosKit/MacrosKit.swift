/// 把表达式 `expr` 在编译期就地展开为 `(expr, "expr 的源代码")`。
///
/// 例子：
/// ```swift
/// let (v, s) = #stringify(1 + 2 * 3)
/// // 展开后等价于：let (v, s) = (1 + 2 * 3, "1 + 2 * 3")
/// ```
@freestanding(expression)
public macro stringify<T>(_ value: T) -> (T, String) =
    #externalMacro(module: "MacrosKitMacros", type: "StringifyMacro")
