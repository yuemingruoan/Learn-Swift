//
//  main.swift
//  13-structs-and-custom-types
//
//  Created by 时雨 on 2026/3/18.
//

import Foundation

func printPrompt(message: String) {
    print(message, terminator: "")
    fflush(stdout)
}

func isValidScore(score: Int) -> Bool {
    return score >= 0 && score <= 100
}

func isPassed(score: Int) -> Bool {
    return score >= 60
}

func roundToOneDecimal(value: Double) -> Double {
    var firstDecimal = Int(value * 10)
    let secondDecimal = Int(value * 100) % 10

    if secondDecimal >= 5 {
        firstDecimal += 1
    }

    return Double(firstDecimal) / 10
}

struct StudentRecord {
    var name: String
    var frequency: Int
    var scoreSum: Int
    var passCount: Int

    func average() -> Double {
        return roundToOneDecimal(value: Double(scoreSum) / Double(frequency))
    }

    func passRate() -> Double {
        return roundToOneDecimal(value: Double(passCount) / Double(frequency) * 100)
    }
}

let invalidPrompt: String = "输入无效，请重新输入"
var record: StudentRecord

// 获取学生姓名
while true {
    printPrompt(message: "请输入学生姓名：")

    if let nameTemp = readLine() {
        record = StudentRecord(name: nameTemp, frequency: 0, scoreSum: 0, passCount: 0)
        break
    } else {
        print(invalidPrompt)
    }
}

// 获取考试次数
while true {
    printPrompt(message: "请输入考试次数：")

    if let frequencyStringTemp = readLine() {
        if let frequencyIntTemp = Int(frequencyStringTemp) {
            if frequencyIntTemp > 0 {
                record.frequency = frequencyIntTemp
                break
            } else {
                print(invalidPrompt)
            }
        } else {
            print(invalidPrompt)
        }
    } else {
        print(invalidPrompt)
    }
}

// 获取考试成绩
for freNow in 1...record.frequency {
    while true {
        printPrompt(message: "请输入第 \(freNow) 次考试成绩：")

        if let scoreStringTemp = readLine() {
            if let scoreIntTemp = Int(scoreStringTemp) {
                if isValidScore(score: scoreIntTemp) {
                    record.scoreSum += scoreIntTemp

                    if isPassed(score: scoreIntTemp) {
                        record.passCount += 1
                    }

                    break
                } else {
                    print(invalidPrompt)
                }
            } else {
                print(invalidPrompt)
            }
        } else {
            print(invalidPrompt)
        }
    }
}

print("学生姓名：", record.name)
print("考试次数：", record.frequency)
print("总分：", record.scoreSum)
print("平均分：", record.average())
print("及格率：\(record.passRate())%")
