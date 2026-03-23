//
//  main.swift
//  25-closures-functions-as-values
//
//  Created by Codex on 2026/3/23.
//

import Foundation

func printDivider(title: String) {
    print("")
    print("======== \(title) ========")
}

struct StudyTask {
    let title: String
    let estimatedHours: Int
    var isFinished: Bool
}

struct StudyTaskCenter {
    let tasks: [StudyTask]

    func filtered(by rule: (StudyTask) -> Bool) -> [StudyTask] {
        var result: [StudyTask] = []

        for task in tasks {
            if rule(task) {
                result.append(task)
            }
        }

        return result
    }

    func sorted(by areInIncreasingOrder: (StudyTask, StudyTask) -> Bool) -> [StudyTask] {
        var result = tasks

        for i in 0..<result.count {
            for j in (i + 1)..<result.count {
                if areInIncreasingOrder(result[j], result[i]) {
                    let temp = result[i]
                    result[i] = result[j]
                    result[j] = temp
                }
            }
        }

        return result
    }

    func summaries(using formatter: (StudyTask) -> String) -> [String] {
        var result: [String] = []

        for task in tasks {
            result.append(formatter(task))
        }

        return result
    }
}

func makeStatusFormatter(prefix: String) -> (StudyTask) -> String {
    return { task in
        let status = task.isFinished ? "已完成" : "未完成"
        return "\(prefix)：\(task.title) - \(task.estimatedHours) 小时 - \(status)"
    }
}

let tasks = [
    StudyTask(title: "补写闭包章节", estimatedHours: 2, isFinished: false),
    StudyTask(title: "整理筛选示例", estimatedHours: 1, isFinished: true),
    StudyTask(title: "准备排序案例", estimatedHours: 3, isFinished: false),
]

let center = StudyTaskCenter(tasks: tasks)

printDivider(title: "闭包可以先存进变量里")
let isLongTask: (StudyTask) -> Bool = { task in
    task.estimatedHours >= 2
}

for task in tasks {
    print("\(task.title) 是否为长任务：\(isLongTask(task))")
}

printDivider(title: "闭包作为参数时，外层流程保持不变")
let unfinishedTasks = center.filtered { task in
    task.isFinished == false
}
for task in unfinishedTasks {
    print("未完成任务：\(task.title)")
}

printDivider(title: "同一个函数可以接收不同闭包")
let tasksByHours = center.sorted { left, right in
    left.estimatedHours < right.estimatedHours
}
print("按时长排序：")
for task in tasksByHours {
    print("- \(task.title)")
}

let tasksByTitle = center.sorted { left, right in
    left.title < right.title
}
print("按标题排序：")
for task in tasksByTitle {
    print("- \(task.title)")
}

printDivider(title: "完整功能：学习任务调度中心")
let dailyFormatter = makeStatusFormatter(prefix: "今日安排")
let reviewFormatter = makeStatusFormatter(prefix: "复盘视角")

let dailySummaries = center.summaries(using: dailyFormatter)
for line in dailySummaries {
    print(line)
}

print("----")

let reviewSummaries = center.summaries(using: reviewFormatter)
for line in reviewSummaries {
    print(line)
}

printDivider(title: "闭包捕获会记住外部变量")
func makeCounter(label: String) -> () -> String {
    var count = 0

    return {
        count += 1
        return "\(label) 已调用 \(count) 次"
    }
}

let callCounter = makeCounter(label: "任务筛选器")
print(callCounter())
print(callCounter())
print(callCounter())

printDivider(title: "这一章最想演示的差别")
print("说明：")
print("- StudyTaskCenter 负责固定流程。")
print("- filtered / sorted / summaries 的具体规则交给闭包。")
print("- makeStatusFormatter 和 makeCounter 展示了闭包可以被返回，并记住外部状态。")
