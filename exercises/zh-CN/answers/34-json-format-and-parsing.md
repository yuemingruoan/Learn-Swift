# 34. JSON 格式与解析 练习答案

对应章节：

- [34. JSON 格式与解析](../../../docs/zh-CN/chapters/34-json-format-and-parsing.md)

如果你想一边看答案一边运行 starter project，可以打开：

- `exercises/zh-CN/projects/34-json-format-and-parsing-starter`

如果你想直接运行本章练习的参考工程，也可以打开：

- `exercises/zh-CN/answers/34-json-format-and-parsing`

说明：

- 这道题不是让你只会把一段 JSON 原文贴进代码里。
- starter project 已经提供了三段原始 JSON。
- 你要做的是根据 JSON 的最外层结构，选择正确的目标类型，并把解析后的内容按项输出出来。

## 当前问题

starter project 里主要有下面几类空缺：

1. 三个 `decode...` 函数都还没有真正调用 `JSONDecoder`。
2. 单个对象 JSON 还没有按字段输出。
3. 数组根结构 JSON 还没有逐项输出。
4. 嵌套对象和对象数组构成的看板 JSON 也还没有展开输出。

## 你需要完成的修改

1. 在 `decodeTask(from:)` 里把 `Data` 解成 `StudyTaskDTO`。
2. 在 `decodeChapterNotes(from:)` 里把 `Data` 解成 `[ChapterNoteDTO]`。
3. 在 `decodeBoard(from:)` 里把 `Data` 解成 `StudyBoardDTO`。
4. 在 `printSingleTaskResult()` 里输出单个任务的标题、预计小时数和完成状态。
5. 在 `printChapterListResult()` 里逐项输出每一条章节笔记。
6. 在 `printBoardResult()` 里输出看板标题、负责人，以及每一条任务。

## 完成标准

完成后，你的代码至少应该表现出下面这些特征：

- 知道对象根结构该解成单个结构体。
- 知道数组根结构该解成结构体数组。
- 知道嵌套对象需要继续定义内部类型。
- 输出结果不是一句笼统描述，而是按项展开。

## 目标输出

这道题不建议自由发挥输出格式，参考答案采用下面这份固定输出：

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

## 参考实现方向

这道题最核心的三句通常接近下面这样：

```swift
let task = try decoder.decode(StudyTaskDTO.self, from: data)
let notes = try decoder.decode([ChapterNoteDTO].self, from: data)
let board = try decoder.decode(StudyBoardDTO.self, from: data)
```

它们分别对应：

- 单个对象
- 数组根结构
- 嵌套对象

这一题最值得观察的不是语法长短，而是：

- `decode` 的目标类型一定要和 JSON 最外层结构对应

## 分题解析

这一题表面上是在练 `JSONDecoder` 的语法，实际上更重要的是训练下面这条判断顺序：

1. 先看 JSON 最外层是对象还是数组。
2. 再决定 `decode` 的目标类型应该写成单个类型还是数组类型。
3. 如果某个字段里面还嵌着对象，就继续补内部结构体。
4. 最后再把解码后的结果按题目要求逐项输出。

如果这四步顺序稳定了，后面再遇到新的 JSON，处理方式也会很接近。

### 练习 1：单个对象

第一段 JSON 最外层长这样：

```json
{
  "title": "复习闭包",
  "estimatedHours": 2,
  "isFinished": false
}
```

这里最关键的判断只有一个：

- 最外层是 `{}`，所以它是一个对象

因此目标类型应该是：

```swift
StudyTaskDTO.self
```

而不是：

```swift
[StudyTaskDTO].self
```

对应的解码写法就是：

```swift
func decodeTask(from data: Data) throws -> StudyTaskDTO {
    let decoder = JSONDecoder()
    return try decoder.decode(StudyTaskDTO.self, from: data)
}
```

这句可以直接翻译成：

- 试着把这段 `Data` 按 `StudyTaskDTO` 的结构解出来

这里还有一个很值得初学者抓住的点：

- `StudyTaskDTO.self` 传入的是“类型本身”

因为 `decode` 不只需要原始数据，还需要知道：

- 你到底想把这段数据解成什么类型

输出部分也不应该只写一句“解析成功”，而要按题目要求把字段展开：

```swift
print("标题：\(task.title)")
print("预计小时数：\(task.estimatedHours)")
print("完成状态：\(task.isFinished)")
```

这一步的意义是：

- 让你确认解码后的结果已经不再是原始 JSON 文本
- 而是一个字段清楚、类型清楚的 Swift 结构体

### 练习 2：数组根结构

第二段 JSON 最外层长这样：

```json
[
  {
    "chapterNumber": 24,
    "title": "泛型：让同一套逻辑适配更多类型",
    "tags": ["泛型", "复用", "约束"]
  }
]
```

这里和第一题最关键的差别是：

- 最外层从 `{}` 变成了 `[]`

这意味着目标类型也必须跟着变：

```swift
[ChapterNoteDTO].self
```

对应代码是：

```swift
func decodeChapterNotes(from data: Data) throws -> [ChapterNoteDTO] {
    let decoder = JSONDecoder()
    return try decoder.decode([ChapterNoteDTO].self, from: data)
}
```

很多初学者在这里最容易犯的错是：

