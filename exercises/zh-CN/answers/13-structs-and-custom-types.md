# 13. 结构体与最基础的自定义类型 练习答案

对应章节：

- [13. 结构体与最基础的自定义类型](../../../docs/zh-CN/chapters/13-structs-and-custom-types.md)

如果你想一边看答案一边运行示例，也可以打开对应工程：

- `demos/projects/13-structs-and-custom-types`

## 练习 1

题目：

- 定义一个 `Book` 结构体，包含书名和价格两个属性

参考答案：

```swift
struct Book {
    var title: String
    var price: Double
}
```

说明：

- `Book` 是类型名
- `title` 和 `price` 是这个类型内部的属性

## 练习 2

题目：

- 定义一个 `Student` 结构体，包含姓名和分数两个属性

参考答案：

```swift
struct Student {
    var name: String
    var score: Int
}
```

如果希望顺手把“是否及格”也组织进去，可以进一步写成：

```swift
struct Student {
    var name: String
    var score: Int

    func isPassed() -> Bool {
        return score >= 60
    }
}
```

## 练习 3

题目：

- 创建 `Book` 和 `Student` 的实例，并输出它们的属性

参考答案：

```swift
struct Book {
    var title: String
    var price: Double
}

struct Student {
    var name: String
    var score: Int
}

let swiftBook = Book(title: "Swift", price: 88.0)
let alice = Student(name: "Alice", score: 95)

print(swiftBook.title)
print(swiftBook.price)
print(alice.name)
print(alice.score)
```

参考输出：

```text
Swift
88.0
Alice
95
```

说明：

- `Book` 和 `Student` 是结构体类型
- `swiftBook` 和 `alice` 是实例
- 通过点语法可以访问属性
