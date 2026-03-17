//
//  main.swift
//  06-variables-and-constants
//
//  Created by 时雨 on 2026/3/16.
//

import Foundation

/*
*   声明变量与常量
*   关键字(var/let) 名字（a） = 值（123）
*   例如：
*/
var number = 123
let word = "Hello"

//如何调用变量 or 常量：
print("变量的调用：")
print("number的值是：",number)
print("word的值是：",word)
/*
*   预期得到的输出：
*   number的值是：123
*   word的值是：Hello
*/

print("---------")//手动分割线

//整型变量之间的运算：
print("变量之间的运算：")
var a = 2
var b = 5
var c = a + b
var d = a - b
var e = a * b
var f = a / b
var g = a % b
print("c的值是：",c)
print("d的值是：",d)
print("e的值是：",e)
print("f的值是：",f)
print("g的值是：",g)
/*
*   预期输出：
*   c的值是： 7  （2+5=7）
*   d的值是： -3  （2-5=-3）
*   e的值是： 10  (2*5=10)
*   2/5= 0 余 2，因此：
*   f的值是： 0
*   g的值是： 2
*/
var h = "Hello"
var i = " "
var j = "World"
var k = h+i+j
print("k的值是：",k)
/*
*   预期输出：
*   k的值是： Hello World （显然，字符串的加法是拼接）
*/

print("---------")//手动分割线

//查看变量或常量的类型：
print("查看变量类型：")
print("number的类型是：", type(of: number))
print("word的类型是：", type(of: word))
print("a的类型是：", type(of: a))
print("k的类型是：", type(of: k))
/*
*   预期输出：
*   number的类型是： Int
*   word的类型是： String
*   a的类型是： Int
*   k的类型是： String
*/
