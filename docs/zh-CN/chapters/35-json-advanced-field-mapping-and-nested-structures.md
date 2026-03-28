# 35. JSON 进阶：字段映射与复杂结构

## 阅读导航

- 前置章节：[13. 结构体与最基础的自定义类型](./13-structs-and-custom-types.md)、[23. 错误处理：让失败路径更清楚](./23-error-handling-clear-failure-paths.md)、[34. JSON 格式与解析](./34-json-format-and-parsing.md)
- 上一章：[34. JSON 格式与解析](./34-json-format-and-parsing.md)
- 建议下一章：[36. Web 基础与状态管理入门：请求、响应与登录态](./36-web-basics-and-state-management.md)
- 下一章：[36. Web 基础与状态管理入门：请求、响应与登录态](./36-web-basics-and-state-management.md)
- 适合谁先读：已经能用 `JSONDecoder` 解简单对象，准备处理更接近真实接口数据的读者

## 本章目标

学完这一章后，你应该能够：

- 理解为什么真实 JSON 往往不会和 Swift 属性名一一对应
- 使用 `CodingKeys` 处理字段名不一致的情况
- 看懂并编写包含嵌套对象、对象数组和外层包装结构的解码模型
- 区分“字段可能不存在”和“字段存在但值为空”的语义差别
- 使用 `decodeIfPresent` 与自定义 `init(from:)` 处理缺字段和默认值
- 建立“先把 JSON 解成贴近原始结构的类型，再继续处理业务逻辑”的基本意识

## 本章对应资源

- 文稿：`docs/zh-CN/chapters/35-json-advanced-field-mapping-and-nested-structures.md`
- 示例项目：`demos/projects/35-json-advanced-field-mapping-and-nested-structures`
- 练习起始工程：`exercises/zh-CN/projects/35-json-advanced-field-mapping-and-nested-structures-starter`
- 练习答案文稿：`exercises/zh-CN/answers/35-json-advanced-field-mapping-and-nested-structures.md`
- 练习参考工程：`exercises/zh-CN/answers/35-json-advanced-field-mapping-and-nested-structures`

建议你这样使用：

- 先把本章当成“把基础解码接到真实数据形态上”的一章来读，而不是把它理解成只多学一个 `CodingKeys`
- 阅读时优先观察三件事：字段名是否一致、结构是否嵌套、字段是否稳定存在
- 如果你上一章已经能解最简单的对象和数组，这一章最重要的是建立“JSON 外形决定解码模型”的稳定直觉

## 为什么上一章还不够

上一章我们先把最基础的链路建立起来了：

**JSON 文本 -> `Data` -> `JSONDecoder` -> `Decodable` 结构体**

这条链很重要，但它主要解决的是：

- JSON 长什么样
- `Data` 在流程里处于什么位置
- 如何把“字段名完全一致”的简单对象解出来

可一旦开始接触更真实的数据，你很快就会遇到下面这些情况：

- JSON 用的是 `snake_case`，Swift 想写成 `camelCase`
- 某些字段被包在 `data`、`meta`、`user`、`items` 这样的嵌套层里
- 有些字段不是每次都有
- 有些字段缺失时，希望代码给出默认值，而不是直接解码失败

也就是说，上一章解决的是“看懂 JSON 和基础解码”，而这一章开始解决的是：

- **当 JSON 不再是一个平铺的小对象时，模型应该怎样继续组织**

## 先看本章最常见的通用语法

### 1. 用 `CodingKeys` 做字段映射

```swift
struct StudyTaskDTO: Decodable {
    let taskTitle: String
    let estimatedHours: Int

    enum CodingKeys: String, CodingKey {
        case taskTitle = "task_title"
        case estimatedHours = "estimated_hours"
    }
}
```

### 2. 用嵌套结构体对应嵌套 JSON

```swift
struct StudyBoardDTO: Decodable {
    let title: String
    let owner: OwnerDTO

    struct OwnerDTO: Decodable {
        let name: String
        let level: String
    }
}
```

### 3. 用 Optional 表达“这个字段可能没有”

```swift
struct StudyTaskDTO: Decodable {
    let title: String
    let note: String?
}
```

### 4. 用自定义 `init(from:)` 补默认值