- 明明 JSON 最外层是数组，却还想解成单个 `ChapterNoteDTO`

这会失败，因为：

- `decode` 的目标类型和 JSON 根结构对不上

这题里还有第二个值得注意的地方：

- `tags` 本身也是数组

所以结构体里对应字段必须写成：

```swift
let tags: [String]
```

而不能写成单个 `String`。

输出时，题目要求的是“逐项输出”，所以答案里用了循环：

```swift
for note in notes {
    print("第 \(note.chapterNumber) 章：\(note.title)")
    print("标签：\(note.tags.joined(separator: " / "))")
}
```

这里的 `joined(separator:)` 不是 JSON 解析语法本身，而是为了把：

- `["泛型", "复用", "约束"]`

整理成更适合阅读的输出文本：

- `泛型 / 复用 / 约束`

### 练习 3：嵌套对象与对象数组

第三题是这组练习里最重要的一题，因为它把前两题的两个核心结构放在了一起：

- 对象里嵌对象
- 对象里嵌数组

先看最外层：

```json
{
  "boardTitle": "周末复习看板",
  "owner": {
    "name": "Alice",
    "level": "beginner"
  },
  "tasks": [
    {
      "title": "整理 JSON 笔记",
      "estimatedHours": 1,
      "isFinished": true
    }
  ]
}
```

这里第一步仍然要先判断根结构：

- 最外层是对象，所以整体目标类型是 `StudyBoardDTO.self`

但这次只写一个外层结构体还不够，因为里面还有：

- `owner` 对应一个对象
- `tasks` 对应一个对象数组

所以答案里才会继续定义：

```swift
struct StudyBoardDTO: Decodable {
    let boardTitle: String
    let owner: BoardOwnerDTO
    let tasks: [StudyTaskDTO]
}

struct BoardOwnerDTO: Decodable {
    let name: String
    let level: String
}
```

这里要建立的直觉是：

- JSON 里一层对象，Swift 里通常就需要一层对应类型

而：

- `tasks: [StudyTaskDTO]`

又是在重复第二题的判断：

- 因为 `tasks` 这个字段对应的是数组
- 所以类型也必须写成数组

对应的解码代码是：

```swift
func decodeBoard(from data: Data) throws -> StudyBoardDTO {
    let decoder = JSONDecoder()
    return try decoder.decode(StudyBoardDTO.self, from: data)
}
```

输出时，这题的重点不是只打印看板标题，而是把三层信息都展开：

1. 看板本身的信息
2. 负责人信息
3. 任务列表信息

答案里对应写成：

```swift
print("看板标题：\(board.boardTitle)")
print("负责人：\(board.owner.name) / \(board.owner.level)")

for task in board.tasks {
    let status = task.isFinished ? "已完成" : "未完成"
    print("- \(task.title) / \(task.estimatedHours) 小时 / \(status)")
}
```

这段输出的意义在于：

- 证明你不只是“把 JSON 解开了”
- 而是真的能从解码后的结构体里继续访问嵌套字段

## 关键语法回看

做完这道题后，最应该回头看稳的是下面几句：

```swift
let decoder = JSONDecoder()
```

表示：

- 创建一个 JSON 解码器

```swift
try decoder.decode(StudyTaskDTO.self, from: data)
```

表示：

- 尝试把 `data` 解成 `StudyTaskDTO`

```swift
try decoder.decode([ChapterNoteDTO].self, from: data)
```

表示：

- 尝试把 `data` 解成“由多个 `ChapterNoteDTO` 组成的数组”

```swift
func decodeBoard(from data: Data) throws -> StudyBoardDTO
```

表示：

- 这个函数输入 `Data`
- 输出 `StudyBoardDTO`
- 中途如果解码失败，会把错误继续抛出去

这里的 `throws` 很重要，因为它让函数签名直接表达出：

- JSON 解析不是一定成功的

## 这道题真正想练什么

如果只从表面看，这题像是在练：

- `JSONDecoder` 的几句固定模板

但更深一层，它真正想让你建立的是下面三条判断：

1. 根结构是对象，就先想单个结构体。
2. 根结构是数组，就先想结构体数组。
3. 字段里面继续嵌对象或数组时，类型也要跟着继续展开。

只要这三条判断建立起来，后面不管你面对的是：

- 本地 JSON 文件
- 接口返回的 JSON
- 更复杂的嵌套数据

处理思路都会稳定很多。

## 为什么这里要给三段不同 JSON

因为初学 JSON 解码时，最容易发生的混乱就是：

- 明明最外层是数组，却还想解成单个对象
- 明明有嵌套对象，却只定义了一层结构体

所以这道题故意给了三种外形：

1. 单个对象
2. 数组根结构
3. 嵌套对象 + 对象数组

你只要把这三种最常见外形练熟，后面再接网络请求时就会顺很多。

## 参考工程说明

如果你想直接运行参考实现，可以打开：

- `exercises/zh-CN/answers/34-json-format-and-parsing`

你最应该重点观察的是：

- 三个 `decode...` 函数的目标类型分别是什么
- 为什么数组要写成 `[ChapterNoteDTO].self`
- 为什么 `StudyBoardDTO` 里面还要继续定义 `BoardOwnerDTO`
- 输出时怎样把结构化数据按项展开，而不是只打印一整坨对象
