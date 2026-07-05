import Foundation

// 任务：写一个 freestanding 宏 #URL，让：
//
//     #URL("https://example.com")
//
// 在编译期：
// - 如果传入的字符串是合法 URL：展开为 URL(string: "https://example.com")!
// - 如果传入的不是字符串字面量、或字符串不能构造合法 URL：抛编译错误
//
// 提示（实现思路，留给你自己写）：
//
// 1. 在 URLKit 里写宏的对外声明：
//
//        @freestanding(expression)
//        public macro URL(_ string: String) -> URL =
//            #externalMacro(module: "URLKitMacros", type: "URLMacro")
//
// 2. 在 URLKitMacros 里写 URLMacro: ExpressionMacro：
//    - 取 node.arguments.first?.expression
//    - 用 .as(StringLiteralExprSyntax.self) 判断是否为字符串字面量；不是就抛错
//    - 取出字符串字面量内容，用 Foundation.URL(string:) 校验
//    - 校验失败抛错；校验通过返回 ExprSyntax: "URL(string: \(literal: text))!"
//
// 3. 在 URLKitMacros/Plugin.swift 注册 URLMacro
// 4. 在下面的 URLDemo/main.swift 里调用 #URL 验证

// 等你写完之后，下面这一行应该能直接跑：
// let homepage = #URL("https://example.com")
// print(homepage)

print("starter 已就绪，请按 README 的步骤完成 #URL 宏。")
