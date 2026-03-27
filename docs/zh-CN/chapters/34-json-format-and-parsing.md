# 34. JSON 格式与解析

## 阅读导航

- 前置章节：[14. 数组与字典：列表与键值对](./14-arrays-and-dictionaries.md)、[23. 错误处理：让失败路径更清楚](./23-error-handling-clear-failure-paths.md)、[29. 并发入门：async/await 与 Task](./29-concurrency-basics-async-await-and-task.md)、[33. 异步序列：AsyncSequence 与 AsyncStream](./33-asyncsequence-and-asyncstream.md)
- 上一章：[33. 异步序列：AsyncSequence 与 AsyncStream](./33-asyncsequence-and-asyncstream.md)
- 建议下一章：35. JSON 进阶：字段映射与复杂结构（待补充）
- 下一章：35. JSON 进阶：字段映射与复杂结构（待补充）
- 适合谁先读：已经理解数组、字典、最基础自定义类型和错误处理，准备先把 JSON 这种常见数据格式看懂的读者

## 本章目标

学完当前这一部分后，你应该能够：

- 理解为什么 JSON 会频繁出现在配置和数据交换场景里
- 知道 JSON 最核心的组织方式是 key-value 结构
- 看懂 JSON 对象、数组、字符串、数字、布尔值和 `null`
- 理解 JSON 对象和 Swift 字典在直觉上的相似之处
- 知道 Swift 里解析 JSON 最常见的两条路线：`JSONSerialization` 和 `JSONDecoder`
- 看懂 `JSONSerialization.jsonObject(with:)` 的最基础语法
- 看懂 `JSONDecoder().decode(_:from:)` 的最基础语法
- 知道 `try`、`Data`、`.self` 在 JSON 解析场景里分别在表达什么

## 本章对应目录

- 本章文稿：`docs/zh-CN/chapters/34-json-format-and-parsing.md`
- 对应项目目录：`demos/projects/34-json-format-and-parsing`
- 练习起始工程：`exercises/zh-CN/projects/34-json-format-and-parsing-starter`
- 练习答案文稿：`exercises/zh-CN/answers/34-json-format-and-parsing.md`
- 练习参考工程：`exercises/zh-CN/answers/34-json-format-and-parsing`

说明：

- 本章当前只聚焦“JSON 格式入门”和“Swift 里的基础解析语法”。
- 更复杂的字段映射和数据建模，放到下一章单独展开。

## 为什么先单独学习 JSON

很多初学者第一次接触 JSON 数据时，会把两件事混在一起：

- 数据是怎么进入程序的
- 数据本身长什么样

但这两件事其实不是同一个问题。

更稳妥的学习顺序通常是：

1. 先看懂 JSON 这种常见数据格式
2. 再学习怎样把它接到更完整的数据处理流程里

因为如果你连数据本身的结构都还看不清，那么后面即使已经拿到原始内容，也很容易停在一种模糊状态：

- 知道程序已经拿到一段内容
- 但不知道这段内容到底该怎样理解

所以这一章先把注意力收缩到：

- JSON 到底是什么
- 它为什么经常长成 key-value 的样子
- 它进入 Swift 之后通常怎样被解析

## 为什么 JSON 这么常见

先说一个最实用的结论：

- JSON 是一种非常常见的数据交换格式

你会在很多地方看到它，例如：

- 数据文件
- 本地配置文件
- 缓存数据
- 导入导出的结构化文本

## 先看一个最小 JSON 例子

例如你可能会看到下面这样一段数据：

```json
{
  "title": "复习闭包",
  "estimatedHours": 2,
  "isFinished": false
}
```

这段 JSON 表达的是一条学习任务。

当前阶段你先重点观察它的外形：

- 最外层是 `{ ... }`
- 里面有三组“名字 : 值”
- 每一组数据都由一个字段名和对应内容组成

这就是 JSON 最核心的组织方式之一：

- **key-value 结构**

## 什么是 key-value 结构

可以先把 key-value 近似理解成：

- key：字段名，也就是“这一项数据叫什么”
- value：字段值，也就是“这一项数据具体是多少”

例如刚才那段 JSON 里：

- `title` 是 key
- `"复习闭包"` 是 value

- `estimatedHours` 是 key
- `2` 是 value

- `isFinished` 是 key
- `false` 是 value

所以如果把整段 JSON 用一句话概括，可以先理解成：

- 它在描述一组“字段名 -> 对应值”的关系

