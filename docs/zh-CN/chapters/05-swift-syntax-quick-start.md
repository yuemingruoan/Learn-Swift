# 05. 变量、类型与转换速览

## 阅读导航

- 前置章节：[01. 环境搭建](./01-environment-setup.md)、[04. 打印 Hello World](./04-hello-world.md)
- 上一章：[04. 打印 Hello World](./04-hello-world.md)
- 建议下一章：[06. 变量、常量与最基本的数据类型](./06-variables-and-constants.md)
- 下一章：[06. 变量、常量与最基本的数据类型](./06-variables-and-constants.md)
- 适合谁先读：已经写过至少一门编程语言，只想快速了解第六章和第七章核心内容的读者

## 这一章怎么使用

这一章只提炼第六章和第七章的核心，不展开细讲。

- 如果你已经理解变量、常量、类型、类型推断这些概念，可以先看这一章
- 如果你几乎没有编程基础，建议直接从[第六章](./06-variables-and-constants.md)开始
- 如果你想直接看可运行示例，可以顺手打开[第六章 demo](../../../demos/projects/06-variables-and-constants)和[第七章 demo](../../../demos/projects/07-explicit-types-and-conversion)

## 第六章和第七章主要讲什么

- 第六章讲：`var`、`let`、基础类型、类型推断、重新赋值
- 第七章讲：显式类型声明、先声明后赋值、整数除法、最基础的类型转换

你如果有其它语言基础，可以先把这两章理解成：

- 第六章在讲“Swift 里变量怎么声明，值怎么保存，编译器怎么推断类型”
- 第七章在讲“当推断不够用时，类型要怎么手动写出来，以及不同数值类型为什么不能随便混算”

## 一眼看懂这两章

| 概念 | Swift 写法 | 和其它语言的相同点 | Swift 里值得注意的点 |
| --- | --- | --- | --- |
| 变量 | `var number = 123` | 和多数语言一样，都是“给一个名字绑定一个值” | 类型通常在第一次确定后就固定下来 |
| 常量 | `let word = "Hello"` | 类似 Java 的 `final`、JavaScript 的 `const` | Swift 很鼓励能用 `let` 就用 `let` |
| 类型推断 | `let year = 2026` | 类似 TypeScript、Kotlin、Rust 的常见体验 | 右边信息足够明确时才会自动推断 |
| 显式类型 | `var a: Int` | 和 TypeScript、Kotlin、Go 一样，类型写在名字后面 | “先声明后赋值”时很常要手动写类型 |
| 类型转换 | `Double(x)` | 很多静态类型语言里都有显式转换 | Swift 不会替你偷偷把 `Int` 和 `Double` 混在一起算 |

## 快速对照语法

### 1. 变量和常量

```swift
var number = 123
let word = "Hello"
```

- `var` 表示后面可以改
- `let` 表示声明后不再改
- 这一点和很多语言都类似，只是 Swift 用的是 `var` / `let`

### 2. 类型推断

```swift
let age = 18
let pi = 3.14
let name = "Swift"
let isPassed = true
```

- 编译器会把它们分别推断成 `Int`、`Double`、`String`、`Bool`
- 这和动态语言“值可以随时换类型”的感觉不同
- 更接近现代静态类型语言的写法

### 3. 重新赋值不是重新声明

```swift
var score = 60
score = 80
```

- 第一行是声明并赋值
- 第二行是对已有变量重新赋值
- 这和 C、Java、JavaScript、Python 里的基本概念一致

### 4. 没有初始值时，要考虑显式类型

```swift
var a: Int
a = 1
```

- 如果你只写 `var a`，编译器不知道 `a` 到底是什么类型
- 所以 Swift 不会等到第二行再“回头猜”
- 这就是第七章要讲的显式类型声明

### 5. 整数除法和类型转换

```swift
let x = 2
let y = 5

print(x / y)
print(Double(x) / Double(y))
```

- `x / y` 的结果是 `0`，因为这里是 `Int / Int`
- 想得到 `0.4`，就要让它们以 `Double` 参与运算
- 这一点和很多静态类型语言类似，但比 JavaScript、Python 更严格直接

## 和其它语言相比，最容易注意到的不同点

### 1. Swift 不做太多隐式转换

```swift
let a = 2
let b = 5.0
// let c = a + b
```

- 在 Swift 里，这种写法不会自动帮你处理成同一类型
- 如果你来自 JavaScript 或 Python，刚开始会明显感觉它更严格

### 2. 类型推断很常见，但不是万能

- `let age = 18` 这种写法很轻松
- `var a` 这种写法却不行
- 也就是说，Swift 的推断依赖强依赖初始化时的赋值

### 3. 第六章和第七章其实是同一条线

- 第六章先讲“值怎么保存”
- 第七章再讲“类型一旦参与进来，编译器会怎样限制你”

如果你有基础，可以把它们当成一组连续规则：

1. 先用 `var` / `let` 保存值
2. 编译器优先根据初始值做类型推断
3. 推断不够时，需要显式写类型
4. 类型不同的值参与运算时，通常要先手动转换

## 这一页之后该怎么读

- 如果这页已经够你建立语法映射，接下来可以直接把[第六章](./06-variables-and-constants.md)和[第七章](./07-explicit-types-and-conversion.md)当成细节展开
- 如果你看完后仍觉得“声明”“赋值”“类型推断”“类型转换”这些词不够稳，就从第六章开始顺序读
