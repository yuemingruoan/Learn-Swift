import Foundation

// 任务 1：实现一个 MenuBuilder
//
// 我们要做一个命令行菜单 DSL：
//
//     let m = menu(title: "主菜单") {
//         item("新建文件")
//         item("打开文件")
//         if isPro {
//             item("导出 PDF")
//         } else {
//             item("升级到 Pro")
//         }
//         for name in recentFiles {
//             item("最近：\(name)")
//         }
//         submenu(title: "设置") {
//             item("外观")
//             item("快捷键")
//         }
//     }
//
//     print(m.render())
//
// 你需要：
// 1. 设计 MenuNode 类型，至少能表达 item / submenu 两类
// 2. 实现 MenuBuilder：支持 buildExpression / buildBlock / buildOptional /
//    buildEither(first:) / buildEither(second:) / buildArray
// 3. 提供 menu(title:_:) / submenu(title:_:) / item(_:) 三个函数
// 4. 提供 render() 方法，把菜单按缩进打印成文本
//
// 推荐的 MenuNode 长这样（可改）：
//
//     public enum MenuNode {
//         case item(String)
//         indirect case submenu(String, [MenuNode])
//     }

// 任务 2：读一段 DSL，写出它的展开形态
//
// 用你实现好的 MenuBuilder（或正文里的 HTMLBuilder）读下面这段代码，
// 它同时含有"顺序 + if/else + for-in"三种结构：
//
//     func makeMenu(isPro: Bool, recent: [String]) -> MenuNode {
//         menu(title: "主菜单") {
//             item("新建文件")
//             if isPro {
//                 item("导出 PDF")
//             } else {
//                 item("升级到 Pro")
//             }
//             for name in recent {
//                 item("最近：\(name)")
//             }
//         }
//     }
//
// 在练习答案文档里：
// - 写出 menu(title:) 的闭包体被改写成 build* 方法调用后的大致形态
// - 列表说明每个语法结构（裸表达式 / 顺序 / if-else / for-in）各对应哪个 build 方法
// - 思考题：一个 result builder 到底该不该实现 buildArray？
//   实现了能让闭包体直接写 for-in，不实现又是出于什么考量（性能、稳定标识等）？

print("starter 已就绪，请在本文件实现 MenuBuilder。")
