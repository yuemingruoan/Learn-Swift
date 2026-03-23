//
//  main.swift
//  26-higher-order-collection-operations
//
//  Created by Codex on 2026/3/23.
//

func printDivider(title: String) {
    print("")
    print("======== \(title) ========")
}

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

printDivider(title: "完整功能：学习日报生成器")
print("今天一共有 \(tasks.count) 项任务。")
for task in tasks {
    print("- \(task.title)")
}

printDivider(title: "先用循环理解 filter 的行为")
var unfinishedTasksByLoop: [StudyTask] = []
for task in tasks {
    if task.isFinished == false {
        unfinishedTasksByLoop.append(task)
    }
}
for task in unfinishedTasksByLoop {
    print("循环筛出的待完成任务：\(task.title)")
}

printDivider(title: "再看 filter 的对应写法")
let unfinishedTasks = tasks.filter { task in
    task.isFinished == false
}
for task in unfinishedTasks {
    print("filter 筛出的待完成任务：\(task.title)")
}

printDivider(title: "先用循环理解 map 的行为")
var titlesByLoop: [String] = []
for task in tasks {
    titlesByLoop.append(task.title)
}
print("循环得到的标题列表：\(titlesByLoop)")

var summaryLinesByLoop: [String] = []
for task in tasks {
    let status = task.isFinished ? "已完成" : "未完成"
    summaryLinesByLoop.append("\(task.title) - \(task.estimatedHours) 小时 - \(status)")
}
for line in summaryLinesByLoop {
    print(line)
}

printDivider(title: "再看 map 的对应写法")
let titles = tasks.map { task in
    task.title
}
print("map 得到的标题列表：\(titles)")

let summaryLines = tasks.map { task in
    let status = task.isFinished ? "已完成" : "未完成"
    return "\(task.title) - \(task.estimatedHours) 小时 - \(status)"
}
for line in summaryLines {
    print(line)
}

printDivider(title: "先用循环理解 reduce 的行为")
var totalHoursByLoop = 0
var finishedCountByLoop = 0
for task in tasks {
    totalHoursByLoop += task.estimatedHours
    if task.isFinished {
        finishedCountByLoop += 1
    }
}
print("循环算出的总学习时长：\(totalHoursByLoop) 小时")
print("循环算出的已完成任务数：\(finishedCountByLoop)")

printDivider(title: "再看 reduce 的对应写法")
let totalHours = tasks.reduce(0) { partialResult, task in
    partialResult + task.estimatedHours
}
let finishedCount = tasks.reduce(0) { partialResult, task in
    partialResult + (task.isFinished ? 1 : 0)
}
print("总学习时长：\(totalHours) 小时")
print("已完成任务数：\(finishedCount)")

printDivider(title: "先用循环理解 compactMap 的行为")
let rawHourTexts = ["2", "x", "5", ""]
var validHoursByLoop: [Int] = []
for text in rawHourTexts {
    if let hour = Int(text) {
        validHoursByLoop.append(hour)
    }
}
print("循环得到的有效时长列表：\(validHoursByLoop)")

printDivider(title: "再看 compactMap 的对应写法")
let validHours = rawHourTexts.compactMap { text in
    Int(text)
}
print("有效时长列表：\(validHours)")
print("说明：")
print("- 这里每一项都会先尝试转成 Int。")
print("- 转换失败时会得到 nil。")
print("- compactMap 会把这些 nil 自动丢掉。")

printDivider(title: "链式调用可以直接表达处理意图")
let unfinishedTitles = tasks
    .filter { task in
        task.isFinished == false
    }
    .map { task in
        task.title
    }
print("未完成任务标题：\(unfinishedTitles)")

printDivider(title: "这一章最想演示的差别")
print("说明：")
print("- 先用循环把行为看懂，再去看高阶操作，会更容易理解这些 API 到底替你做了什么。")
print("- compactMap：先解析，再丢掉无效数据。")
print("- filter：留下需要继续处理的任务。")
print("- map：把任务对象变成标题或摘要。")
print("- reduce：把整组任务汇总成最终统计结果。")
