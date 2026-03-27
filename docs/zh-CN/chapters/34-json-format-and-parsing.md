# 34. JSON 格式与解析

## 阅读导航

- **前置章节**：[14. 数组与字典](./14-arrays-and-dictionaries.md)、[23. 错误处理](./23-error-handling-clear-failure-paths.md)、[29. 并发入门](./29-concurrency-basics-async-await-and-task.md)
- **上一章**：[33. 异步序列](./33-asyncsequence-and-asyncstream.md)
- **下一章**：35. JSON 进阶：字段映射与复杂结构（待补充）
- **适合人群**：已理解数组、字典、基础自定义类型和错误处理，准备上手处理常见数据格式的读者。

## 本章目标

学完本章后，你将能够：

- 理解 JSON 为何成为配置和数据交换的主流格式。
- 掌握 JSON 的核心结构：对象（Object）、数组（Array）及基础数据类型。
- 理解 JSON 与 Swift 字典、数组的异同。
- 掌握 Swift 中解析 JSON 的两种主要方式：`JSONSerialization` 和 `JSONDecoder`。
- 理解 `try`、`Data`、`.self` 在解析场景中的具体含义。

## 本章对应资源

- **文稿**：`docs/zh-CN/chapters/34-json-format-and-parsing.md`
- **示例项目**：`demos/projects/34-json-format-and-parsing`
- **练习起始工程**：`exercises/zh-CN/projects/34-json-format-and-parsing-starter`
- **练习答案**：`exercises/zh-CN/answers/34-json-format-and-parsing.md`

> **说明**：本章聚焦"JSON 格式入门”和“基础解析语法”。复杂的字段映射和数据建模将在下一章展开。

## 为什么先单独学习 JSON？

初学者接触 JSON 时，容易混淆两个问题：

1. 数据本身长什么样？
2. 数据是怎么进入程序的？

因此本章将按照**先看懂 JSON 结构，再学习如何接入处理流程**的结构讲解

毕竟如果连数据结构都看不清，即使拿到了原始内容，也容易陷入“知道有数据，但不知道怎么用”的模糊状态。

因此，本章我们将注意力集中在：

- JSON 到底是什么？
- 它为什么通常是 key-value 结构？
- 进入 Swift 后如何被解析？

## 为什么 JSON 这么常见？

结论很简单：**JSON 是主流的数据交换格式。**

你会在以下场景频繁遇到它：
- 配置文件
- 网络接口返回数据
- 本地缓存
- 导入导出的结构化文本

### 最小 JSON 示例

```json
{
  "title": "复习闭包",
  "estimatedHours": 2,
  "isFinished": false
}
```

这段 JSON 描述了一条学习任务。先观察它的结构特征：

- 最外层是 `{ ... }`。
- 内部包含三组“名字 : 值”。
- 每组数据由字段名和对应内容组成。

这就是 JSON 的核心组织方式：**键值对（key-value）结构**。

### 什么是 key-value 结构？

- **key（键）**：字段名，表示“这项数据叫什么”。
- **value（值）**：字段值，表示“这项数据具体是多少”。

例如上面的 JSON 中：
- `title` 是 key，`"复习闭包"` 是 value。
- `estimatedHours` 是 key，`2` 是 value。
- `isFinished` 是 key，`false` 是 value。

概括来说，JSON 描述了一组“字段名 -> 对应值”的关系。

## JSON 的核心结构

### 1. JSON 对象（Object）

只要你看到 `{ ... }` 包裹的内容，就可以认定这是一个 **JSON 对象**。

json对象有这些特征:

- 由多个 key-value 对组成。
- **key 必须是字符串**。

```json
{
  "name": "Alice",
  "score": 95
}
```

### 2. JSON 数组（Array）
另一种常见结构是数组，用 `[ ... ]` 表示。
- 元素按顺序排列。
- 元素可以是字符串、数字、对象，甚至是嵌套数组。

```json
[
  "闭包",
  "并发",
  "JSON"
]
```

**常见场景**：最外层是数组，数组内每个元素是一个对象。这通常对应一组任务、一组课程或一组用户。

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

### 3. 基础数据类型

