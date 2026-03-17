//
//  main.swift
//  07-explicit-types-and-conversion
//
//  Created by 时雨 on 2026/3/17.
//

import Foundation

/*
*   显式类型声明
*   当编译器不能自动推断类型时，可以手动把类型写出来
*   最基础的写法：
*   var a: Int
*/

var a: Int
a = 1
print("a的值是：", a)
print("a的类型是：", type(of: a))
/*
*   预期输出：
*   a的值是： 1
*   a的类型是： Int
*/

print("---------")//手动分割线

/*
*   声明时也可以同时赋值
*   写法：
*   var a: Int = 1
*/
var b: Int = 2
let name: String = "Swift"
print("b的值是：", b)
print("name的值是：", name)
print("b的类型是：", type(of: b))
print("name的类型是：", type(of: name))
/*
*   预期输出：
*   b的值是： 2
*   name的值是： Swift
*   b的类型是： Int
*   name的类型是： String
*/

var exam: Double = 10
print("exam的值是：", exam)
print("exam的类型是：", type(of: exam))
/*
*   预期输出：
*   exam的值是： 10.0
*   exam的类型是： Double
*/

print("---------")//手动分割线

/*
*   整数除法
*   2 和 5 都是 Int，因此 2 / 5 得到的是整数结果
*/
let x = 2
let y = 5
print("x / y 的值是：", x / y)
print("x / y 的类型是：", type(of: x / y))
/*
*   预期输出：
*   x / y 的值是： 0
*   x / y 的类型是： Int
*/

print("---------")//手动分割线

/*
*   最基础的类型转换
*   如果想得到带小数的结果，需要把整数转换成 Double
*/
let doubleResult = Double(x) / Double(y)
print("Double(x) / Double(y) 的值是：", doubleResult)
print("Double(x) / Double(y) 的类型是：", type(of: doubleResult))
/*
*   预期输出：
*   Double(x) / Double(y) 的值是： 0.4
*   Double(x) / Double(y) 的类型是： Double
*/

/*
*   Double 和 Int 之间也可以做最基础的类型转换
*/
var test: Double = 114.514
var test2: Int = Int(test)
var test3: Double = Double(test2)
print("test的值是：", test)
print("test2的值是：", test2)
print("test3的值是：", test3)
/*
*   预期输出：
*   test的值是： 114.514
*   test2的值是： 114
*   test3的值是： 114.0
*/

print("---------")//手动分割线

/*
*   继续观察：字面量里只要出现小数，推断出来的结果也会不同
*/
var c = 2 / 5
var d = Double(2) / Double(5)
var e = 2 / 5.0
var f = 2.0 / 5

print("c的值是：", c)
print("c的类型是：", type(of: c))
print("d的值是：", d)
print("d的类型是：", type(of: d))
print("e的值是：", e)
print("e的类型是：", type(of: e))
print("f的值是：", f)
print("f的类型是：", type(of: f))
/*
*   预期输出：
*   c的值是： 0
*   c的类型是： Int
*   d的值是： 0.4
*   d的类型是： Double
*   e的值是： 0.4
*   e的类型是： Double
*   f的值是： 0.4
*   f的类型是： Double
*/

print("---------")//手动分割线

/*
*   变量类型不一致时，Swift 不会替你自动转换
*/
var number1 = 2.0
var number2 = 5
//var result = number1/number2 报错：Binary operator '/' cannot be applied to operands of type 'Double' and 'Int'
print("number1的类型是：", type(of: number1))
print("number2的类型是：", type(of: number2))
/*
*   预期输出：
*   number1的类型是： Double
*   number2的类型是： Int
*/
