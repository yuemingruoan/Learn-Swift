//
//  main.swift
//  10-expressions-conditions-and-loops
//
//  Created by 时雨 on 2026/3/17.
//

import Foundation

/*
*   表达式会产生结果
*   最常见的一类是算术表达式
*/
let sum = 2 + 3
let diff = 5 - 2
let product = 4 * 3
let quotient = 8 / 2
let remainder = 9 % 2

print("sum的值是：", sum)
print("diff的值是：", diff)
print("product的值是：", product)
print("quotient的值是：", quotient)
print("remainder的值是：", remainder)
/*
*   预期输出：
*   sum的值是： 5
*   diff的值是： 3
*   product的值是： 12
*   quotient的值是： 4
*   remainder的值是： 1
*/

print("---------") // 手动分割线

/*
*   比较表达式会得到 Bool
*/
var a = 10 < 20
print("a的值是：", a)
print("a的类型是：", type(of: a))

let x = 10
let y = 20
print("x > y 的结果是：", x > y)
print("x < y 的结果是：", x < y)
print("x == y 的结果是：", x == y)
print("x != y 的结果是：", x != y)
/*
*   预期输出：
*   a的值是： true
*   a的类型是： Bool
*   x > y 的结果是： false
*   x < y 的结果是： true
*   x == y 的结果是： false
*   x != y 的结果是： true
*/

print("---------") // 手动分割线

/*
*   逻辑表达式也会得到 Bool
*/
let age = 20
let hasTicket = true
print("age >= 18 && hasTicket 的结果是：", age >= 18 && hasTicket)
print("age < 18 || hasTicket 的结果是：", age < 18 || hasTicket)
print("!hasTicket 的结果是：", !hasTicket)
/*
*   预期输出：
*   age >= 18 && hasTicket 的结果是： true
*   age < 18 || hasTicket 的结果是： true
*   !hasTicket 的结果是： false
*/

print("---------") // 手动分割线

/*
*   最基础的条件判断：if
*   条件必须真正得到 Bool
*/
let score1 = 75
if score1 >= 60 {
    print("score1及格")
}

let score2 = 45
if score2 >= 60 {
    print("score2及格")
} else {
    print("score2不及格")
}

let score3 = 85
if score3 >= 90 {
    print("score3优秀")
} else if score3 >= 60 {
    print("score3及格")
} else {
    print("score3不及格")
}

// if score1 {
//     print("这段代码在 Swift 里不成立")
// }
/*
*   预期输出：
*   score1及格
*   score2不及格
*   score3及格
*/

print("---------") // 手动分割线

/*
*   for-in 适合按范围重复执行
*/
print("使用 1...5 输出：")
for i in 1...5 {
    print(i)
}

print("使用 1..<5 输出：")
for i in 1..<5 {
    print(i)
}

print("1到10中的偶数是：")
for i in 1...10 {
    if i % 2 == 0 {
        print(i)
    }
}
/*
*   预期输出：
*   使用 1...5 输出：
*   1
*   2
*   3
*   4
*   5
*
*   使用 1..<5 输出：
*   1
*   2
*   3
*   4
*
*   1到10中的偶数是：
*   2
*   4
*   6
*   8
*   10
*/

print("---------") // 手动分割线

/*
*   while 会在条件成立时持续重复
*/
var count = 1
while count <= 3 {
    print("count的值是：", count)
    count = count + 1
}
/*
*   预期输出：
*   count的值是： 1
*   count的值是： 2
*   count的值是： 3
*/

print("---------") // 手动分割线

/*
*   break 可以在中途直接跳出循环
*/
print("使用 break 提前结束 for-in：")
for i in 1...10 {
    if i == 5 {
        break
    }
    print(i)
}

print("使用 break 提前结束 while：")
var current = 1
while true {
    print("current的值是：", current)

    if current == 3 {
        break
    }

    current = current + 1
}
/*
*   预期输出：
*   使用 break 提前结束 for-in：
*   1
*   2
*   3
*   4
*
*   使用 break 提前结束 while：
*   current的值是： 1
*   current的值是： 2
*   current的值是： 3
*/

print("---------") // 手动分割线

/*
*   continue 不会结束整个循环
*   它只会跳过当前这一轮，直接进入下一轮
*/
print("使用 continue 跳过 for-in 中的某一轮：")
for i in 1...5 {
    if i == 3 {
        continue
    }
    print(i)
}

print("使用 continue 跳过 while 中的某一轮：")
var loopCount = 0
while loopCount < 5 {
    loopCount = loopCount + 1

    if loopCount == 3 {
        continue
    }

    print("loopCount的值是：", loopCount)
}
/*
*   预期输出：
*   使用 continue 跳过 for-in 中的某一轮：
*   1
*   2
*   4
*   5
*
*   使用 continue 跳过 while 中的某一轮：
*   loopCount的值是： 1
*   loopCount的值是： 2
*   loopCount的值是： 4
*   loopCount的值是： 5
*/

print("---------") // 手动分割线

/*
*   综合示例：
*   重复提示用户输入，直到输入一个合法整数
*/
var isValid = false

while !isValid {
    print("请输入一个整数：", terminator: "")
    fflush(stdout)

    if let text = readLine() {
        if let number = Int(text) {
            print("输入成功，值是：", number)

            if number > 0 {
                print("这是一个正数")
            } else if number < 0 {
                print("这是一个负数")
            } else {
                print("这是 0")
            }

            isValid = true
        } else {
            print("输入无效，请重新输入")
        }
    }
}
/*
*   例如如果依次输入：
*   Hello
*   -3
*
*   那么通常会看到：
*   请输入一个整数：Hello
*   输入无效，请重新输入
*   请输入一个整数：-3
*   输入成功，值是： -3
*   这是一个负数
*/