```swift
struct StudyTaskDTO: Decodable {
    let title: String
    let isFinished: Bool

    enum CodingKeys: String, CodingKey {
        case title
        case isFinished
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        title = try container.decode(String.self, forKey: .title)
        isFinished = try container.decodeIfPresent(Bool.self, forKey: .isFinished) ?? false
    }
}
```

只有先熟悉这四种外形，后面再看真实例子时就不会只觉得“JSON 越来越复杂”，而是能直接判断：

- 这里需要映射字段名
- 这里需要加一层嵌套类型
- 这里应该用 Optional
- 这里更适合给默认值

## 第一个现实问题：字段名不一致怎么办

上一章里的例子之所以容易，是因为 JSON 字段名和 Swift 属性名几乎完全一致。

例如：

```json
{
  "title": "复习闭包",
  "estimatedHours": 2
}
```

它可以直接对应：

```swift
struct StudyTaskDTO: Decodable {
    let title: String
    let estimatedHours: Int
}
```

但真实场景里，你经常会看到这样的 JSON：

```json
{
  "task_title": "复习闭包",
  "estimated_hours": 2,
  "is_finished": false
}
```

这时如果你还写：

```swift
struct StudyTaskDTO: Decodable {
    let taskTitle: String
    let estimatedHours: Int
    let isFinished: Bool
}
```

解码会失败。原因不是数据没有来，而是：

- JSON 的字段名和 Swift 的属性名没有对上

### `CodingKeys` 的作用

`CodingKeys` 本质上是在说：

- **Swift 这边我想使用更合适的属性名**
- **但 JSON 那边的原始字段名我也要明确告诉解码器**

最常见写法如下：

```swift
struct StudyTaskDTO: Decodable {
    let taskTitle: String
    let estimatedHours: Int
    let isFinished: Bool

    enum CodingKeys: String, CodingKey {
        case taskTitle = "task_title"
        case estimatedHours = "estimated_hours"
        case isFinished = "is_finished"
    }
}
```

你可以先把它理解成一张映射表：

- Swift 的 `taskTitle` 对应 JSON 的 `task_title`
- Swift 的 `estimatedHours` 对应 JSON 的 `estimated_hours`
- Swift 的 `isFinished` 对应 JSON 的 `is_finished`

### 为什么不直接把 Swift 属性也写成 `task_title`

因为那会让 Swift 代码本身变得别扭。

在 Swift 里，更自然的命名方式通常是：

- `taskTitle`
- `estimatedHours`
- `isFinished`

也就是说，`CodingKeys` 不是为了炫技，而是为了同时照顾两件事：

- 保持 Swift 代码风格清楚
- 保持和外部 JSON 的真实字段名准确对接

### 什么时候可以少写一点映射代码

如果 JSON 大量使用 `snake_case`，而你的 Swift 属性统一使用 `camelCase`，系统其实还提供了另一种思路：

```swift
let decoder = JSONDecoder()
decoder.keyDecodingStrategy = .convertFromSnakeCase
```

这样像 `task_title` 这类字段，通常就能自动映射到 `taskTitle`。

但当前阶段更建议你先使用 `CodingKeys` ，原因是：

- 它更显式
- 它更容易看出每个字段是如何对应的
- 它在字段名并非简单蛇形转换时依然适用

所以本章先把 `CodingKeys` 当成主线，自动策略只建立一个“我知道有这条路”的印象即可。

## 第二个现实问题：JSON 不总是平铺的

上一章里最简单的 JSON 经常长这样：

```json
{
  "title": "复习闭包",
  "estimatedHours": 2
}
```

但真实数据更常见的外形是：

```json
{
  "board_title": "周末复习看板",
  "owner": {
    "name": "Alice",
    "level": "beginner"
  },
  "tasks": [
    {
      "task_title": "复习闭包",
      "estimated_hours": 2
    },
    {
      "task_title": "整理 JSON 笔记",
      "estimated_hours": 1
    }
  ]
}
```

这里至少有三层信息：

- 最外层是一个看板对象
- `owner` 本身又是一个对象
- `tasks` 是一个对象数组

这时最稳妥的思路不是“把所有字段都塞进一个巨大的结构体”，而是：

- **JSON 里每个稳定的小结构，都给它一个对应类型**

例如：

