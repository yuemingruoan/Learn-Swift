//
//  main.swift
//  22-extensions-adding-capabilities
//
//  Created by 时雨 on 2026/3/20.
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

// MARK: - Core Type

struct StudyTask {
    let title: String
    let estimatedHours: Int
    var isFinished: Bool
}

// MARK: - Standard Library Helper Extension

extension Int {
    func studyHoursText() -> String {
        return "\(self) 小时"
    }
}

// MARK: - StudyTask Helper Extensions

extension StudyTask {
    func summaryLine() -> String {
        let status = isFinished ? "已完成" : "未完成"
        return "\(title) - \(estimatedHours.studyHoursText()) - \(status)"
    }

    var isLongTask: Bool {
        return estimatedHours >= 2
    }
}

// MARK: - StudyTask Protocol Conformance

extension StudyTask: DailyBriefPrintable {
    var name: String {
        return title
    }

    func dailyBrief() -> String {
        if isLongTask {
            return "今天优先完成这项长任务。"
        } else {
            return "今天可以作为短任务快速完成。"
        }
    }
}

func printDailyBriefs(items: [DailyBriefPrintable]) {
    print("开始输出今日简报：")

    for item in items {
        print("\(item.name)：\(item.dailyBrief())")
    }
}

let tasks = [
    StudyTask(title: "阅读 extension 章节", estimatedHours: 1, isFinished: true),
    StudyTask(title: "整理协议与扩展笔记", estimatedHours: 2, isFinished: false),
    StudyTask(title: "完成 demo 复盘", estimatedHours: 3, isFinished: false),
]

printDivider(title: "类型主体保持简单")
for task in tasks {
    print("原始任务：\(task.title)，预计时长：\(task.estimatedHours.studyHoursText())")
}

printDivider(title: "通过 extension 补方法和计算属性")
for task in tasks {
    print(task.summaryLine())
    print("是否为长任务：\(task.isLongTask)")
}

printDivider(title: "通过 extension 补协议遵守")
let printableTasks: [DailyBriefPrintable] = tasks
printDailyBriefs(items: printableTasks)

printDivider(title: "同一类型的能力可以按主题分块")
print("说明：")
print("- Core Type：StudyTask 只保留核心数据。")
print("- Helper Extensions：补 summaryLine() 和 isLongTask。")
print("- Protocol Conformance：单独补 DailyBriefPrintable。")

printDivider(title: "标准库类型也可以扩展")
let studyHours = 4
print("今天计划投入：\(studyHours.studyHoursText())")
