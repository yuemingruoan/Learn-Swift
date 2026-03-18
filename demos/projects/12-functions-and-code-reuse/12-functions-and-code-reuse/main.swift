//
//  main.swift
//  12-functions-and-code-reuse
//
//  Created by 时雨 on 2026/3/18.
//

import Foundation

/*
*   无参数、无返回值的函数
*/
func sayHello() {
    print("Hello")
}

/*
*   带参数、无返回值的函数
*/
func greet(name: String) {
    print("你好，\(name)")
}

/*
*   带参数、有返回值的函数
*/
func add(number1: Int, number2: Int) -> Int {
    let result = number1 + number2
    return result
}

/*
*   返回 Bool 的函数
*/
func isPassed(score: Int) -> Bool {
    return score >= 60
}

/*
*   从第十章思考题中提炼出来的函数
*/
func printPrompt(message: String) {
    print(message, terminator: "")
    fflush(stdout)
}

func isValidScore(score: Int) -> Bool {
    return score >= 0 && score <= 100
}

func roundToOneDecimal(value: Double) -> Double {
    var firstDecimal = Int(value * 10)
    let secondDecimal = Int(value * 100) % 10

    if secondDecimal >= 5 {
        firstDecimal += 1
    }

    return Double(firstDecimal) / 10
}

/*
*   定义函数，不等于执行函数
*/
sayHello()
/*
*   预期输出：
*   Hello
*/

print("---------") // 手动分割线

/*
*   调用带参数的函数
*/
greet(name: "Alice")
greet(name: "Bob")
/*
*   预期输出：
*   你好，Alice
*   你好，Bob
*/

print("---------") // 手动分割线

/*
*   调用带返回值的函数
*/
let addResult = add(number1: 1, number2: 2)
print("1 + 2 的结果是：", addResult)
print("3 + 4 的结果是：", add(number1: 3, number2: 4))
/*
*   预期输出：
*   1 + 2 的结果是： 3
*   3 + 4 的结果是： 7
*/

print("---------") // 手动分割线

/*
*   返回 Bool 的函数很适合拿来做条件判断
*/
let score1 = 75
let score2 = 45

print("score1 是否及格：", isPassed(score: score1))
print("score2 是否及格：", isPassed(score: score2))

if isPassed(score: score1) {
    print("score1及格")
}

if isPassed(score: score2) {
    print("score2及格")
} else {
    print("score2不及格")
}
/*
*   预期输出：
*   score1 是否及格： true
*   score2 是否及格： false
*   score1及格
*   score2不及格
*/

print("---------") // 手动分割线

/*
*   用函数统一输出输入提示
*/
printPrompt(message: "请输入你的名字：")
if let name = readLine() {
    print("你好，\(name)")
}
/*
*   例如如果输入：
*   Swift
*
*   那么通常会看到：
*   请输入你的名字：Swift
*   你好，Swift
*/

print("---------") // 手动分割线

/*
*   用函数统一判断成绩是否合法
*/
let score3 = 101
let score4 = 88
print("101 是否是合法成绩：", isValidScore(score: score3))
print("88 是否是合法成绩：", isValidScore(score: score4))
/*
*   预期输出：
*   101 是否是合法成绩： false
*   88 是否是合法成绩： true
*/

print("---------") // 手动分割线

/*
*   用函数统一处理保留一位小数
*/
let average = roundToOneDecimal(value: 402.0 / 5.0)
let passRate = roundToOneDecimal(value: 4.0 / 5.0 * 100)

print("平均分是：", average)
print("及格率是：\(passRate)%")
/*
*   预期输出：
*   平均分是： 80.4
*   及格率是：80.0%
*/