## JSON 对象：最常见的 key-value 容器

在 JSON 里，只要你看到：

```json
{
  "name": "Alice",
  "score": 95
}
```

就可以先建立一个稳定直觉：

- 这是一个 JSON 对象

对象最重要的特征就是：

- 使用 `{}` 包起来
- 里面由多个 key-value 对组成
- key 必须是字符串

例如上面这段里：

- `"name"` 是 key
- `"Alice"` 是 value
- `"score"` 是 key
- `95` 是 value

## JSON 数组：把多个值排成列表

除了对象，JSON 里另一种非常常见的结构是数组。

例如：

```json
[
  "闭包",
  "并发",
  "JSON"
]
```

或者：

```json
[
  {
    "title": "复习闭包",
    "estimatedHours": 2
  },
  {
    "title": "学习 JSON",
    "estimatedHours": 1
  }
]
```

这里最值得先记住的是：

- 数组用 `[]` 表示
- 数组里的元素按顺序排列
- 元素可以是字符串、数字、对象，甚至还是数组

所以你会看到一种非常常见的真实返回格式：

- 最外层是数组
- 数组里的每个元素都是对象

这通常就对应：

- 一组任务
- 一组课程
- 一组用户

## JSON 里最常见的值类型

当前阶段不需要把 JSON 规范背下来，但至少要认识下面这些最常见的值：

### 1. 字符串

```json
"Swift"
```

### 2. 数字

```json
24
```

```json
3.14
```

### 3. 布尔值

```json
true
```

```json
false
```

### 4. `null`

```json
null
```

它表示：

- 这里没有值
- 不是`nil`，这点和`Swift`不太一样

### 5. 对象

```json
{
  "title": "复习泛型"
}
```

### 6. 数组

```json
[
  1,
  2,
  3
]
```

你可以先把这一组东西记成：

- JSON 的 value 不一定只是一个简单值
- value 也可以继续是对象或数组

## 对象和数组可以继续嵌套

这也是 JSON 很常见的一点。

例如：

```json
{
  "boardTitle": "今日学习看板",
  "tasks": [
    {
      "title": "复习闭包",
      "estimatedHours": 2
    },
    {
      "title": "整理并发笔记",
      "estimatedHours": 1
    }
  ],
  "owner": {
    "name": "Alice",
    "level": "beginner"
  }
}
```

这里要建立的直觉是：

- `boardTitle` 对应的是一个字符串
- `tasks` 对应的是一个数组
- `owner` 对应的是一个对象

所以 JSON 的核心不只是“有 key-value”，而是：

- 一个 value 还可以继续展开成下一层结构

这就是为什么你在真实项目里，经常会看到一份 JSON 长得像一棵树。

## JSON 和 Swift 字典、数组像在哪里

如果你前面已经学过数组和字典，那这里可以先建立一个非常有帮助的类比：

- JSON 对象，直觉上很像 Swift 里的字典
- JSON 数组，直觉上很像 Swift 里的数组

例如这段 JSON：

```json
{
  "title": "学习 JSON",
  "estimatedHours": 2
}
```

很容易让你联想到：

```swift
[
    "title": "学习 JSON",
    "estimatedHours": 2
]
```

这种直觉是有帮助的，因为它能让你快速理解：

- JSON 对象本质上也是“字段名对应字段值”

但这里也要立刻补一个边界：

- JSON 不是 Swift 字典语法
- JSON 是一种独立的数据格式

所以你不能把 Swift 字典直接当成 JSON 原文，也不能把 JSON 原文直接当成 Swift 代码。

## JSON 原文进入 Swift 之后，通常先是 `Data`

这一点很关键。

程序读到的 JSON 通常不是一个已经现成排好的 Swift 字典，也不是一个现成结构体，而是：

- 一段原始字节数据

在 Swift 里，这通常会落在：

```swift
Data
```

也就是说，JSON 在真正被解析之前，经常先以 `Data` 的形式存在。

如果只是为了教学演示，我们也可以手动把 JSON 字符串转成 `Data`：

```swift
let jsonText = """
{
    "title": "复习闭包",
    "estimatedHours": 2,
    "isFinished": false
}
"""

let jsonData = jsonText.data(using: .utf8)!
```

这里可以先这样理解：

- `jsonText` 是字符串
- `jsonData` 才是后面解析函数真正要吃进去的输入
-  `using: .utf8` 代表使用`utf-8`格式解析json字符串

## 先看最原始的 JSON 解析路线：`JSONSerialization`

