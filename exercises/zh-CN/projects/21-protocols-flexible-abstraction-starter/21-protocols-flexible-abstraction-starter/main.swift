//
//  main.swift
//  21-protocols-flexible-abstraction-starter
//
//  Created by Codex on 2026/3/21.
//

import Foundation

func printDivider(title: String) {
    print("")
    print("======== \(title) ========")
}

// 这个版本里的几个类型都能“输出汇报”，但它们并不是自然的父子关系。
// 当前问题：
// 1. 统一输出时仍然要按具体类型分别处理。
// 2. 如果硬要继续做继承，关系会很别扭。
//
// 练习目标：
// - 定义 DailyBriefPrintable。
// - 让 Student / Teacher / StudyRobot 一起遵守协议。
// - 把当前分别处理的输出流程改成 [DailyBriefPrintable] 的统一遍历。

class Student {
    let name: String
    let track: String

    init(name: String, track: String) {
        self.name = name
        self.track = track
    }

    func generateBrief() -> String {
        return "继续完成 \(track) 方向的练习"
    }
}

class Teacher {
    let name: String
    let subject: String

    init(name: String, subject: String) {
        self.name = name
        self.subject = subject
    }

    func generateBrief() -> String {
        return "准备 \(subject) 的讲解内容"
    }
}

struct StudyRobot {
    let name: String
    let version: String

    func generateBrief() -> String {
        return "使用 \(version) 模式整理学习进度"
    }
}

func printDailyBriefs(students: [Student], teachers: [Teacher], robots: [StudyRobot]) {
    print("开始输出今日汇报：")

    for student in students {
        print("\(student.name)：\(student.generateBrief())")
    }

    for teacher in teachers {
        print("\(teacher.name)：\(teacher.generateBrief())")
    }

    for robot in robots {
        print("\(robot.name)：\(robot.generateBrief())")
    }
}

let students = [
    Student(name: "小林", track: "iOS")
]

let teachers = [
    Teacher(name: "周老师", subject: "Swift")
]

let robots = [
    StudyRobot(name: "学习机器人", version: "R1")
]

printDivider(title: "当前版本已经能输出，但还没统一抽象")
printDailyBriefs(students: students, teachers: teachers, robots: robots)

printDivider(title: "下一步请你改成协议统一处理")
print("- 这里不太适合继续强行做继承。")
print("- 更自然的方向是：定义 DailyBriefPrintable。")
print("- 然后让 class 和 struct 一起遵守它，并统一遍历输出。")
