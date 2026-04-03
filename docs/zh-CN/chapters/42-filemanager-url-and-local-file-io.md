# 42. 文件与目录：FileManager、URL 与本地读写

## 阅读导航

- 前置章节：[29. 并发入门：async/await 与 Task](./29-concurrency-basics-async-await-and-task.md)、[34. JSON 格式与解析](./34-json-format-and-parsing.md)、[41. 更完整的 HTTP：查询、分页、超时与下载](./41-http-query-pagination-timeout-and-download.md)
- 上一章：[41. 更完整的 HTTP：查询、分页、超时与下载](./41-http-query-pagination-timeout-and-download.md)
- 建议下一章：[43. 本地快照缓存：Codable、文件落盘与恢复路径](./43-codable-persistence-and-local-cache.md)
- 下一章：[43. 本地快照缓存：Codable、文件落盘与恢复路径](./43-codable-persistence-and-local-cache.md)
- 适合谁先读：已经能写最基本的 `try`/`do-catch`，并且开始遇到“下载到的内容要放到哪里”“怎么下次启动还能读回”的读者。

## 本章目标

学完本章后，你将能够：

- 用清晰的心智模型区分：**路径（path）**、**目录（directory）**、**文件（file）**分别是什么。
- 理解并使用**文件 URL（file URL）**：它和网络 URL（https URL）长得像，但语义完全不同。
- 在应用沙盒（或用户目录）中找到合适的落盘位置：文档目录（Documents）、缓存目录（Caches）和临时目录（tmp）的职责差异。
- 建立最小可用链路：把 `String` / `Data` 写入本地文件，再从本地读回，并能处理“文件不存在、读写失败”等最小失败路径。
- 为下一章“用 `Codable` 把模型落盘做本地缓存”打好地基：先把“写到哪、怎么写、失败怎么分”讲清楚。

本章只看**本地文件 I/O**：路径、目录、文件存在性，以及读写失败该怎么分。

本章不会展开数据库、缓存策略大全或 SwiftData。下一章会在本章基础上用 `Codable` 串起“模型落盘与读取”。

## 正文主体

### 0. 为什么“下载之后”很快就会遇到文件系统

在第 41 章你已经见过“拿到一段内容”的场景：可能是 JSON，也可能是图片、PDF、音频等二进制数据。

拿到内容之后，通常马上会碰到两个问题：

- 下一次启动 App，还要不要重新请求/重新下载？
- 用户希望把内容“保存下来”时，保存到哪里？用什么名字？要不要覆盖？

这两个问题最后都会落到**本地文件系统**上。本章先把文件系统这层打通，下一章再接模型持久化和本地缓存。

### 1. 文件、目录、路径：三个概念先分清

可以把应用的本地存储想成一棵树：

- **目录（directory / folder）**：树上的分支，里面可以装别的目录或文件。
- **文件（file）**：树上的叶子，里面装的是内容（文本或二进制数据）。
- **路径（path）**：从根走到某个节点的“走法描述”，常见表现是一个字符串，例如 `/Users/.../note.txt`。

在编程里最容易踩的坑是：把“路径字符串”当成“万能定位方式”，然后自己手写拼接。

因此在这里我们先提出几条原则：

- **不要手写绝对路径**（因为沙盒路径会变、不同平台不一样、也不利于迁移）。
- **尽量不要自己拼路径字符串**（因为分隔符、转义、相对路径等问题很容易埋雷）。
- 用系统 API 给你的“基准目录”，再在其上“追加文件名/子目录名”。

### 2. URL 不等于网络地址：文件 URL 和网络 URL 的区别

在`Swift`里，`URL` 并不仅仅代表“网页链接”。

`URL` 其实只是一个统一的资源定位方式。最常见的有两类：

- **网络 URL**：例如 `https://example.com/image.png`，定位远程资源。
- **文件 URL**：例如 `file:///var/mobile/Containers/.../note.txt`，定位本地文件。

它们的核心区别在于：

- **scheme 不同**：网络 URL 常见是 `https`/`http`，文件 URL 是 `file`。
- **语义不同**：网络 URL 指向远端，需要网络请求；文件 URL 指向本机文件，读写通常不需要网络。