Swift 里一条比较基础的 JSON 解析路线是：

```swift
JSONSerialization
```

最常见的入门写法如下：

```swift
let object = try JSONSerialization.jsonObject(with: jsonData)
```

这行代码的意思可以拆成三部分来看：

1. `JSONSerialization`
   这是系统提供的一个 JSON 解析工具。

2. `jsonObject(with: jsonData)`
   表示：把这段 `Data` 解析成一个通用对象。

3. `try`
   表示：解析过程可能失败。

例如：

- JSON 格式本身不合法
- 数据不是合法 JSON

都可能导致这里抛错。

## `jsonObject(with:)` 返回的为什么不是现成结构体

这是初学者很容易疑惑的一点。

先看这句：

```swift
let object = try JSONSerialization.jsonObject(with: jsonData)
```

这里的 `object` 并不是一个已经类型很明确的 `StudyTask`，而更像是：

- 一个“我先帮你把 JSON 解析出来了，但具体类型你自己再确认”的通用结果

因此它的结果通常要继续配合类型转换使用。

例如，如果最外层是对象，可以写成：

```swift
if let dictionary = try JSONSerialization.jsonObject(with: jsonData) as? [String: Any] {
    print(dictionary["title"] ?? "")
}
```

这里最值得注意的是：

- `as? [String: Any]`

它表示：

- 尝试把解析结果当成“键是字符串、值是任意类型”的字典

如果最外层其实是数组，常见写法又会变成：

```swift
if let array = try JSONSerialization.jsonObject(with: jsonData) as? [[String: Any]] {
    print(array.count)
}
```

所以你可以先留下这样一个印象：

- `JSONSerialization` 能帮你把 JSON 打开
- 但打开之后，很多结构还需要你自己判断和转换

## 先把 `as?` 的含义看清楚

前面这一句：

```swift
as? [String: Any]
```

如果你一眼看不懂，不要急着把它整体死记。

当前阶段先拆成两部分：

- `as?`
- `[String: Any]`

其中：

- `[String: Any]` 表示一个字典
- key 是 `String`
- value 是 `Any`

也就是说，它表达的是：

- 一个字段名是字符串、字段值可能有多种类型的容器

而：

- `as?`

表示：

- 尝试把当前值当成这种类型

如果成功，就得到转换后的结果；如果失败，就得到 `nil`。

所以这一整句可以先近似理解成：

- 试试看，这个 JSON 解析结果能不能被当成一个字典来看

## 为什么 `JSONSerialization` 只适合做“最基础的结构理解”

`JSONSerialization` 并不是不能用，但对初学者来说，它很容易把注意力拖进这些细节里：

- 到处判断最外层是字典还是数组
- 到处写 `[String: Any]`
- 到处手动取 key
- 到处手动做类型转换

例如：

```swift
if let dictionary = try JSONSerialization.jsonObject(with: jsonData) as? [String: Any],
   let title = dictionary["title"] as? String,
   let estimatedHours = dictionary["estimatedHours"] as? Int,
   let isFinished = dictionary["isFinished"] as? Bool {
    print(title, estimatedHours, isFinished)
}
```

这种写法可以工作，但你很快就会发现：

- 字段一多，手动解析会越来越啰嗦
- 结构一复杂，嵌套判断会越来越乱

所以在真正写应用代码时，更常见的路线通常是：

- `JSONDecoder`

## 更常见的解析路线：`JSONDecoder`

相比手动从 `[String: Any]` 里一个个取值，Swift 更常见的写法是：

- 先定义一个能承接 JSON 结构的类型
- 再用 `JSONDecoder` 直接解码

最基础的例子如下：

```swift
struct StudyTaskDTO: Decodable {
    let title: String
    let estimatedHours: Int
    let isFinished: Bool
}
```

这里你可以先把 `Decodable` 理解成：

- 这个类型允许自己从外部数据里被解码出来

然后配合：

```swift
let decoder = JSONDecoder()
let task = try decoder.decode(StudyTaskDTO.self, from: jsonData)
```

这段代码的阅读顺序可以先固定成：

- 创建一个解码器
- 告诉它要解成什么类型
- 把 `Data` 交给它

## `decode(_:from:)` 这句语法到底在说什么

这是本章非常关键的一句。

```swift
let task = try decoder.decode(StudyTaskDTO.self, from: jsonData)
```

你可以把它直接翻成一句中文：

- 试着把 `jsonData` 解码成 `StudyTaskDTO` 类型

