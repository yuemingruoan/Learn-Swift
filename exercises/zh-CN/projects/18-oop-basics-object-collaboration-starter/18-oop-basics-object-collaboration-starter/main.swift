//
//  main.swift
//  18-oop-basics-object-collaboration-starter
//
//  Created by Codex on 2026/3/21.
//

import Foundation

func printDivider(title: String) {
    print("")
    print("======== \(title) ========")
}

// 这是一个“已经能跑，但结构还比较散”的学习中心脚本。
// 当前问题：
// 1. 同一件事的数据散落在很多顶层变量里。
// 2. 进度统计和完成任务逻辑都留在顶层函数中。
// 3. main.swift 直接管理所有状态，不利于继续扩展。
//
// 练习目标：
// - 尝试把这里重构成 StudyPlan / Student / LearningCenter 三个类型。
// - 把 finishTask(at:) 和 progressText() 收回对象内部。
// - 让 main.swift 不再直接读写所有细节。

let centerName = "晚间学习中心"
let studentName = "小林"
let planName = "Swift OOP 重构练习"

let taskTitles = [
    "阅读第 18 章正文",
    "运行本章 demo",
    "整理封装笔记"
]

let taskHours = [1, 1, 2]
var taskFinishedFlags = [false, false, false]

func progressText() -> String {
    var finishedCount = 0

    for flag in taskFinishedFlags {
        if flag {
            finishedCount += 1
        }
    }

    return "已完成 \(finishedCount)/\(taskFinishedFlags.count)"
}

func finishTask(at index: Int) {
    if index >= 0 && index < taskFinishedFlags.count {
        taskFinishedFlags[index] = true
    }
}

func printTaskList() {
    for index in 0..<taskTitles.count {
        let status = taskFinishedFlags[index] ? "已完成" : "未完成"
        print("\(index + 1). \(taskTitles[index]) - 预计 \(taskHours[index]) 小时 - \(status)")
    }
}

func printStudentSummary() {
    print("学生：\(studentName)")
    print("计划：\(planName)")
    print("当前进度：\(progressText())")
}

func printCenterOverview() {
    print("学习中心：\(centerName)")
    print("\(studentName)：\(progressText())")
}

printDivider(title: "当前脚本还能运行")
printTaskList()

printDivider(title: "main.swift 亲自推进所有流程")
printStudentSummary()
finishTask(at: 0)
finishTask(at: 1)
printStudentSummary()

printDivider(title: "整体概览")
printCenterOverview()

printDivider(title: "建议你开始重构")
print("- 先提取 StudyPlan：让任务和进度统计回到计划内部。")
print("- 再提取 Student：让学生对象发起完成任务动作。")
print("- 最后提取 LearningCenter：让中心对象负责输出整体概览。")
