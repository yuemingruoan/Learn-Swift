//
//  main.swift
//  26-higher-order-collection-operations-starter
//
//  Created by Codex on 2026/3/23.
//

func printDivider(title: String) {
    print("")
    print("======== \(title) ========")
}

// 这个 starter project 的问题不是“功能不能跑”，而是：
// 1. 大量 for-in + append 在重复做筛选、提取、汇总。
// 2. 同一种数组处理意图没有被直接表达出来。
// 3. 有些循环其实只是 map/filter/reduce/compactMap 的展开版。
//
// 练习目标：
// - 先识别每段循环在做什么。
// - 再把适合的地方改成高阶操作。
// - 不要求把所有循环都硬改掉，但要让集合处理意图更清楚。

struct StudyTask {
    let title: String
    let estimatedHours: Int
    let isFinished: Bool
}

let tasks = [
    StudyTask(title: "补写高阶操作章节", estimatedHours: 2, isFinished: true),
    StudyTask(title: "整理 map 示例", estimatedHours: 1, isFinished: false),
    StudyTask(title: "准备 compactMap 例子", estimatedHours: 2, isFinished: false),
]

let rawHourTexts = ["2", "x", "5", ""]

printDivider(title: "当前项目能生成日报，但处理流程很原始")
for task in tasks {
    print("- \(task.title)")
}

printDivider(title: "循环筛出未完成任务")
var unfinishedTasks: [StudyTask] = []
for task in tasks {
    if task.isFinished == false {
        unfinishedTasks.append(task)
    }
}
for task in unfinishedTasks {
    print("待完成：\(task.title)")
}

printDivider(title: "循环提取标题")
var titles: [String] = []
for task in tasks {
    titles.append(task.title)
}
print("标题列表：\(titles)")

printDivider(title: "循环生成摘要文本")
var summaryLines: [String] = []
for task in tasks {
    let status = task.isFinished ? "已完成" : "未完成"
    summaryLines.append("\(task.title) - \(task.estimatedHours) 小时 - \(status)")
}
for line in summaryLines {
    print(line)
}

printDivider(title: "循环汇总总时长与完成数量")
var totalHours = 0
var finishedCount = 0
for task in tasks {
    totalHours += task.estimatedHours
    if task.isFinished {
        finishedCount += 1
    }
}
print("总学习时长：\(totalHours) 小时")
print("已完成任务数：\(finishedCount)")

printDivider(title: "循环清洗有效时长")
var validHours: [Int] = []
for text in rawHourTexts {
    if let hour = Int(text) {
        validHours.append(hour)
    }
}
print("有效时长列表：\(validHours)")

printDivider(title: "TODO")
print("请找出这些循环分别对应哪些高阶操作，再在合适的地方改写。")
