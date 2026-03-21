//
//  main.swift
//  22-extensions-adding-capabilities-starter
//
//  Created by Codex on 2026/3/21.
//

import Foundation

func printDivider(title: String) {
    print("")
    print("======== \(title) ========")
}

protocol DailyBriefPrintable {
    var name: String { get }
    func dailyBrief() -> String
}

// 这个版本里的功能已经完整，但很多辅助逻辑都散落在顶层函数中。
// 当前问题：
// 1. summaryLine / isLongTask / studyHoursText 都不在类型附近。
// 2. StudyTask 还没有按主题拆出协议遵守。
//
// 练习目标：
// - 把顶部辅助逻辑逐步移入 extension。
// - 给 Int 补一个 studyHoursText()。
// - 给 StudyTask 补 summaryLine() 和 isLongTask。
// - 最后用 extension 让 StudyTask 遵守 DailyBriefPrintable。

struct StudyTask {
    let title: String
    let estimatedHours: Int
    var isFinished: Bool
}

func studyHoursText(_ value: Int) -> String {
    return "\(value) 小时"
}

func isLongTask(_ task: StudyTask) -> Bool {
    return task.estimatedHours >= 2
}

func summaryLine(_ task: StudyTask) -> String {
    let status = task.isFinished ? "已完成" : "未完成"
    return "\(task.title) - \(studyHoursText(task.estimatedHours)) - \(status)"
}

func dailyBrief(_ task: StudyTask) -> String {
    if isLongTask(task) {
        return "今天优先完成这项长任务。"
    } else {
        return "今天可以作为短任务快速完成。"
    }
}

let tasks = [
    StudyTask(title: "阅读 extension 章节", estimatedHours: 1, isFinished: true),
    StudyTask(title: "整理协议与扩展笔记", estimatedHours: 2, isFinished: false),
    StudyTask(title: "完成 demo 复盘", estimatedHours: 3, isFinished: false)
]

printDivider(title: "当前版本先把功能跑通")
for task in tasks {
    print(summaryLine(task))
}

printDivider(title: "顶层函数还能工作，但组织还不够清楚")
for task in tasks {
    print("\(task.title)：\(dailyBrief(task))")
}

printDivider(title: "下一步请你开始整理扩展")
print("- 先把 studyHoursText(_:) 改成 Int 的扩展方法。")
print("- 再把 isLongTask / summaryLine 收进 StudyTask 扩展。")
print("- 最后用扩展补 DailyBriefPrintable 协议遵守。")