```swift
struct StudyBoardDTO: Decodable {
    let boardTitle: String
    let owner: OwnerDTO
    let tasks: [StudyTaskDTO]

    enum CodingKeys: String, CodingKey {
        case boardTitle = "board_title"
        case owner
        case tasks
    }
}

struct OwnerDTO: Decodable {
    let name: String
    let level: String
}

struct StudyTaskDTO: Decodable {
    let taskTitle: String
    let estimatedHours: Int

    enum CodingKeys: String, CodingKey {
        case taskTitle = "task_title"
        case estimatedHours = "estimated_hours"
    }
}
```

### 这段模型最值得观察什么

1. `StudyBoardDTO` 对应最外层对象。
2. `owner` 对应另一个结构体 `OwnerDTO`。
3. `tasks` 对应 `[StudyTaskDTO]`，因为 JSON 里它是对象数组。
4. 只有字段名不一致的地方才需要映射；字段名本来一致时，不必强行每个都写进 `CodingKeys`。

你现在应该开始建立一个非常重要的直觉：

- **模型结构不是根据“我想把代码写成什么样”决定的，而是先根据 JSON 的外形决定的**

## 第三个现实问题：外层常常还有一层包装

很多真实接口返回的并不是你真正想要的对象本身，而是一个“包裹后的响应结构”。

例如：

```json
{
  "message": "success",
  "data": {
    "board_title": "周末复习看板",
    "owner": {
      "name": "Alice",
      "level": "beginner"
    },
    "tasks": [
      {
        "task_title": "复习闭包",
        "estimated_hours": 2
      }
    ]
  }
}
```

如果你这时直接拿 `StudyBoardDTO.self` 去解：

```swift
let board = try decoder.decode(StudyBoardDTO.self, from: data)
```

通常会失败。因为 JSON 的最外层不是看板本身，而是：

- 一个包含 `message`
- 以及 `data`

的响应对象。

这时就应该先把外层壳也建出来：

```swift
struct StudyBoardResponseDTO: Decodable {
    let message: String
    let data: StudyBoardDTO
}
```

然后再解：

```swift
let response = try decoder.decode(StudyBoardResponseDTO.self, from: data)
let board = response.data
```

这一点非常关键，因为它会帮你避免很多“明明数据看起来对，为什么解不出来”的困惑。

更短的记忆方式是：

- `decode` 的目标类型，必须对应 JSON 的**最外层结构**

## 第四个现实问题：有些字段可能缺失

真实 JSON 还有一个很常见的特点：

- 字段并不总是稳定出现

例如：

```json
{
  "task_title": "复习闭包",
  "estimated_hours": 2
}
```

而另一次返回可能是：

```json
{
  "task_title": "复习闭包",
  "estimated_hours": 2,
  "note": "结合第 25 章一起复习"
}
```

### 用 Optional 表达“可能没有”

如果 `note` 可能是空值，这里更稳妥的写法是把它写成`Optional`：

```swift
struct StudyTaskDTO: Decodable {
    let taskTitle: String
    let estimatedHours: Int
    let note: String?

    enum CodingKeys: String, CodingKey {
        case taskTitle = "task_title"
        case estimatedHours = "estimated_hours"
        case note
    }
}
```

这样表达的是：

- 这个字段可能存在，也可能不存在

此时如果 JSON 里没有 `note`，解码器仍然能顺利完成，只是 `note` 会得到 `nil`。

### 什么时候不该随手加 Optional

如果一个字段在业务上是必须存在的，例如标题、主键、关键状态，你就不应该为了“省事”把它们全改成 Optional。

否则会把真正的数据问题悄悄吞掉。

更稳妥的边界是：

- 字段本来就可能没有，用 Optional
- 字段本来必须存在，就保持非 Optional，让解码在数据异常时明确失败

## 第五个现实问题：缺字段时，有时你想给默认值

有些场景下，字段缺失并不代表整条数据无效。

例如：

- `is_finished` 缺失时，默认当作 `false`
- `tags` 缺失时，默认当作空数组

这时单靠属性声明本身通常不够，你需要显式告诉解码器：

- 如果这个字段没有，就给一个兜底值

最常见写法如下：