你只需要认识以下最常见的值类型：

1. **字符串**：`"Swift"`
2. **数字**：`24`, `3.14`
3. **布尔值**：`true`, `false`
4. **null**：`null`（表示没有值，注意不同于 Swift 的 `nil`）
5. **对象**：`{ ... }`
6. **数组**：`[ ... ]`

**嵌套结构**：JSON 的 value 可以是对象或数组，从而形成树状结构。

```json
{
   "boardTitle": "今日学习看板",
   "tasks": [
    {
       "title": "复习闭包",
       "estimatedHours": 2
    }
  ],
   "owner": {
     "name": "Alice",
     "level": "beginner"
  }
}
```
- `boardTitle` 是字符串。
- `tasks` 是数组。
- `owner` 是对象。

## JSON 与 Swift 的对应关系

如果你学过数组和字典，可以建立以下直觉：
- **JSON 对象** ≈ **Swift 字典**
- **JSON 数组** ≈ **Swift 数组**

```json
{
  "title": "学习 JSON",
  "estimatedHours": 2
}
```

这很容易让人联想到 Swift 字典：

```swift
[
    "title": "学习 JSON",
    "estimatedHours": 2
]
```

**注意**：这只是直觉类比。JSON 是独立的数据格式，不能直接把 Swift 字典当成 JSON 原文，反之亦然。

### 关键桥梁：Data

JSON 原文进入 Swift 程序后，通常不会直接变成字典或结构体，而是先表现为 **原始字节数据**，即 `Data` 类型。

```swift
let jsonText = """
{
    "title": "复习闭包",
    "estimatedHours": 2,
    "isFinished": false
}
"""

// 字符串转 Data
let jsonData = jsonText.data(using: .utf8)!
```

- `jsonText` 是字符串（便于阅读）。
- `jsonData` 是解析函数真正的输入。

## Swift 中的 JSON 解析路线

### 路线一：JSONSerialization（基础/底层）

#### 基础语法

这是系统提供的基础解析工具。

```swift
let object = try JSONSerialization.jsonObject(with: jsonData)
```
- `JSONSerialization`：解析工具。
- `jsonObject(with:)`：将 `Data` 解析为通用对象。
- `try`：解析可能失败（格式错误、数据非法等）。

#### 返回值

`object` 不是明确的 `StudyTask` 类型，而是一个通用结果，通常需要配合类型转换：

```swift
if let dictionary = try JSONSerialization.jsonObject(with: jsonData) as? [String: Any] {
    print(dictionary["title"] ?? "")
}
```

- `as? [String: Any]`：尝试将结果视为“键为字符串、值为任意类型”的字典。
- 如果外层是数组，则转换为 `[[String: Any]]`。

####  局限性：

虽然能用，但代码繁琐。你需要手动判断外层结构、手动转换类型、手动取 key。字段一多，嵌套判断会让代码变得难以维护。

### 路线二：JSONDecoder（推荐/现代）

更常见的做法是：**定义模型类型，让解码器直接转换。**

#### 1. 定义模型

```swift
struct StudyTaskDTO: Decodable {
    let title: String
    let estimatedHours: Int
    let isFinished: Bool
}
```
- `Decodable` 协议：表示该类型可以从外部数据解码。

#### 2. 执行解码

```swift
let decoder = JSONDecoder()
let task = try decoder.decode(StudyTaskDTO.self, from: jsonData)
```
这句代码的含义：**试着把 `jsonData` 解码成 `StudyTaskDTO` 类型。**

关键点解析：

1. **`try`**：解码可能失败（缺字段、类型不匹配、非法 JSON）。
2. **`StudyTaskDTO.self`**：传入类型本身。解码器需要知道目标类型。
3. **`from: jsonData`**：指定输入数据。

#### 3. 字段匹配

解码成功的前提是**字段名一致**：

- JSON 的 `title` 对应 Swift 的 `title`。
- JSON 的 `estimatedHours` 对应 Swift 的 `estimatedHours`。

> 注：如果字段名不一致，后续章节会介绍 `CodingKeys` 进行映射。

#### 4. 完整示例

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
**流程总结**：

