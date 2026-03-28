# 35. JSON 进阶：字段映射与复杂结构 练习答案

对应章节：

- [35. JSON 进阶：字段映射与复杂结构](../../../docs/zh-CN/chapters/35-json-advanced-field-mapping-and-nested-structures.md)

如果你想一边看答案一边运行 starter project，可以打开：

- `exercises/zh-CN/projects/35-json-advanced-field-mapping-and-nested-structures-starter`

如果你想直接运行本章练习的参考工程，也可以打开：

- `exercises/zh-CN/answers/35-json-advanced-field-mapping-and-nested-structures`

说明：

- 这道题只有 1 份根 JSON 结构，但给了 3 段不同的数据。
- 同一个根对象里同时包含基础字段、嵌套对象、对象数组，以及可复用的共享子结构。
- 练习重点不是把 JSON 机械拆平，而是识别哪些子结构应该被独立抽成可复用模型。

## 当前问题

starter project 里主要有下面几类空缺：

1. 根对象还没有真正处理 `task_title`、`estimated_hours`、`is_finished` 这些映射字段。
2. 根对象还没有处理 `note`、`tags`、`resources` 缺失时的默认值或 Optional 语义。
3. 嵌套对象 `owner`、`contact`、`progress` 以及数组 `checkpoints`、`resources` 还没有建模。
4. `link` 这份共享子结构会在多个位置重复出现，但 starter 没有直接告诉你该如何抽模型。
5. 三段 JSON 的输出还没有把多层嵌套和共享子结构展开。

## 你需要完成的修改

1. 为同一个根模型补齐字段映射和默认值处理。
2. 为 `owner`、`contact`、`progress`、`checkpoint`、`resource` 这些嵌套结构建模。
3. 识别并抽出共享的 `link` 子结构，让它能复用于多个位置。
4. 在 `decodeTask(from:)` 里把 `Data` 解成这个根模型。
5. 分别解码 3 段 JSON，并证明它们都能落到同一套结构上。
6. 在输出函数里同时展开：
   - 根对象字段
   - 嵌套对象字段
   - 数组元素字段
   - 共享子结构字段
   - 缺失字段与空值的区别

## 完成标准

完成后，你的代码至少应该表现出下面这些特征：

- 知道字段名不一致时应使用 `CodingKeys`
- 知道嵌套对象和对象数组要如何继续拆成子模型
- 知道重复出现的结构应该抽成共享类型，而不是复制多份定义
- 知道 `note` 这种字段缺失时应保留 Optional 语义
- 知道 `is_finished`、`tags`、`links`、`checkpoints`、`resources` 缺失时如何给默认值
- 知道数组元素内部也可以继续做默认值处理
- 输出结果不是一句笼统描述，而是把每层结构逐项展开

## 目标输出

这道题不建议自由发挥输出格式，参考答案采用下面这份固定输出：

```text
======== 练习 1：共享子结构与多层嵌套 ========
标题：复习闭包
预计小时数：2
备注：重点观察参数和返回值的关系
完成状态：未完成
标签：closure / review
负责人：Alice / beginner
负责人链接：
- Alice 的学习主页 / https://study.example.com/alice / 主链接
- 闭包讨论群 / https://chat.example.com/closure / 普通链接
当前步骤：2
检查点：
- 阅读闭包语法 / 已完成
  参考链接：
  - 官方文档 / https://swift.org/documentation/ / 主链接
- 手写排序闭包 / 未完成
  参考链接：无
资源：
- 闭包语法卡片 / article / 必学
  链接：
  - 文档页 / https://example.com/closure-card / 主链接
- Swift Playgrounds 练习 / exercise / 选学
  链接：无

======== 练习 2：缺失字段与默认值 ========
标题：整理 JSON 笔记
预计小时数：1
备注：无
完成状态：未完成
标签：无标签
负责人：Bob / beginner
负责人链接：无
当前步骤：1
检查点：无
资源：无

======== 练习 3：空字符串与空数组 ========
标题：检查空字符串和空数组
预计小时数：1
备注：（空字符串）
完成状态：已完成
标签：无标签
负责人：Carol / intermediate
负责人链接：无
当前步骤：3
检查点：无
资源：无
```

