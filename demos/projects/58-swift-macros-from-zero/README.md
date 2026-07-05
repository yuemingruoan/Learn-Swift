# 58 章 demo：从零写一个 Swift 宏

## 这里有什么

这是第 58 章配套的最小 macro package。只做一件事：实现一个 freestanding 宏 `#stringify(x)`，它在编译期就地变成 `(x, "x 的源代码")`。

## 工程结构

```
58-swift-macros-from-zero/
├── Package.swift               ← 多 target，依赖 swift-syntax
└── Sources/
    ├── MacrosKitMacros/        ← .macro target：宏的实际实现（用 SwiftSyntax 操作 AST）
    │   ├── Plugin.swift
    │   └── StringifyMacro.swift
    ├── MacrosKit/              ← .target：对外宏声明，使用者 import 这个
    │   └── MacrosKit.swift
    └── MacrosDemo/             ← .executableTarget：跑一段 #stringify 看效果
        └── main.swift
└── Tests/
    └── MacrosKitTests/         ← 用 SwiftSyntaxMacrosTestSupport 测宏展开结果
        └── StringifyMacroTests.swift
```

## 怎么跑

```bash
swift run MacrosDemo   # 看 #stringify 展开后的运行结果
swift test             # 验证宏展开生成的源码字符串符合预期
```

> 第一次构建会拉 swift-syntax 并整体编译，**慢得不寻常**（首次可能 1~3 分钟，且要联网到 GitHub）。

## 怎么"看见"宏展开

打开 Xcode：

```bash
open Package.swift
```

进入 `MacrosDemo/main.swift`，把光标放在 `#stringify(...)` 上 → 右键 → **Expand Macro**。你会看到它就地变成：

```swift
let (v1, s1) = (1 + 2 * 3, "1 + 2 * 3")
```

——这就是宏的全部魔法。

## 看完之后

回到正文 `docs/zh-CN/chapters/58-swift-macros-from-zero.md`，把 `@Observable` 也按同样方式 Expand 一次，对照模块 7 的解释逐行读。