这里的三个关键点分别是：

### 1. `try`

表示：

- 解码可能失败

例如：

- JSON 缺字段
- 字段类型不匹配
- 根本不是合法 JSON

### 2. `StudyTaskDTO.self`

它表示：

- 这里传入的是“类型本身”

当前阶段你先不用把 `.self` 理解得太底层，只要先记住：

- `decode` 不只是要数据
- 它还要知道“应该把数据解成什么类型”

因此这里写的不是某个实例，而是：

- `StudyTaskDTO` 这个类型本身

### 3. `from: jsonData`

表示：

- 输入数据来自这段 `jsonData`

所以整句拼起来就是：

- 试着把这段 `jsonData` 按 `StudyTaskDTO` 的结构解出来

## 为什么这里的字段名要和 JSON 对上

先看 JSON：

```json
{
  "title": "复习闭包",
  "estimatedHours": 2,
  "isFinished": false
}
```

再看结构体：

```swift
struct StudyTaskDTO: Decodable {
    let title: String
    let estimatedHours: Int
    let isFinished: Bool
}
```

这两个能直接对应起来，一个很重要的原因就是：

- 字段名一致

也就是说：

- JSON 里的 `title` 对上 Swift 里的 `title`
- JSON 里的 `estimatedHours` 对上 Swift 里的 `estimatedHours`
- JSON 里的 `isFinished` 对上 Swift 里的 `isFinished`

当前阶段先记住这个最简单版本就够了。

后面如果字段名不一致，再引入 `CodingKeys` 这类工具。

## 一个最小的完整解码例子

把前面的内容合在一起，可以得到下面这段最基础示例：

```swift
import Foundation

struct StudyTaskDTO: Decodable {
    let title: String
    let estimatedHours: Int
    let isFinished: Bool
}

let jsonText = """
{
    "title": "复习闭包",
    "estimatedHours": 2,
    "isFinished": false
}
"""

let jsonData = jsonText.data(using: .utf8)!

let decoder = JSONDecoder()
let task = try decoder.decode(StudyTaskDTO.self, from: jsonData)

print(task.title)
print(task.estimatedHours)
print(task.isFinished)
```

值得注意的是：

- JSON 原文先变成 `Data`
- `JSONDecoder` 负责把 `Data` 解码成结构体
- 解码结果已经不再是 `[String: Any]`
- 而是一个字段清楚、类型清楚的 `StudyTaskDTO`

## 再看一个数组解码例子

如果这份 JSON 表达的不是一条任务，而是一组任务，那么最外层很可能就是数组：

```json
[
  {
    "title": "复习闭包",
    "estimatedHours": 2,
    "isFinished": false
  },
  {
    "title": "学习 JSON",
    "estimatedHours": 1,
    "isFinished": true
  }
]
```

此时解码写法会变成：

```swift
let tasks = try decoder.decode([StudyTaskDTO].self, from: jsonData)
```

这里的：

```swift
[StudyTaskDTO].self
```

表示：

- 目标类型不再是单个 `StudyTaskDTO`
- 而是“由多个 `StudyTaskDTO` 组成的数组”

所以你也能顺便建立一个很重要的直觉：

- `decode` 的第一参数，描述的就是整个 JSON 根结构

如果 JSON 最外层是对象，就传对象类型。

如果 JSON 最外层是数组，就传数组类型。

## 可以把解码逻辑收进一个函数

前面我们已经学过函数的价值，所以这里也可以很自然地把解析流程收拢起来。

例如：

```swift
func parseTask(from data: Data) throws -> StudyTaskDTO {
    let decoder = JSONDecoder()
    return try decoder.decode(StudyTaskDTO.self, from: data)
}
```

这个函数的意思是：

- 输入一段 `Data`
- 输出一个解码后的 `StudyTaskDTO`
- 如果解码失败，就把错误继续抛出去

如果要解析任务数组，也可以写成：

```swift
func parseTasks(from data: Data) throws -> [StudyTaskDTO] {
    let decoder = JSONDecoder()
    return try decoder.decode([StudyTaskDTO].self, from: data)
}
```

这两段函数的价值不只是“少写两行代码”，更重要的是：

- 你把“JSON 解析”这件事单独收拢成了一个明确步骤

后面再把它接到更完整的数据处理流程里时，结构会清楚很多。

## 当前部分最需要先建立的印象

如果你现在只先记住下面这些点，这一部分就已经达到目标了：

