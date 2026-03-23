//
//  main.swift
//  25-closures-functions-as-values-starter
//
//  Created by Codex on 2026/3/23.
//

func printDivider(title: String) {
    print("")
    print("======== \(title) ========")
}

// 这个 starter project 当前也能跑，但它的问题是：
// 1. 各种筛选函数只是条件不同，却重复写了很多份。
// 2. 排序函数只是比较规则不同，也重复写了很多份。
// 3. 摘要输出函数只是前缀不同，也重复写了很多份。
// 4. 当前项目把“规则”都写死在函数里，主流程越来越难扩展。
//
// 练习目标：
// - 用本章的闭包知识，把“固定流程”和“可变规则”拆开。
// - 不改变当前业务输出的核心语义。
//
// TODO 建议优先查看：
// - filterUnfinishedTasks(_:)
// - filterLongTasks(_:)
// - sortTasksByHours(_:)
// - sortTasksByTitle(_:)
// - makeDailySummaries(_:)
// - makeReviewSummaries(_:)

struct StudyTask {
    let title: String
    let estimatedHours: Int
    let isFinished: Bool
}

func filterUnfinishedTasks(_ tasks: [StudyTask]) -> [StudyTask] {
    var result: [StudyTask] = []

    for task in tasks {
        if task.isFinished == false {
            result.append(task)
        }
    }

    return result
}

func filterLongTasks(_ tasks: [StudyTask]) -> [StudyTask] {
    var result: [StudyTask] = []

    for task in tasks {
        if task.estimatedHours >= 2 {
            result.append(task)
        }
    }

    return result
}

func sortTasksByHours(_ tasks: [StudyTask]) -> [StudyTask] {
    var result = tasks

    for i in 0..<result.count {
        for j in (i + 1)..<result.count {
            if result[j].estimatedHours < result[i].estimatedHours {
                let temp = result[i]
                result[i] = result[j]
                result[j] = temp
            }
        }
    }

    return result
}

func sortTasksByTitle(_ tasks: [StudyTask]) -> [StudyTask] {
    var result = tasks

    for i in 0..<result.count {
        for j in (i + 1)..<result.count {
            if result[j].title < result[i].title {
                let temp = result[i]
                result[i] = result[j]
                result[j] = temp
            }
        }
    }

    return result
}

func makeDailySummaries(_ tasks: [StudyTask]) -> [String] {
    var result: [String] = []

    for task in tasks {
        let status = task.isFinished ? "已完成" : "未完成"
        result.append("今日安排：\(task.title) - \(task.estimatedHours) 小时 - \(status)")
    }

    return result
}

func makeReviewSummaries(_ tasks: [StudyTask]) -> [String] {
    var result: [String] = []

    for task in tasks {
        let status = task.isFinished ? "已完成" : "未完成"
        result.append("复盘视角：\(task.title) - \(task.estimatedHours) 小时 - \(status)")
    }

    return result
}

let tasks = [
    StudyTask(title: "补写闭包章节", estimatedHours: 2, isFinished: false),
    StudyTask(title: "整理筛选示例", estimatedHours: 1, isFinished: true),
    StudyTask(title: "准备排序案例", estimatedHours: 3, isFinished: false),
]

printDivider(title: "重复的筛选函数")
for task in filterUnfinishedTasks(tasks) {
    print("未完成：\(task.title)")
}

for task in filterLongTasks(tasks) {
    print("长任务：\(task.title)")
}

printDivider(title: "重复的排序函数")
for task in sortTasksByHours(tasks) {
    print("按时长排序：\(task.title)")
}

for task in sortTasksByTitle(tasks) {
    print("按标题排序：\(task.title)")
}

printDivider(title: "重复的格式化函数")
for line in makeDailySummaries(tasks) {
    print(line)
}

print("----")

for line in makeReviewSummaries(tasks) {
    print(line)
}

printDivider(title: "TODO")
print("请把这些“流程一样、规则不同”的函数收拢成接收闭包的统一版本。")
