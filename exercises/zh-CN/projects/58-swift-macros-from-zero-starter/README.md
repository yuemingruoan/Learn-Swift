# 58 章练习 starter：写一个 `#URL` 宏

请你完成第 58 章练习题 2：实现一个 freestanding 宏 `#URL("https://...")`，要求：

- 编译期校验字符串是否为合法 URL
- 合法 → 展开为 `URL(string: "...")!`
- 非字符串字面量 / 不合法字符串 → 抛编译错误

按以下步骤推进：

1. 看 `Sources/URLKit/URLKit.swift` —— 写宏的对外声明
2. 看 `Sources/URLKitMacros/URLMacro.swift` —— 写 `URLMacro: ExpressionMacro` 的实现
3. 看 `Sources/URLKitMacros/Plugin.swift` —— 把 `URLMacro` 加到 `providingMacros`
4. 看 `Sources/URLDemo/main.swift` —— 用 `#URL("...")` 验证它确实可用
5. 看 `Tests/URLKitTests/URLMacroTests.swift` —— 写三个测试：合法、参数非字面量、参数不合法

写完之后跑：

```bash
swift test
swift run URLDemo
```

完成后请阅读 `exercises/zh-CN/answers/58-swift-macros-from-zero.md` 比对参考答案与思考题答案。
