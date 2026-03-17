# 08. Optional 入门 练习答案

对应章节：

- [08. Optional 入门](../../../docs/zh-CN/chapters/08-optional-basics.md)

如果你想一边看答案一边运行代码，也可以打开对应示例工程：

- `demos/projects/08-optional-basics`

## 练习 1

题目：

- 声明一个 `String?` 类型的变量

参考答案：

```swift
var text: String?
```

说明：

- `String?` 表示这个变量可能有字符串值，也可能没有值

## 练习 2

题目：

- 先给它赋值为一个字符串，再改成 `nil`

参考答案：

```swift
var text: String?

text = "Hello"
print(text as Any)

text = nil
print(text as Any)
```

参考输出：

```text
Optional("Hello")
nil
```

说明：

- 第一次赋值后，`text` 里面真的保存了一个字符串
- 改成 `nil` 后，表示它当前没有值

## 练习 3

题目：

- 写一个 `Int("123")` 的例子，并用 `if let` 取值

参考答案：

```swift
let number = Int("123")

if let value = number {
    print("转换成功，值是：", value)
}
```

参考输出：

```text
转换成功，值是： 123
```

说明：

- `Int("123")` 的结果是 `Int?`
- 因为字符串转整数这件事可能成功，也可能失败
- 这里刚好成功了，所以 `if let` 里的代码会执行

## 练习 4

题目：

- 再写一个 `Int("Hello")` 的例子，观察为什么不能直接得到整数

参考答案：

```swift
let number = Int("Hello")

print(number as Any)

if let value = number {
    print("转换成功，值是：", value)
}
```

参考输出：

```text
nil
```

说明：

- `"Hello"` 不是一个可以转换成整数的字符串
- 所以 `Int("Hello")` 的结果是 `nil`
- 因为没有成功取到值，所以 `if let` 代码块不会执行

## 练习 5

题目：

- 尝试自己读懂下面这行代码的意思

```swift
if let text = readLine() {
    print(text)
}
```

参考答案：

你可以先把它读成：

- 如果 `readLine()` 真的读到了一行文本
- 就把这行文本取出来，命名为 `text`
- 然后执行 `print(text)`

也可以拆开理解成：

1. `readLine()` 的结果是 `String?`
2. `if let text = ...` 会先检查这里面有没有值
3. 如果有值，就把里面真正的字符串取出来，命名为 `text`
4. 这时 `text` 已经不是 `String?`，而是普通的 `String`
5. 如果没有值，这个代码块就会被直接跳过

## 一组可直接运行的综合答案

```swift
import Foundation

var text: String?
print("初始值：", text as Any)

text = "Hello"
print("赋值后：", text as Any)

text = nil
print("改回 nil 后：", text as Any)

let number1 = Int("123")
let number2 = Int("Hello")

if let value = number1 {
    print("number1 转换成功，值是：", value)
}

if let value = number2 {
    print("number2 转换成功，值是：", value)
}
```