```swift
struct StudyTaskDTO: Decodable {
    let taskTitle: String
    let estimatedHours: Int
    let isFinished: Bool
    let tags: [String]

    enum CodingKeys: String, CodingKey {
        case taskTitle = "task_title"
        case estimatedHours = "estimated_hours"
        case isFinished = "is_finished"
        case tags
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        taskTitle = try container.decode(String.self, forKey: .taskTitle)
        estimatedHours = try container.decode(Int.self, forKey: .estimatedHours)
        isFinished = try container.decodeIfPresent(Bool.self, forKey: .isFinished) ?? false
        tags = try container.decodeIfPresent([String].self, forKey: .tags) ?? []
    }
}
```

### 什么是 `decodeIfPresent` 

你可以先把它理解成：

- 有值就解
- 没值就先得到 `nil`

然后再用 `??` 给出默认值。

也就是说：

- `decode` 更像“这个字段必须有”
- `decodeIfPresent` 更像“这个字段可能没有，你先别急着报错”

### 为什么这一招要谨慎用

因为“给默认值”虽然能让程序更稳，但也可能掩盖后端或数据源的问题。

所以更稳妥的原则是：

- 如果字段缺失是正常情况，才考虑给默认值
- 如果字段缺失本身就说明数据坏了，就应该让解码失败

## 把前面几种情况放到一个完整例子里

下面这个 JSON 同时包含：

- 字段映射
- 外层包装
- 嵌套对象
- 对象数组
- 可选字段
- 默认值

```json
{
  "message": "success",
  "data": {
    "board_title": "周末复习看板",
    "owner": {
      "name": "Alice",
      "level": "beginner"
    },
    "tasks": [
      {
        "task_title": "复习闭包",
        "estimated_hours": 2,
        "tags": ["closure", "review"]
      },
      {
        "task_title": "整理 JSON 笔记",
        "estimated_hours": 1,
        "note": "补充 CodingKeys 示例",
        "is_finished": true
      }
    ]
  }
}
```

对应模型可以写成：

```swift
import Foundation

struct StudyBoardResponseDTO: Decodable {
    let message: String
    let data: StudyBoardDTO
}

struct StudyBoardDTO: Decodable {
    let boardTitle: String
    let owner: OwnerDTO
    let tasks: [StudyTaskDTO]

    enum CodingKeys: String, CodingKey {
        case boardTitle = "board_title"
        case owner
        case tasks
    }
}

struct OwnerDTO: Decodable {
    let name: String
    let level: String
}

struct StudyTaskDTO: Decodable {
    let taskTitle: String
    let estimatedHours: Int
    let note: String?
    let isFinished: Bool
    let tags: [String]

    enum CodingKeys: String, CodingKey {
        case taskTitle = "task_title"
        case estimatedHours = "estimated_hours"
        case note
        case isFinished = "is_finished"
        case tags
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        taskTitle = try container.decode(String.self, forKey: .taskTitle)
        estimatedHours = try container.decode(Int.self, forKey: .estimatedHours)
        note = try container.decodeIfPresent(String.self, forKey: .note)
        isFinished = try container.decodeIfPresent(Bool.self, forKey: .isFinished) ?? false
        tags = try container.decodeIfPresent([String].self, forKey: .tags) ?? []
    }
}

let decoder = JSONDecoder()
let response = try decoder.decode(StudyBoardResponseDTO.self, from: jsonData)

print(response.message)
print(response.data.boardTitle)
print(response.data.owner.name)
print(response.data.tasks.count)
```

这段例子里最重要的不是记住每一行，而是能清楚回答下面几个问题：

1. 最外层为什么不是直接解 `StudyBoardDTO`？
2. 哪些字段用了映射？为什么？
3. 哪些字段用 Optional？为什么？
4. 哪些字段给了默认值？为什么？

只要这些判断逐渐稳定下来，你就已经在从“会解 JSON”走向“会组织解码模型”。

## 一个非常重要的概念

当前阶段最好先建立一个印象：

- **解码类型首先服务于“把 JSON 正确接进来”，而不是一开始就承担全部业务含义**

这也是为什么本章里的类型大多写成 `DTO`。

你可以先把它理解成：

- 这是一种“贴近接口原始结构”的数据类型

这样做的好处是：

- 映射关系更清楚
- 出问题时更容易定位是 JSON 结构问题还是业务逻辑问题
- 后续如果要转换成程序内部更好用的模型，也更容易拆分步骤

