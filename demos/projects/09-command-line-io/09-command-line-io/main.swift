//
//  main.swift
//  09-command-line-io
//
//  Created by 时雨 on 2026/3/17.
//

import Foundation

/*
*   命令行输出的最基础写法
*/
print("Hello, Swift")

let courseName = "命令行输入与输出"
let chapterNumber = 9
print("当前章节是：", chapterNumber)
print("当前主题是：", courseName)
/*
*   预期输出：
*   Hello, Swift
*   当前章节是： 9
*   当前主题是： 命令行输入与输出
*/

print("---------") // 手动分割线

/*
*   readLine() 会读取一整行输入
*   它的结果是 String?，所以要先用 if let 处理
*/
print("请输入一段文本，然后按回车：")
if let text = readLine() {
    print("你输入的是：", text)
    print("text 的类型是：", type(of: text))
}
/*
*   这里的输出会根据用户输入而变化
*   例如如果输入：
*   Hello
*
*   那么通常会看到：
*   你输入的是： Hello
*   text 的类型是： String
*/

print("---------") // 手动分割线

/*
*   一个最简单的交互程序：
*   读取名字，然后输出欢迎语
*/
print("请输入你的名字：")
if let name = readLine() {
    print("你好，", name)
}
/*
*   例如如果输入：
*   Alice
*
*   那么通常会看到：
*   你好， Alice
*/

print("---------") // 手动分割线

/*
*   一个小技巧：
*   使用 terminator: "" 可以让输出后先不换行
*   这样用户就可以直接在冒号后面输入
*   某些环境里为了让提示更稳妥地立即显示，
*   可以再配合 fflush(stdout)
*/
print("下面这两段代码的区别在于：一段不手动刷新，一段手动刷新")

print("【未手动刷新】请输入你的学校：", terminator: "")
if let school = readLine() {
    print("你输入的学校是：", school)
}
/*
*   这段代码在很多环境里也可能正常工作，
*   但在某些环境里，提示文字不一定会立刻显示出来
*/

print("---------") // 手动分割线

print("请输入你的城市：", terminator: "")
fflush(stdout)
if let city = readLine() {
    print("你输入的城市是：", city)
}
/*
*   例如如果输入：
*   Beijing
*
*   那么通常会看到：
*   请输入你的城市：Beijing
*   你输入的城市是： Beijing
*/

print("---------") // 手动分割线

/*
*   命令行输入默认先按字符串处理
*   如果想当整数使用，需要手动转换
*/
print("请输入一个整数：")
if let text = readLine() {
    print("你输入的原始文本是：", text)

    let number = Int(text)
    print("Int(text) 的结果是：", number as Any)

    if let value = number {
        print("转换成功，值是：", value)
        print("它的两倍是：", value * 2)
    } else {
        print("转换失败：这不是一个有效的整数")
    }
}
/*
*   例如如果输入：
*   21
*
*   那么通常会看到：
*   你输入的原始文本是： 21
*   Int(text) 的结果是： Optional(21)
*   转换成功，值是： 21
*   它的两倍是： 42
*
*   如果输入：
*   Hello
*
*   那么通常会看到：
*   你输入的原始文本是： Hello
*   Int(text) 的结果是： nil
*   转换失败：这不是一个有效的整数
*/
