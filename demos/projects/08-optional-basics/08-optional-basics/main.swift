//
//  main.swift
//  08-optional-basics
//
//  Created by 时雨 on 2026/3/17.
//

import Foundation

/*
*   Optional 最基础的含义：
*   一个值可能存在，也可能不存在
*/

// var notReady: String
// print(notReady)
// 报错：Variable 'notReady' used before being initialized

/*
*   a 是 Optional 字符串
*   b 是普通字符串，只是当前值刚好是空字符串
*/
var a: String?
var b: String = ""
print("a的值为：", a as Any)
print("b的值为：", b)
/*
*   预期输出：
*   a的值为： nil
*   b的值为：
*/

print("---------") // 手动分割线

/*
*   Optional 变量后面也可以真正保存一个值
*/
a = "Swift"
print("给 a 赋值后，a 的值为：", a as Any)

/*
*   也可以再次改回 nil
*/
a = nil
print("把 a 改回 nil 后，a 的值为：", a as Any)
/*
*   预期输出：
*   给 a 赋值后，a 的值为： Optional("Swift")
*   把 a 改回 nil 后，a 的值为： nil
*/

print("---------") // 手动分割线

/*
*   最基础的安全取值：if let
*   如果 Optional 里面真的有值，就先取出来再使用
*/
let text1: String? = "Hello"
let text2: String? = nil

print("text1 的原始结果是：", text1 as Any)
print("text2 的原始结果是：", text2 as Any)

if let value = text1 {
    print("text1 里真正的字符串值是：", value)
    print("value 的类型是：", type(of: value))
}

if let value = text2 {
    print("text2 里真正的字符串值是：", value)
}
/*
*   预期输出：
*   text1 的原始结果是： Optional("Hello")
*   text2 的原始结果是： nil
*   text1 里真正的字符串值是： Hello
*   value 的类型是： String
*
*   这里不会出现 text2 里真正的字符串值的输出，
*   因为 text2 当前是 nil
*/

print("---------") // 手动分割线

/*
*   字符串转整数时，也会得到 Optional
*   因为编译器不能保证每个字符串都能变成 Int
*/
let numberText1 = "123"
let numberText2 = "Hello"
let number1 = Int(numberText1)
let number2 = Int(numberText2)

print("number1 的原始结果是：", number1 as Any)
print("number2 的原始结果是：", number2 as Any)

if let value = number1 {
    print("number1 转换成功，值是：", value)
}

if let value = number2 {
    print("number2 转换成功，值是：", value)
}
/*
*   预期输出：
*   number1 的原始结果是： Optional(123)
*   number2 的原始结果是： nil
*   number1 转换成功，值是： 123
*
*   这里不会出现 number2 转换成功的输出，
*   因为 "Hello" 不能转换成 Int
*/