本章只讨论**文件 URL**，也就是本地文件 I/O。不要把它和网络下载混在一起：`URLSession` 负责网络请求；本章关注的是你已经拿到 `String`/`Data` 后，如何落盘与读回。

### 3. 先按 macOS 开发环境理解：Documents / Caches / tmp

当前这套教程的开发环境以 **macOS** 为主，所以这里先按 macOS 的直觉来理解这些目录。

如果你现在跑的是命令行工具，或是在 macOS 上做最基础的本地文件实验，那么你可以先把这些目录理解成“当前用户目录下的一些标准位置”：

- `Documents`
  - 用户文稿目录
- `Library/Caches`
  - 当前用户的缓存目录
- `tmp`
  - 系统提供的临时目录

这样理解会更贴近你手头的开发环境，也更方便你用 Finder 或终端去观察真实文件位置。

等你后面切到 App 沙盒环境时，再额外补一层理解：

- 同样是 `.documentDirectory`
- 在沙盒 App 里返回的就不再是“用户根目录下的 Documents”
- 而是“当前 App 容器里的 Documents”

先把这三类目录的职责差异记住就够了：

- **Documents（文档目录）**：更偏“用户数据”，希望随备份、可长期保存的内容。
- **Caches（缓存目录）**：可再生成的数据，系统可能在空间紧张时清理它，不能把它当成永久仓库。
- **tmp（临时目录）**：短期中转，随时可能被清理，更适合解压、临时下载片段、一次性导出等场景。

你可以先把本章的大部分代码都理解成：

- “在 macOS 上向系统询问标准目录位置”

而不是：

- “手写一条固定路径去猜文件应该放在哪”

等将来切到 iOS / iPadOS / macOS App 沙盒时，代码写法依然成立，只是系统返回的具体路径会换成当前应用容器里的位置。

### 4. FileManager：你和文件系统的基础接口

`FileManager` 是 Foundation 里最常用的文件系统入口。它能做很多事，但本章只取初学者最常用的一小部分：

- 获取常用目录 URL
- 检查文件/目录是否存在
- 创建目录
- 配合 `String` / `Data` 完成读写

先创建一个 `FileManager`：

```swift
import Foundation

let fm = FileManager.default
```

`FileManager`

- 它解决的问题：作为文件系统操作入口，统一负责找目录、查存在、建目录、删文件。
- 本章常用成员：`default`、`temporaryDirectory`
- 本章常用函数：`url(for:in:appropriateFor:create:)`、`fileExists(atPath:isDirectory:)`、`createDirectory(at:withIntermediateDirectories:attributes:)`、`removeItem(at:)`
- 当前代码里怎么理解：后面不管是缓存文件还是本地 store 文件，第一步都离不开它。

`URL`

- 它解决的问题：稳定表示本地文件位置，而不是自己手写路径字符串。
- 本章常用成员：`path`、`lastPathComponent`
- 本章常用函数：`appendingPathComponent(_:)`、`appendingPathComponent(_:isDirectory:)`
- 当前代码里怎么理解：它既可以表示目录，也可以表示文件。

对应文档：

