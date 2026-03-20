# 16. class 与引用语义：为什么改一个地方，另一个地方也会变 练习答案

对应章节：

- [16. class 与引用语义：为什么改一个地方，另一个地方也会变](../../../docs/zh-CN/chapters/16-class-and-reference-semantics.md)

如果你想一边看答案一边运行本章完整示例，也可以打开对应工程：

- `demos/projects/16-class-and-reference-semantics`

说明：

- `demos/projects/16-class-and-reference-semantics` 负责展示正文里的完整对比示例
- 本文档保留更小、更基础的 `class` 练习答案

## 练习 1

题目：

- 定义一个 `Book` 类，包含 `title` 和 `pageCount`

参考答案：

```swift
class Book {
    var title: String
    var pageCount: Int

    init(title: String, pageCount: Int) {
        self.title = title
        self.pageCount = pageCount
    }
}
```

说明：

- `Book` 是类型名
- `title` 和 `pageCount` 是属性
- `init(...)` 负责创建实例时提供初始值

## 练习 2

题目：

- 创建一个 `Book` 实例，把它赋值给第二个变量，再通过第二个变量修改页数，观察两个变量输出

参考答案：

```swift
class Book {
    var title: String
    var pageCount: Int

    init(title: String, pageCount: Int) {
        self.title = title
        self.pageCount = pageCount
    }
}

let firstBook = Book(title: "Swift 入门", pageCount: 180)
let secondBook = firstBook

secondBook.pageCount = 200

print(firstBook.pageCount)
print(secondBook.pageCount)
```

参考输出：

```text
200
200
```

说明：

- `secondBook = firstBook` 并没有创建新的 `Book` 实例
- 两个变量引用的是同一个实例

## 练习 3

题目：

- 写一个函数，接收 `Book` 实例并修改书名，观察函数调用前后的变化

参考答案：

```swift
class Book {
    var title: String
    var pageCount: Int

    init(title: String, pageCount: Int) {
        self.title = title
        self.pageCount = pageCount
    }
}

func renameBook(book: Book, to newTitle: String) {
    book.title = newTitle
}

let book = Book(title: "Swift 入门", pageCount: 180)
print(book.title)

renameBook(book: book, to: "Swift 进阶")
print(book.title)
```

参考输出：

```text
Swift 入门
Swift 进阶
```

说明：

- 函数里操作的仍然是同一个实例
- 所以修改会反映到外部

## 练习 4

题目：

- 再创建一个内容相同但分别初始化的新实例，分别用 `===` 判断它和前面的实例是否为同一个实例

参考答案：

```swift
class Book {
    var title: String
    var pageCount: Int

    init(title: String, pageCount: Int) {
        self.title = title
        self.pageCount = pageCount
    }
}

let firstBook = Book(title: "Swift 入门", pageCount: 180)
let secondBook = firstBook
let thirdBook = Book(title: "Swift 入门", pageCount: 180)

print(firstBook === secondBook)
print(firstBook === thirdBook)
```

参考输出：

```text
true
false
```

说明：

- `firstBook` 和 `secondBook` 是同一个实例
- `thirdBook` 虽然内容相同，但它是新创建的另一个实例
