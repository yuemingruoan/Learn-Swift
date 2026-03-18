# 13. 结构体与最基础的自定义类型

## 阅读导航

- 前置章节：[10. 表达式、条件判断与循环](./10-expressions-conditions-and-loops.md)、[11. 思考题解析：命令行成绩录入程序](./11-thought-problem-analysis.md)、[12. 函数与代码复用](./12-functions-and-code-reuse.md)
- 上一章：[12. 函数与代码复用](./12-functions-and-code-reuse.md)
- 建议下一章：14. 类与实例（待补充）
- 下一章：14. 类与实例（待补充）
- 适合谁先读：已经理解函数、参数与返回值，准备学习如何组织相关数据的读者

## 本章目标

学完这一章后，你应该能够：

- 理解为什么需要自定义类型来组织数据
- 知道 `struct` 的最基础定义方式
- 理解属性和实例分别表示什么
- 创建结构体实例并访问其中的属性
- 在结构体中编写最基础的方法
- 理解普通函数与方法之间最直接的区别

## 本章对应目录

- 对应项目目录：`demos/projects/13-structs-and-custom-types`

## 为什么在这一章学习 `struct`

前面几章里，程序中的数据主要以零散变量的形式存在。

例如，在成绩录入程序中，可能会出现下面这些变量：

```swift
var name: String
var frequency: Int
var score_sum: Int
var pass_num: Int
var average: Double
var pass_rate: Double
```

这种写法当然可以工作，但当程序继续变长时，会逐渐暴露一个问题：

- 相关数据虽然彼此有关，但在代码中却是分散的

例如：

- `name`、`frequency`、`score_sum`、`pass_num`
  都是在描述同一份成绩记录

但从写法上看，它们只是若干个彼此独立的变量。

当变量还很少时，这种分散不算严重；但变量逐渐增多后，程序就会出现下面这些问题：

- 不容易一眼看出哪些数据属于同一件事
- 数据之间的关系不够清楚
- 后续如果还要增加新的相关数据，变量会越来越散

这时就需要一种新的组织方式：

- 将相关数据放进同一个类型中

而在`Swift`中最基础,也是最易懂的方式就是 `struct`。

## 什么是自定义类型

前面已经接触过很多语言内置类型，例如：

- `Int`
- `Double`
- `String`
- `Bool`

这些类型都不是我们自己写的，而是 Swift 已经提供好的。

但程序开发中，常常还需要另一类类型：

- 不是语言预先提供的
- 而是根据当前问题自己定义的

这类类型可以先统称为：

- 自定义类型

例如，如果当前程序要处理“学生成绩记录”，那么很自然就会希望有一种类型专门表示：

- 学生姓名
- 考试次数
- 总分
- 及格次数

这种类型并不是 Swift 内置的，因此需要程序自己定义。

## 什么是结构体

在当前阶段，可以先把结构体理解成：

- 一种把相关数据组织在一起的自定义类型

最简单的例子如下：

```swift
struct Student {
    var name: String
    var score: Int
}
```

这段代码的意思是：

- 现在定义了一个新的类型，名字叫 `Student`
- 它内部有两个数据项：`name` 和 `score`

也就是说，从这一刻开始，程序里不只有：

- `Int`
- `String`

这样的内置类型，也有了：

- `Student`

这个自己定义出来的类型。

## `struct` 的最基础写法

先看结构：

```swift
struct 类型名 {
    属性定义
}
```

例如：

```swift
struct Book {
    var title: String
    var price: Double
}
```

这里可以拆成三部分理解：

1. `struct`
   表示这里要定义一个结构体。

2. `Book`
   这是结构体名，也就是类型名。

3. `{ ... }`
   结构体内部用于声明这个类型包含哪些数据。

## 什么是属性

在结构体内部，像下面这些成员：

```swift
var title: String
var price: Double
```

就叫作属性。

当前阶段可以先把属性理解成：

- 这个类型内部保存的数据

例如在 `Book` 里：

- `title` 表示书名
- `price` 表示价格

因此，属性本质上就是：

- 某个类型内部的变量

它和前面已经学过的普通变量并不是完全陌生的概念，只是它现在被放进了一个类型内部。

## 为什么属性会让数据更清楚

先比较下面两种写法。

第一种写法：

```swift
var studentName = "Alice"
var chinese = 95
var math = 88
```

第二种写法：

```swift
struct Student {
    var name: String
    var chinese: Int
    var math: Int
}
```

第二种写法的价值并不是“代码更短”，而是：

- 它明确表达了这些数据本来就属于同一个对象

也就是说：

- `name`
- `chinese`
- `math`

不是几项偶然放在一起的数据，而是共同构成了一个 `Student`。

这就是结构体作为数据组织方式的意义。

## 什么是实例

结构体本身只是类型定义。

例如：

```swift
struct Student {
    var name: String
    var score: Int
}
```

它只是说明：

- “Student 这种类型应该长什么样”

但这还不等于程序里已经真正有了某个学生的数据。

如果要得到一个具体的学生，还需要创建实例。

例如：

```swift
let student = Student(name: "Alice", score: 95)
```

这里的 `student` 就是一个实例。

当前阶段可以先把“实例”理解成：

- 某个类型的一个具体值

也就是说：

- `Student` 是类型
- `student` 是这个类型的一个具体对象

## 如何创建结构体实例

最基础的写法是：

```swift
let student = Student(name: "Alice", score: 95)
```

这个写法当前阶段可以先照着理解，不需要先深究初始化规则。

