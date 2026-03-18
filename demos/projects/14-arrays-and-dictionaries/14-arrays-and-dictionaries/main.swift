//
//  main.swift
//  14-arrays-and-dictionaries
//
//  Created by 时雨 on 2026/3/19.
//

import Foundation

// 统一处理“不换行的输入提示”，避免每次都重复写 print + fflush。
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

// 第 14 章开始不再只保存统计结果，而是直接保存完整成绩列表。
struct StudentRecord {
    var name: String
    var scores: [Int]

    // 后面的统计都从 scores 重新计算，避免同时维护多份状态。
    func totalScore() -> Int {
        var total = 0

        for score in scores {
            total += score
        }

        return total
    }

    func passCount() -> Int {
        var count = 0

        for score in scores {
            if isPassed(score: score) {
                count += 1
            }
        }

        return count
    }

    func average() -> Double {
        return roundToOneDecimal(value: Double(totalScore()) / Double(scores.count))
    }

    // 及格率仍然沿用前面章节的规则，只是数据来源改成了数组。
    func passRate() -> Double {
        return roundToOneDecimal(value: Double(passCount()) / Double(scores.count) * 100)
    }

    func highestScore() -> Int {
        var highest = scores[0]

        for score in scores {
            if score > highest {
                highest = score
            }
        }

        return highest
    }

    func lowestScore() -> Int {
        var lowest = scores[0]

        for score in scores {
            if score < lowest {
                lowest = score
            }
        }

        return lowest
    }
}

let invalidPrompt: String = "输入无效，请重新输入"
var record: StudentRecord
var frequency: Int

// 先创建学生记录的主体，成绩数组一开始为空。
while true {
    printPrompt(message: "请输入学生姓名：")

    if let nameTemp = readLine() {
        record = StudentRecord(name: nameTemp, scores: [])
        break
    } else {
        print(invalidPrompt)
    }
}

// 继续确定后面要录入多少次成绩。
while true {
    printPrompt(message: "请输入考试次数：")

    if let frequencyStringTemp = readLine() {
        if let frequencyIntTemp = Int(frequencyStringTemp) {
            if frequencyIntTemp > 0 {
                frequency = frequencyIntTemp
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

// 每次录入成功后，直接把成绩追加进数组。
for freNow in 1...frequency {
    while true {
        printPrompt(message: "请输入第 \(freNow) 次考试成绩：")

        if let scoreStringTemp = readLine() {
            if let scoreIntTemp = Int(scoreStringTemp) {
                if isValidScore(score: scoreIntTemp) {
                    record.scores.append(scoreIntTemp)
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

// 输出阶段只读取 record 中的数据，主流程会更接近实际需求。
print("学生姓名：", record.name)
print("考试次数：", record.scores.count)
print("成绩列表：", record.scores)
print("总分：", record.totalScore())
print("平均分：", record.average())
print("最高分：", record.highestScore())
print("最低分：", record.lowestScore())
print("及格率：\(record.passRate())%")