## 参考实现方向

这一题最关键的思路，是把一整棵 JSON 结构分层建出来，并在重复出现的位置抽出共享类型。

根对象大致会包含：

- 任务基础信息
- `owner` 嵌套对象
- `owner.contact` 嵌套对象
- `progress` 嵌套对象
- `checkpoints` 对象数组
- `resources` 对象数组

而 `link` 这份共享子结构，会同时出现在：

- `owner.contact.links`
- `progress.checkpoints[].references`
- `resources[].links`

参考实现通常会接近下面这种拆法：

```swift
struct StudyLinkDTO: Decodable {
    let linkLabel: String
    let url: String
    let isPrimary: Bool
}

struct StudyOwnerContactDTO: Decodable {
    let links: [StudyLinkDTO]
}

struct StudyOwnerDTO: Decodable {
    let name: String
    let level: String
    let contact: StudyOwnerContactDTO
}

struct StudyCheckpointDTO: Decodable {
    let title: String
    let isDone: Bool
    let references: [StudyLinkDTO]
}

struct StudyResourceDTO: Decodable {
    let resourceTitle: String
    let kind: String
    let isRequired: Bool
    let links: [StudyLinkDTO]
}
```

然后分别在不同层处理自己的边界：

- 根对象处理 `task_title`、`estimated_hours`、`is_finished`
- `link` 处理 `link_label`、`is_primary`
- `checkpoint` 处理 `is_done`
- `resource` 处理 `resource_title`、`is_required`

## 分题解析

这一题表面上是在练 `Decodable`，实际上更重要的是训练下面这条判断顺序：

1. 先确认多段 JSON 是否其实属于同一个根结构。
2. 再把嵌套对象和数组元素一层层拆出来。
3. 再观察有没有重复出现的结构，决定是否抽成共享模型。
4. 再看字段名和 Swift 属性名是否一致。
5. 再判断某个字段缺失时应该失败、保持 Optional，还是给默认值。
6. 最后才是把解码后的结构按题目格式输出。

只要这套顺序稳定了，后面再接真实接口时，解码过程就不会显得混乱。

### 练习 1：共享子结构与多层嵌套

第一段 JSON 最值得注意的，不只是 `snake_case`，还包括：

- `owner.contact.links` 是对象数组
- `progress.checkpoints[].references` 是对象数组
- `resources[].links` 也是对象数组

这三处虽然挂在不同父对象下面，但元素结构其实一致。

因此最值得建模的地方，不只是“把 JSON 解出来”，而是主动识别出它们都应该复用同一个 `StudyLinkDTO`。

### 练习 2：缺失字段与默认值

第二段 JSON 故意省略了：

- `note`
- `is_finished`
- `tags`
- `owner.contact.links`
- `progress.checkpoints`
- `resources`

这时最重要的是分清：

- 哪些字段是可以缺失的
- 缺失之后是变成 `nil`
- 还是补成 `false`
- 还是补成 `[]`

如果这一步想不清楚，模型通常会被写得又松又乱。

### 练习 3：空字符串与空数组

第三段 JSON 则强调另一件事：

- 字段缺失，不等于字段存在但值为空

例如：

- `note == nil` 表示没有提供备注
- `note == ""` 表示提供了备注字段，只是内容为空
- `owner.contact.links == []` 表示字段存在，但当前没有任何负责人链接

从解码角度看，后两者并不会失败，但输出层最好把它们表达清楚。

## 参考答案代码

参考工程已经放在：

- `exercises/zh-CN/answers/35-json-advanced-field-mapping-and-nested-structures`

建议你先自己独立完成 starter，再回来看答案，因为这道题真正要训练的不是语法记忆，而是看到一棵更复杂的 JSON 结构后，能不能先稳定判断：

1. 根对象是谁。
2. 哪些字段必须存在。
3. 哪些地方需要继续拆子模型。
4. 哪些结构值得被复用成共享模型。
5. 哪些字段该 Optional。
6. 哪些字段该给默认值。