只需要先记住：

- 结构体定义好属性后
- Swift 会提供一种最基础的创建方式
- 创建时把每个属性需要的值按名字写进去即可

例如：

```swift
let book = Book(title: "Swift", price: 88.0)
```

这样程序里就真正有了一个 `Book` 类型的值。

## 如何访问属性

创建实例之后，就可以通过点语法访问属性。

例如：

```swift
let student = Student(name: "Alice", score: 95)

print(student.name)
print(student.score)
```

这里的：

```swift
student.name
student.score
```

可以先理解成：

- 访问 `student` 里面的 `name`
- 访问 `student` 里面的 `score`

这也是结构体最常见的基础使用方式。

## 从零散变量过渡到结构体

回到前面的成绩程序。

原来的代码里，可能有下面这些变量：

```swift
var name: String
var frequency: Int
var score_sum: Int
var pass_num: Int
```

如果只是从“功能是否正确”的角度看，这些变量当然没有问题。

但从“数据是否有组织”的角度看，它们其实可以进一步收拢。

例如：

```swift
struct StudentRecord {
    var name: String
    var frequency: Int
    var scoreSum: Int
    var passCount: Int
}
```

这样做之后，代码表达出来的意思会更清楚：

- 这些数据共同描述的是一份成绩记录

此时结构体的意义已经非常明显：

- 不再只是单纯多学一个语法
- 而是在重新组织程序中的数据

## 结构体中也可以写方法

上一章已经学习过函数。

如果把函数写在结构体内部，它通常就会被称为方法。

例如：

```swift
struct Student {
    var name: String
    var score: Int

    func isPassed() -> Bool {
        return score >= 60
    }
}
```

这里的 `isPassed()` 仍然是函数，只不过它被写进了 `Student` 内部，因此：

- 它不再是一个独立函数
- 而是 `Student` 类型自己的方法

## 方法和普通函数的最直接区别

先看普通函数：

```swift
func isPassed(score: Int) -> Bool {
    return score >= 60
}
```

它的特点是：

- 逻辑独立存在
- 需要把 `score` 作为参数传进去

再看方法：

```swift
struct Student {
    var name: String
    var score: Int

    func isPassed() -> Bool {
        return score >= 60
    }
}
```

它的特点是：

- 逻辑和 `Student` 绑定在一起
- 它直接使用这个实例自己的 `score`

因此，在当前阶段可以先做一个最直观的区分：

- 普通函数：适合写独立逻辑
- 方法：适合写和某个类型自身数据密切相关的逻辑

## 调用方法的方式

方法同样通过点语法调用。

例如：

```swift
let student = Student(name: "Alice", score: 95)
print(student.isPassed())
```

这里的：

```swift
student.isPassed()
```

表示：

- 调用 `student` 这个实例自己的方法

如果输出结果是 `true`，就说明这个学生当前成绩及格。

## 这一章暂时不展开的内容

本章只聚焦结构体最基础的用法，因此下面这些内容暂时不展开：

- 自定义初始化方法
- `mutating`
- 访问控制
- 协议
- 泛型
- `struct` 与 `class` 的深入区别

这些内容并不重要，而是需要等前面的基础先稳定之后，再逐步补上。

## 常见错误

### 1. 以为定义了结构体，就已经自动有了数据

例如：

```swift
struct Student {
    var name: String
    var score: Int
}
```

这只是定义了类型，不是创建了实例。

### 2. 把类型名和实例名混淆

例如：

- `Student` 是类型名
- `student` 才是某个具体实例

### 3. 定义了属性，但不理解这些属性本来属于同一个整体

学习结构体时，重点不只是写出语法，而是理解：

- 为什么这些数据应该放在一起

### 4. 方法里仍然只想着依赖外部变量

如果方法本来描述的是这个类型自己的行为，那么它通常应该优先使用自身属性。

## 本章练习

请你自己完成下面几件事：

1. 定义一个 `Book` 结构体，包含书名和价格两个属性
2. 定义一个 `Student` 结构体，包含姓名和分数两个属性
3. 创建 `Book` 和 `Student` 的实例，并输出它们的属性

- 本题对应参考答案：

- [13. 结构体与最基础的自定义类型 练习答案](../../../exercises/zh-CN/answers/13-structs-and-custom-types.md)

## 思考题

请你继续思考下面两个问题：

1. 如果后面程序里还要继续增加“班级”“考试日期”“成绩等级”等信息，那么继续使用大量零散变量和改用结构体，各自会带来什么差别？

这一题不要求立刻写出完整代码，重点是思考：

- 当数据种类越来越多时，怎样的组织方式更清楚

2. 学习了struct后，再次查看我们在第十二章时修改过后的代码

- 代码中的变量封装成`struct`
- 尝试将获取及格率和平均分的代码封装成结构体内的函数

你应该能感受到代码变得愈发“优雅”了

- 本题对应参考答案：

- [13-structs-and-custom-types.xcodeproj](/Users/shiyu/Documents/Project/Learn-Swift/demos/projects/13-structs-and-custom-types/13-structs-and-custom-types.xcodeproj)

## 本章小结

本章的重点并不在于结构体的全部细节，而在于建立下面这组基础认识：

- `struct` 是一种自定义类型
- 属性用于组织相关数据
- 实例表示这个类型的具体值
- 方法本质上是写在类型内部的函数
- 结构体的价值在于让数据关系更清楚

如果已经能够理解这些内容，那么下一步继续学习更完整的类型设计时，难度会明显降低。