- JSON 是一种很常见的数据交换格式
- JSON 最核心的组织方式之一是 key-value
- JSON 对象像字典，JSON 数组像列表
- JSON 在 Swift 里常常先表现成 `Data`
- `JSONSerialization` 可以先把 JSON 打开成通用结构
- `JSONDecoder` 更适合把 JSON 直接解成结构体
- `decode(_:from:)` 的意思是“把这段 `Data` 解成指定类型”

## 本节小结

这一部分最重要的是先熟悉下面这条链路：

- 原始 JSON 文本或字节数据进入程序
- JSON 进入 Swift 后通常先是 `Data`
- 你可以用 `JSONSerialization` 理解最原始结构
- 更常见的是用 `JSONDecoder` 直接把数据解成 `Decodable` 类型

只要这条链路先建立起来，后面再继续进入：

- 文件读写里的 JSON
- 程序输入里的 JSON
- 更复杂的嵌套结构和字段映射

就会顺很多。

## 本章练习与课后作业

如果你想继续巩固“理解 JSON 格式并把它解析成 Swift 类型”上，可以继续完成下面这道解码练习：

- 作业答案：`exercises/zh-CN/answers/34-json-format-and-parsing.md`
- 起始工程：`exercises/zh-CN/projects/34-json-format-and-parsing-starter`
- 参考答案工程：`exercises/zh-CN/answers/34-json-format-and-parsing`

starter project 当前已经提供了三段原始 JSON：

- 单个对象 JSON
- 数组根结构 JSON
- 嵌套对象和对象数组组成的看板 JSON

请你按下面这些明确目标完成修改：

1. 在 `decodeTask(from:)` 里把 `Data` 解成 `StudyTaskDTO`。
2. 在 `decodeChapterNotes(from:)` 里把 `Data` 解成 `[ChapterNoteDTO]`。
3. 在 `decodeBoard(from:)` 里把 `Data` 解成 `StudyBoardDTO`。
4. 在 `printSingleTaskResult()` 里按字段输出单个任务。
5. 在 `printChapterListResult()` 里逐项输出章节列表。
6. 在 `printBoardResult()` 里输出看板标题、负责人和任务列表。

示例输出：

```text
======== 练习 1：单个对象 ========
标题：复习闭包
预计小时数：2
完成状态：false

======== 练习 2：数组根结构 ========
第 24 章：泛型：让同一套逻辑适配更多类型
标签：泛型 / 复用 / 约束
第 25 章：闭包：把函数当成值来传递
标签：闭包 / 排序 / 回调
第 34 章：JSON 格式与解析
标签：JSON / Data / 解码

======== 练习 3：嵌套对象与对象数组 ========
看板标题：周末复习看板
负责人：Alice / beginner
- 整理 JSON 笔记 / 1 小时 / 已完成
- 练习数组根结构解码 / 2 小时 / 未完成
- 复习嵌套对象解析 / 1 小时 / 未完成
```

若你能成功完成这份作业，意味着你已经熟练掌握了这些知识：

- 知道对象根结构该解成单个结构体。
- 知道数组根结构该解成结构体数组。
- 知道嵌套对象需要继续定义内部类型。
- 能把解析结果按项展开，而不是只打印一整坨原始内容。


## 本章小结

这一章中，以下这些知识点务必牢记：

- JSON 最核心的组织方式之一是 key-value。
- JSON 对象常常对应“字段名到字段值”的一组关系。
- JSON 数组常常对应“按顺序排列的一组值”。
- JSON 进入 Swift 后，常常先以 `Data` 的形式存在。
- `JSONSerialization` 适合帮助你先看懂最原始结构。
- `JSONDecoder` 更适合把 JSON 直接解成 `Decodable` 类型。
- `decode(_:from:)` 的目标类型，必须和 JSON 最外层结构对上。

如果你能够准确区分下面三种情况：

- 最外层是对象
- 最外层是数组
- 某个字段的 value 里还嵌着对象或数组

并且知道它们在 Swift 里通常该被解码成什么类型，那么这一章最重要的目标就已经达到了。

## 接下来怎么读

如果继续沿这条主线往下走，下一步很自然会进入：

- 35. JSON 进阶：字段映射与复杂结构（待补充）

因为当你已经理解：

- JSON 的常见外形
- `Data` 在解析链路里的位置
- `JSONDecoder` 的最基础写法

接下来一个很现实的问题就是：

- 怎样继续处理字段名不一致、结构更深、约束更多的 JSON
