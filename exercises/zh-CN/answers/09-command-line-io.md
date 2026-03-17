# 09. 命令行输入与输出 练习答案

对应章节：

- [09. 命令行输入与输出](../../../docs/zh-CN/chapters/09-command-line-io.md)

如果你想一边看答案一边运行代码，也可以打开对应示例工程：

- `demos/projects/09-command-line-io`

## 练习 1

题目：

- 使用 `print(...)` 输出一句固定文本

参考答案：

```swift
print("Hello, Swift")
```

说明：

- `print(...)` 会把内容输出到控制台
- 当前阶段最常见的用途就是输出固定提示文字

## 练习 2

题目：

- 定义一个变量，并把它和提示文字一起输出

参考答案：

```swift
let name = "Swift"
print("name 的值是：", name)
```

参考输出：

```text
name 的值是： Swift
```

说明：

- `print(...)` 可以一次输出多个内容
- 这也是命令行程序里最常见的基础输出方式之一

## 练习 3

题目：

- 使用 `readLine()` 读取一行输入，再原样输出它

参考答案：

```swift
print("请输入一段文本：")

if let text = readLine() {
    print("你输入的是：", text)
}
```

说明：

- `readLine()` 的结果是 `String?`
- 所以当前阶段最稳妥的做法是先用 `if let` 取值

## 练习 4

题目：

- 写一个读取名字并输出欢迎语的程序

参考答案：

```swift
print("请输入你的名字：")

if let name = readLine() {
    print("你好，", name)
}
```

例如如果输入：

```text
Alice
```

那么通常会看到：

```text
你好， Alice
```

## 练习 5

题目：

- 写一个读取整数并输出它的两倍的程序

参考答案：

```swift
print("请输入一个整数：")

if let text = readLine() {
    if let number = Int(text) {
        print("你输入的数字是：", number)
        print("它的两倍是：", number * 2)
    }
}
```

例如如果输入：

```text
21
```

那么通常会看到：

```text
你输入的数字是： 21
它的两倍是： 42
```

说明：

- `readLine()` 先读到的是字符串
- `Int(text)` 会尝试把字符串转换成整数
- 因为转换可能失败，所以它的结果仍然是 `Int?`

## 练习 6

题目：

- 尝试输入一个不能转换成整数的内容，观察程序为什么没有进入第二层 `if let`

参考答案：

例如下面这段代码：

```swift
print("请输入一个整数：")

if let text = readLine() {
    if let number = Int(text) {
        print("你输入的数字是：", number)
    }
}
```

如果输入的是：

```text
Hello
```

那么第二层 `if let` 不会进入。

原因是：

- `text` 的值是 `"Hello"`
- `Int("Hello")` 的结果是 `nil`
- 因为没有成功取到整数值，所以 `if let number = Int(text)` 的代码块会被直接跳过

如果你想把这个过程看得更清楚，可以临时这样写：

```swift
print("请输入一个整数：")

if let text = readLine() {
    let number = Int(text)
    print("Int(text) 的结果是：", number as Any)

    if let value = number {
        print("转换成功，值是：", value)
    } else {
        print("转换失败：这不是一个有效的整数")
    }
}
```

这样如果输入：

```text
Hello
```

通常会看到：

```text
Int(text) 的结果是： nil
转换失败：这不是一个有效的整数
```

## 练习 7

题目：

- 使用 `print(..., terminator: "")` 写一个不换行提示，让用户可以直接在冒号后面输入名字

参考答案：

```swift
print("请输入你的名字：", terminator: "")

if let name = readLine() {
    print("你好，", name)
}
```

例如如果输入：

```text
Alice
```

那么控制台里通常会看到：

```text
请输入你的名字：Alice
你好， Alice
```

说明：

- 默认情况下，`print(...)` 输出完会自动换行
- `terminator: ""` 表示把结尾改成空字符串
- 这样光标就会停留在当前行末尾，用户可以直接在提示文字后面输入
- 如果你希望提示更稳妥地立即显示出来，可以再补一句 `fflush(stdout)`

在某些环境里，如果你发现提示没有及时显示，也可以进一步写成：

```swift
print("请输入你的名字：", terminator: "")
fflush(stdout)

if let name = readLine() {
    print("你好，", name)
}
```

## 一组可直接运行的综合答案

```swift
import Foundation

print("Hello, Swift")

let topic = "命令行输入与输出"
print("当前主题是：", topic)

print("请输入一段文本：")
if let text = readLine() {
    print("你输入的是：", text)
}

print("请输入你的名字：")
if let name = readLine() {
    print("你好，", name)
}

print("请输入你的城市：", terminator: "")
fflush(stdout)
if let city = readLine() {
    print("你输入的城市是：", city)
}

print("请输入一个整数：")
if let text = readLine() {
    let number = Int(text)
    print("Int(text) 的结果是：", number as Any)

    if let value = number {
        print("它的两倍是：", value * 2)
    } else {
        print("转换失败：这不是一个有效的整数")
    }
}
```