- [`FileManager`（Apple Developer）](https://developer.apple.com/documentation/foundation/filemanager)
- [`URL`（Apple Developer）](https://developer.apple.com/documentation/foundation/url)
- [`Data`（Apple Developer）](https://developer.apple.com/documentation/foundation/data)

如果你去看 Apple Developer 文档，会发现 `FileManager` 并不是只认识 `Documents` 和 `Caches`。它内部有一组专门的目录枚举：

- `FileManager.SearchPathDirectory`

这组枚举表示“系统里一些有明确语义的重要目录位置”，例如：

- `.documentDirectory`
- `.cachesDirectory`
- `.downloadsDirectory`
- `.desktopDirectory`
- `.applicationSupportDirectory`
- `.libraryDirectory`
- `.trashDirectory`

如果只从“名字对应的大致目录”来理解，可以先记成下面这样：

- `.documentDirectory`
  - 典型对应 `Documents`
- `.cachesDirectory`
  - 典型对应 `Library/Caches`
- `.applicationSupportDirectory`
  - 典型对应 `Library/Application Support`
- `.libraryDirectory`
  - 典型对应 `Library`
- `.downloadsDirectory`
  - 典型对应 `Downloads`
- `.desktopDirectory`
  - 典型对应 `Desktop`
- `.moviesDirectory`
  - 典型对应 `Movies`
- `.musicDirectory`
  - 典型对应 `Music`
- `.picturesDirectory`
  - 典型对应 `Pictures`
- `.trashDirectory`
  - 典型对应废纸篓目录

这里要特别注意“典型对应”这四个字：

- 这些名字表达的是**目录语义**
- 不等于你可以在代码里硬编码出一条固定字符串路径

例如在当前的 macOS 开发环境里、在命令行工具里、在沙盒 App 里，同一个 `.documentDirectory` 背后返回的具体路径都可能不同。这里更关心的是两件事：

- 你知道这个枚举值代表哪一类目录
- 然后通过 `FileManager` 向系统拿到当前环境下真正可用的 `URL`

换句话说，`FileManager` 不是让你自己写字符串去猜路径，而是先把两件事说清楚：

- “我要哪一类目录”
- “我要在哪个 domain 里找”

然后再由系统返回对应的 `URL`。

这也是为什么前面一直强调：

- 不要手写绝对路径
- 优先通过 `FileManager` 提供的目录语义去找位置

不过在当前阶段，没必要把 `SearchPathDirectory` 的所有 case 都背下来。很多目录要么有平台历史包袱，要么更偏桌面系统语义，例如：

- `.applicationDirectory`
- `.developerDirectory`
- `.documentationDirectory`
- `.moviesDirectory`
- `.musicDirectory`
- `.picturesDirectory`

它们当然真实存在，也确实能通过 `FileManager` 获取，但在本书当前主线里，最值得优先掌握的仍然是这几个：

- `.documentDirectory`
- `.cachesDirectory`
- `.applicationSupportDirectory`
- `temporaryDirectory`

后面如果你看到 `FileManager.url(for:in:appropriateFor:create:)` 里的：

- `.documentDirectory`
- `.cachesDirectory`

不要把它当成“随便传个枚举值”，它背后其实是在问系统：

- “请给我这个类型的标准目录位置”

#### 4.1 获取“基准目录 URL”

拿 Documents 目录举例。在你当前的 macOS 开发环境里，它通常更接近“当前用户可用的文稿目录”；如果换成沙盒 App，它会返回当前 App 容器里的 Documents 目录：

```swift
let documentsURL = try fm.url(
    for: .documentDirectory,
    in: .userDomainMask,
    appropriateFor: nil,
    create: true
)
```

`url(for:in:appropriateFor:create:)`

- 参数：
  - `for`：想要哪一类标准目录
  - `in`：在哪个 domain 里找
  - `appropriateFor`：是否参考另一个 URL 决定位置
  - `create`：目录不存在时是否允许创建
- 返回值：
  - 目标目录 `URL`
- 作用：
  - 向系统请求当前环境下真正可用的标准目录位置

对应文档：

- [`url(for:in:appropriateFor:create:)`（Apple Developer）](https://developer.apple.com/documentation/foundation/filemanager/url%28for%3Ain%3Aappropriatefor%3Acreate%3A%29)
- [`temporaryDirectory`（Apple Developer）](https://developer.apple.com/documentation/foundation/filemanager/temporarydirectory)

这四个参数最好按顺序理解：

- `for: .documentDirectory`
  - 你要找的是哪一类目录。
  - 这里表示“文档目录”。

- `in: .userDomainMask`
  - 你要在哪个 domain 里找。
  - 当前阶段先把它理解成“当前用户这一侧的目录范围”就够了。
  - 也就是说，这里不是去找系统级共享目录，而是找当前用户可用的那份目录位置。

- `appropriateFor: nil`
  - 这个参数主要用于某些“和另一个 URL 有关系的目录定位场景”，例如临时替换目录之类。
  - 对当前教程里的 Documents / Caches 获取来说，通常不需要特殊上下文，所以先传 `nil`。
  - 你可以先把它理解成：“这次不需要参考别的 URL 来决定放哪”。

- `create: true`
  - 如果目录不存在，系统会尝试创建它。
  - 获取失败会抛错，所以要用 `try`。

如果把整句翻译成自然语言，它大致是在说：

- “请在当前用户范围里，给我文档目录的 URL；如果没有，就尝试创建。”

同一个方法签名以后会反复出现，所以这里把它读顺很重要。初学阶段你最常见的搭配通常就是：

- `for: .documentDirectory` + `in: .userDomainMask`
- `for: .cachesDirectory` + `in: .userDomainMask`

类似地，你也会用到 Caches 目录：

```swift
let cachesURL = try fm.url(
    for: .cachesDirectory,
    in: .userDomainMask,
    appropriateFor: nil,
    create: true
)
```

临时目录通常用 `FileManager.default.temporaryDirectory`：

```swift
let tempURL = fm.temporaryDirectory
```

#### 4.2 从目录 URL 拼出“目标文件 URL”

文件 URL 的正确拼法是**基于目录 URL 追加 path component**：

```swift
let noteFileURL = documentsURL.appendingPathComponent("note.txt")
```

如果你要把文件放到一个子目录里，也一样拼：

```swift
let folderURL = documentsURL.appendingPathComponent("notes", isDirectory: true)
let noteInFolderURL = folderURL.appendingPathComponent("note.txt")
```

这里不要用字符串手写 `"/notes/note.txt"` 去拼接。`URL` 的 `appendingPathComponent` 会更稳健，也更符合“用类型表达意图”的风格。

`appendingPathComponent(_:)`

- 参数：
  - 一个路径片段，例如 `"note.txt"`
- 返回值：
  - 新的 `URL`
- 作用：
  - 在已有 URL 末尾继续拼出一个子路径，常用于文件名

`appendingPathComponent(_:isDirectory:)`

- 参数：
  - 路径片段
  - `isDirectory`：这段路径是否代表目录
- 返回值：
  - 新的 `URL`
- 作用：
  - 在拼接路径时把“这是目录还是文件”的意图表达清楚

后面第 `43` 章缓存文件路径和第 `44` 章 SwiftData store 路径，都会直接复用这套写法。

对应文档：

- [`appendingPathComponent(_:)`（Apple Developer）](https://developer.apple.com/documentation/foundation/url/appendingpathcomponent%28_%3A%29)
- [`appendingPathComponent(_:isDirectory:)`（Apple Developer）](https://developer.apple.com/documentation/foundation/url/appendingpathcomponent%28_%3Aisdirectory%3A%29)

#### 4.3 文件/目录是否存在：先判断再处理失败路径

最常用的是按路径检查（`URL` 提供 `.path`）：

```swift
var isDirectory: ObjCBool = false
let exists = fm.fileExists(atPath: folderURL.path, isDirectory: &isDirectory)

if exists && isDirectory.boolValue {
    print("目录存在")
} else if exists {
    print("存在，但它是文件，不是目录")
} else {
    print("不存在")
}
```

`fileExists(atPath:isDirectory:)`

- 参数：
  - 路径字符串
  - 一个可回写“是否为目录”的变量
- 返回值：
  - `Bool`
- 作用：
  - 检查这条路径上是否真的有文件系统对象，并区分它是文件还是目录

对应文档：

- [`fileExists(atPath:isDirectory:)`（Apple Developer）](https://developer.apple.com/documentation/foundation/filemanager/fileexists%28atpath%3Aisdirectory%3A%29)

这里需要解释一下：

- `atPath: folderURL.path`
  - `fileExists` 在这里要的是路径字符串，不是 `URL` 本身。
  - 所以我们把 `folderURL` 转成 `.path` 再传进去。
  - 你可以把它理解成：“去检查这条路径上有没有东西”。

- `isDirectory: &isDirectory`
  - 这个参数的作用是：如果路径上真的有东西，系统顺手把“它是不是目录”写回到这个变量里。
  - 也就是说，这个方法不只返回 `exists`，还额外通过 `isDirectory` 带回第二个信息。

这里的 `&` 表示：

- 不是把 `isDirectory` 当前的值复制进去
- 而是把这个变量本身交给函数，让函数可以回写结果

你可以先把它理解成一种“请帮我把答案填到这个变量里”的写法。

学过C++的同学应该有一种“似曾相识”的感觉

没错，这就是C++中所谓的实参

所以这段代码实际上同时拿到了两件事：

- `exists`
  - 路径上是否存在某个文件系统对象
- `isDirectory.boolValue`
  - 如果存在，它是不是目录

为什么这里要先声明：

```swift
var isDirectory: ObjCBool = false
```

原因是：

- 这个参数需要一个**可变变量**
- 类型还要符合这个 API 期待的 `ObjCBool`

如果你不加 `&`，那就只是把一个普通值传进去，函数没法把“是否为目录”的结果带出来。

为什么要区分“存在但类型不对”？因为在真实项目里，错误地把文件当目录、把目录当文件，会让后续读写出现更隐蔽的失败。

#### 4.4 创建目录：保证写入路径可用

要把文件写进某个子目录前，先确保目录存在：

```swift
try fm.createDirectory(
    at: folderURL,
    withIntermediateDirectories: true,
    attributes: nil
)
```

`withIntermediateDirectories: true` 的含义是：如果中间层级不存在，也一并创建（类似 `mkdir -p`）。

`createDirectory(at:withIntermediateDirectories:attributes:)`

- 参数：
  - `at`：目标目录 URL
  - `withIntermediateDirectories`：是否递归创建中间目录
  - `attributes`：附加文件属性，入门阶段通常传 `nil`
- 返回值：
  - `Void`
- 作用：
  - 在真正写文件前，保证目标目录结构已经存在

这也是后面第 `43` 章、`44` 章反复出现 `fm.createDirectory(...)` 的原因：先把目录准备好，后续写缓存文件或 store 文件时才不会因为父目录不存在而失败。

对应文档：

- [`createDirectory(at:withIntermediateDirectories:attributes:)`（Apple Developer）](https://developer.apple.com/documentation/foundation/filemanager/createdirectory%28at%3Awithintermediatedirectories%3Aattributes%3A%29)

### 5. 写入与读取：String 与 Data 的两条最小链路

本章只讲两个最常见的落盘形态：

- **文本（String）**：例如日志、简单配置、你临时保存的 JSON 文本。
- **二进制（Data）**：例如下载到的图片、音频、以及“编码后的 JSON”。

#### 5.1 写入与读取 String

写入：

```swift
let content = "Hello, File IO!"
try content.write(to: noteFileURL, atomically: true, encoding: .utf8)
```

读取：

```swift
let readBack = try String(contentsOf: noteFileURL, encoding: .utf8)
print(readBack)
```

这里有两个初学者常见问题：

- `encoding` 选什么？最常见是 `.utf8`。如果你写入和读取用的编码不一致，读出来就可能是乱码或直接失败。
- `atomically: true` 做了什么？它会用“写临时文件再替换”的方式减少部分写入导致的损坏风险（仍然要准备失败路径，但这是一个合理的默认值）。

#### 5.2 写入与读取 Data（更贴近下载结果）

写入：

```swift
let data = Data([0x48, 0x69]) // "Hi"
try data.write(to: noteFileURL, options: [.atomic])
```

读取：

```swift
let readBackData = try Data(contentsOf: noteFileURL)
print("bytes:", readBackData.count)
```

`write(to:options:)`

- 参数：
  - 目标文件 `URL`
  - 写入选项，例如 `.atomic`
- 返回值：
  - `Void`
- 作用：
  - 把当前 `Data` 真正写入磁盘文件

`init(contentsOf:)`

- 参数：
  - 要读取的文件 `URL`
- 返回值：
  - 读回来的 `Data`
- 作用：
  - 从文件读出原始字节，后面可以继续转成 `String`、JSON 或别的结构

对应文档：

- [`Data.write(to:options:)`（Apple Developer）](https://developer.apple.com/documentation/foundation/data/write%28to%3Aoptions%3A%29)
- [`Data.init(contentsOf:)`（Apple Developer）](https://developer.apple.com/documentation/foundation/data/init%28contentsof%3Aoptions%3A%29)

如果你确信它是 UTF-8 文本，也可以把 `Data` 转回 `String`：

```swift
let text = String(decoding: readBackData, as: UTF8.self)
print(text)
```

注意：`Data -> String` 的成功并不代表“内容是你业务需要的结构”。例如你读回的是一段 JSON 文本，下一步还要解析/解码；那已经属于下一章的主题了。

### 6. 最小失败路径：文件不存在、路径不可用、读写失败怎么分

文件 I/O 的一个核心训练目标是：不要把所有失败都打印成同一句“失败了”，而是能区分：

- **路径层面**：目录不存在、要写入的父目录没创建、目标 URL 拼错。
- **存在性层面**：文件压根不存在（读取时最常见）。
- **权限/环境层面**：无写权限、沙盒限制、或命令行工具运行目录与你预期不一致。
- **内容层面**：文件存在但内容不是你期望的格式（例如 JSON 损坏，或编码不是 UTF-8）。

你至少应该能写出这样的最小处理：

```swift
do {
    let text = try String(contentsOf: noteFileURL, encoding: .utf8)
    print("read ok:", text.count)
} catch {
    // 这里只做“最小可观察”，更细的错误分类在真实项目里会做得更完整
    print("read failed:", error)
}
```

以及在读取前先检查存在性，给出更明确的分支：

```swift
if fm.fileExists(atPath: noteFileURL.path) {
    let text = try String(contentsOf: noteFileURL, encoding: .utf8)
    print(text)
} else {
    print("file not found:", noteFileURL.lastPathComponent)
}
```

`removeItem(at:)`

- 参数：
  - 目标文件或目录 `URL`
- 返回值：
  - `Void`
- 作用：
  - 删除某个已存在的文件系统对象

这会在下一章的坏缓存恢复里直接复用，所以先在这里建立认识更顺手。

对应文档：

- [`removeItem(at:)`（Apple Developer）](https://developer.apple.com/documentation/foundation/filemanager/removeitem%28at%3A%29)

这种写法的价值在于：你能把“文件不存在”和“读取失败”分开处理。对缓存来说，这两个分支的业务含义通常完全不同：

- 文件不存在：首次启动/首次请求，很正常，走“去远程拿”。
- 读取失败：可能是写入中断、内容损坏、版本不兼容，可能需要清理缓存或回退。

### 7. 用 JSON 文件把链路串起来（为下一章铺路）

本节只做一件事：把“JSON 内容作为文本或二进制”保存为文件，再读回来打印。我们先不在本章把它解码成模型，避免提前混入 `Codable` 的主题。

```swift
let jsonText = """
{
  "name": "Alice",
  "score": 95
}
"""

let jsonFileURL = documentsURL.appendingPathComponent("profile.json")

// 写入（作为文本）
try jsonText.write(to: jsonFileURL, atomically: true, encoding: .utf8)

// 读回（再打印）
let readBack = try String(contentsOf: jsonFileURL, encoding: .utf8)
print(readBack)
```

把这一步做好后，下一章要做的事情就非常自然了：

- 用 `Codable` 把模型编码为 `Data`（通常是 JSON）
- 把 `Data` 写入文件
- 下次启动先读文件再解码回模型

这也是本章刻意强调“文件存在性”和“内容可用性”是两回事的原因：文件读回来了，不代表 JSON 一定能解码成功。

## 边界说明

为了把初学者的复杂度控制在可理解范围内，本章**不覆盖**以下内容：

- 不提前讲数据库（例如 SQLite、Core Data、SwiftData），也不讲完整缓存策略（过期、容量、淘汰、同步冲突等）。
- 不深入讲沙盒权限、安全作用域（security-scoped）、文件协调（File Coordination）、iCloud Drive、文件导入导出 UI 等平台细节。
- 不讨论“下载到磁盘”的高级网络细节（后台下载、断点续传、流式写入）。本章假设你已经拿到 `String` 或 `Data`，然后才谈落盘与读取。

本章只负责打好地基：用正确的目录、正确的文件 URL、以及可观察的失败路径，完成最小本地文件读写闭环。