JSON 文本 -> `Data` -> `JSONDecoder` -> 类型明确的结构体。

#### 5. 数组解码

如果 JSON 最外层是数组：
```json
[
  { "title": "任务 1", ... },
  { "title": "任务 2", ... }
]
```
解码代码只需调整目标类型：

```swift
let tasks = try decoder.decode([StudyTaskDTO].self, from: jsonData)
```

- `[StudyTaskDTO].self`：表示目标是一个结构体数组。
- **快速记忆**：`decode` 的第一个参数描述的是 JSON 的**根结构**。外层是对象传对象类型，外层是数组传数组类型。

#### 6. 封装解析逻辑

在实际编码中我们更建议将解析逻辑封装为函数，使流程更清晰：

```swift
func parseTask(from data: Data) throws -> StudyTaskDTO {
    let decoder = JSONDecoder()
    return try decoder.decode(StudyTaskDTO.self, from: data)
}

func parseTasks(from data: Data) throws -> [StudyTaskDTO] {
    let decoder = JSONDecoder()
    return try decoder.decode([StudyTaskDTO].self, from: data)
}
```
这不仅减少了重复代码，更重要的是将"JSON 解析”明确为一个独立步骤，便于后续接入完整的数据处理流程。

## 本章核心印象

如果你只记住以下几点，本章目标就已达成：
1. **JSON 格式**：核心是 key-value，对象像字典，数组像列表。
2. **数据形态**：在 Swift 中通常先表现为 `Data`。
3. **解析工具**：`JSONSerialization` 适合查看原始结构，`JSONDecoder` 适合转为模型。
4. **解码语法**：`decode(_:from:)` 意为“把这段 Data 解成指定类型”。

## 本节小结

熟悉这条链路至关重要：

**原始 JSON 数据 -> Swift 中的 `Data` -> `JSONDecoder` -> `Decodable` 结构体**

建立这个认知后，后续学习文件读写、网络请求中的 JSON 处理，以及更复杂的嵌套结构，都会顺畅很多。

## 本章练习与课后作业

请基于 `34-json-format-and-parsing-starter` 工程完成以下解码练习：

### 任务目标
1. 在 `decodeTask(from:)` 中将 `Data` 解为 `StudyTaskDTO`。
2. 在 `decodeChapterNotes(from:)` 中将 `Data` 解为 `[ChapterNoteDTO]`。
3. 在 `decodeBoard(from:)` 中将 `Data` 解为 `StudyBoardDTO`。
4. 完善打印函数，按字段输出解析结果。

### 示例输出

```text
======== 练习 1：单个对象 ========
标题：复习闭包
预计小时数：2
完成状态：false

======== 练习 2：数组根结构 ========
第 24 章：泛型：让同一套逻辑适配更多类型
标签：泛型 / 复用 / 约束
...

======== 练习 3：嵌套对象与对象数组 ========
看板标题：周末复习看板
负责人：Alice / beginner
- 整理 JSON 笔记 / 1 小时 / 已完成
...
```

### 完成标准

- 能够将对象根结构解为单个结构体。
- 能够将数组根结构解为结构体数组。
- 能够为嵌套对象定义所需内部类型。
- 能清晰展开解析结果，而非打印原始数据。

## 本章小结

务必牢记以下知识点：
- `JSON` 核心是 `key-value` 结构。
- `JSON` 对象对应“字段名到字段值”，数组对应“有序值列表”。
- `Swift` 中 `JSON` 常以 `Data` 形式存在。
- `JSONDecoder` 配合 `Decodable` 是主流解析方案。
- `decode` 的目标类型必须与 `JSON` 最外层结构匹配。

如果你能准确区分：

- 对象根结构
- 数组根结构
- 嵌套结构

并知道它们在 Swift 中对应的类型，那么本章最重要的目标就已经达到了。

## 接下来怎么读？

下一步我们将会进入：**JSON 进阶：字段映射与复杂结构**。

当你理解了 JSON 的外形、`Data` 的位置以及 `JSONDecoder` 的基础用法后，接下来要解决的现实问题是：
- 怎样处理字段名不一致？
- 怎样处理更深的嵌套结构？
- 怎样处理更多的数据约束？
