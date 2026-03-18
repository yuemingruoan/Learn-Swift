# 12. 函数与代码复用 练习答案

对应章节：

- [12. 函数与代码复用](../../../docs/zh-CN/chapters/12-functions-and-code-reuse.md)

如果你想一边看答案一边运行示例，也可以打开对应工程：

- `demos/projects/12-functions-and-code-reuse`

## 练习 1

题目：

- 写一个无参数、无返回值的函数，输出一句固定文本

参考答案：

```swift
func sayHello() {
    print("Hello")
}

sayHello()
```

说明：

- 这类函数的重点在于“把一段固定逻辑命名后再调用”

## 练习 2

题目：

- 写一个带参数的函数，输出欢迎语

参考答案：

```swift
func greet(name: String) {
    print("你好，\(name)")
}

greet(name: "Alice")
```

说明：

- 参数的作用是让同一段逻辑处理不同输入

## 练习 3

题目：

- 写一个带两个整数参数的函数，返回它们的和

参考答案：

```swift
func add(number1: Int, number2: Int) -> Int {
    return number1 + number2
}

let result = add(number1: 3, number2: 4)
print(result)
```

参考输出：

```text
7
```

说明：

- `print(...)` 负责输出
- `return` 负责把结果交还给外部

## 练习 4

题目：

- 写一个函数，接收一个分数，返回它是否及格

参考答案：

```swift
func isPassed(score: Int) -> Bool {
    return score >= 60
}

print(isPassed(score: 75))
print(isPassed(score: 45))
```

参考输出：

```text
true
false
```

## 练习 5

题目：

- 把第十章思考题中的“判断成绩是否合法”提炼成函数

参考答案：

```swift
func isValidScore(score: Int) -> Bool {
    return score >= 0 && score <= 100
}

print(isValidScore(score: 88))
print(isValidScore(score: 101))
```

参考输出：

```text
true
false
```

说明：

- 提炼后的好处在于“合法成绩”的规则被明确命名了

## 练习 6

题目：

- 把“保留一位小数”的逻辑提炼成函数

参考答案：

```swift
func roundToOneDecimal(value: Double) -> Double {
    var firstDecimal = Int(value * 10)
    let secondDecimal = Int(value * 100) % 10

    if secondDecimal >= 5 {
        firstDecimal += 1
    }

    return Double(firstDecimal) / 10
}

print(roundToOneDecimal(value: 402.0 / 5.0))
print(roundToOneDecimal(value: 4.0 / 5.0 * 100))
```

参考输出：

```text
80.4
80.0
```

说明：

- 这一版的核心思想是：直接取第二位小数，再判断第一位小数是否进位

## 思考题提示

如果你尝试继续重构第十章思考题，可以优先考虑提炼下面这些函数：

1. `printPrompt(message: String)`
2. `isPassed(score: Int) -> Bool`
3. `roundToOneDecimal(value: Double) -> Double`
4. `isValidScore(score: Int) -> Bool`

判断是否值得提炼的标准可以先抓住两点：

- 这段逻辑是否重复出现
- 提炼之后，主流程是否更清晰