当前阶段你不必把“DTO 和业务模型如何分层”学得很深，但至少先建立一个意识：

- 不要急着让一个类型同时承担“解码外部数据”和“表达全部业务语义”两种责任

后续讲网络请求和更完整的数据流时，这个边界会越来越重要。

## 本章核心印象

只要你记住以下几点，本章目标便已达成：

1. 字段名不一致时，用 `CodingKeys` 做映射。
2. JSON 有嵌套结构时，就为稳定的小结构定义对应类型。
3. `decode` 的目标类型，必须匹配 JSON 最外层结构。
4. 字段可能缺失时，要先判断它在语义上是“可选”还是“应该失败”。
5. `decodeIfPresent` 配合 `??` 可以处理默认值，但不能滥用。

## 本节小结

这一章的目的是为了帮你建立下面这条判断链：

- 先看 JSON 字段名是否一致
- 再看 JSON 结构是否嵌套
- 再看字段是不是稳定存在
- 最后才决定模型里哪些地方要映射、哪些地方要 Optional、哪些地方要默认值

当你能按这个顺序看待一段 JSON 时，解码过程通常就不会再显得混乱。

## 本章练习与课后作业

请基于 `35-json-advanced-field-mapping-and-nested-structures-starter` 工程完成下面这组练习。

### 任务目标

1. 根据 starter 顶部给出的结构说明，为 `StudyTaskDTO`、`BoardOwnerDTO`、`StudyBoardDTO` 和 `StudyBoardResponseDTO` 建模。
2. 为 `StudyTaskDTO` 处理 `task_title`、`estimated_hours`、`is_finished` 这些映射字段。
3. 为 `StudyTaskDTO` 处理 `note` 的 Optional 语义，以及 `is_finished`、`tags` 的默认值。
4. 将完整字段任务 JSON 解码为 `StudyTaskDTO` 并格式化输出。
5. 将缺字段任务 JSON 解码为同一个 `StudyTaskDTO`，验证默认值生效。
6. 将包含 `message + data` 外层包装的看板 JSON 解码为响应结构并展开输出。

### 样例输出:

```text
======== 练习 1：字段映射与完整字段 ========
标题：复习闭包
预计小时数：2
备注：重点观察参数和返回值的关系
完成状态：未完成
标签：closure / review

======== 练习 2：可选项与默认值 ========
标题：整理 JSON 笔记
预计小时数：1
备注：无
完成状态：未完成
标签：无标签

======== 练习 3：外层包装与嵌套结构 ========
响应消息：success
看板标题：周末复习看板
负责人：Alice / beginner
- 复习闭包 / 2 小时 / 未完成
  备注：无备注
  标签：closure / review
- 整理 JSON 笔记 / 1 小时 / 已完成
  备注：补充 CodingKeys 示例
  标签：无标签
- 练习嵌套对象解码 / 1 小时 / 未完成
  备注：无备注
  标签：json / nested
```

### 完成标准

- 能为字段名不一致的情况写出正确的 `CodingKeys`
- 能判断最外层是否需要额外的响应包装类型
- 能为嵌套对象和对象数组建立对应模型
- 能区分 Optional 和默认值各自更适合的场景
- 能按固定格式把解码后的结果逐项展开输出

## 本章小结

务必牢记以下知识点：

- `CodingKeys` 解决的是字段名映射问题，不是所有解码问题都靠它
- 真实 JSON 经常包含外层包装、嵌套对象和对象数组
- `decode` 强调“字段应当存在”，`decodeIfPresent` 强调“字段可能不存在”
- 默认值是一种边界选择，不只是语法技巧
- 解码模型应先贴近 JSON 结构，再考虑后续业务组织

如果你能看见一段 JSON 后，先判断：

- 最外层是什么
- 每一层对象对应什么类型
- 哪些字段名不一致
- 哪些字段不稳定

那么这一章最重要的目标就已经达到了。

## 接下来怎么读

如果继续沿这条主线往下走，下一步很自然会进入第 36 章《网络请求入门：用 URLSession 获取远程 JSON》。

因为当你已经理解：

- JSON 基础解析
- 字段映射
- 嵌套结构
- 缺字段与默认值

接下来就轮到一个非常现实的问题就是：

- **这些 JSON 数据是怎样从远程接口传入程序**
