//
//  main.swift
//  21-protocols-flexible-abstraction
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

class Student: DailyBriefPrintable {
    let name: String
    let track: String

    init(name: String, track: String) {
        self.name = name
        self.track = track
    }

    func dailyBrief() -> String {
        return "继续完成 \(track) 方向的练习"
    }
}

class Teacher: DailyBriefPrintable {
    let name: String
    let subject: String

    init(name: String, subject: String) {
        self.name = name
        self.subject = subject
    }

    func dailyBrief() -> String {
        return "准备 \(subject) 的讲解内容"
    }
}

struct StudyRobot: DailyBriefPrintable {
    let name: String
    let version: String

    func dailyBrief() -> String {
        return "使用 \(version) 模式整理学习进度"
    }
}

func printDailyBriefs(reporters: [DailyBriefPrintable]) {
    print("开始输出今日汇报：")

    for reporter in reporters {
        print("\(reporter.name)：\(reporter.dailyBrief())")
    }
}

let reporters: [DailyBriefPrintable] = [
    Student(name: "小林", track: "iOS"),
    Teacher(name: "周老师", subject: "Swift"),
    StudyRobot(name: "学习机器人", version: "R1"),
]

printDivider(title: "不同类型一起遵守同一个协议")
printDailyBriefs(reporters: reporters)

printDivider(title: "协议类型变量也可以统一接收不同实例")
var currentReporter: DailyBriefPrintable = Student(name: "小周", track: "SwiftUI")
print("\(currentReporter.name)：\(currentReporter.dailyBrief())")

currentReporter = StudyRobot(name: "记录机器人", version: "R2")
print("\(currentReporter.name)：\(currentReporter.dailyBrief())")

printDivider(title: "协议视角只能访问协议要求")
let concreteStudent = Student(name: "阿明", track: "服务端 Swift")
let abstractReporter: DailyBriefPrintable = concreteStudent
print("具体类型视角可以知道学习方向：\(concreteStudent.track)")
print("协议类型视角统一读取名字：\(abstractReporter.name)")
print("协议类型视角统一读取汇报：\(abstractReporter.dailyBrief())")
print("说明：")
print("- abstractReporter 当前只按 DailyBriefPrintable 使用。")
print("- 因此可以访问 name 和 dailyBrief()。")
print("- 但不能直接访问 Student 才有的 track。")

printDivider(title: "协议不要求父子关系")
print("说明：")
print("- Student 和 Teacher 都是 class。")
print("- StudyRobot 是 struct。")
print("- 它们不是同一棵继承树里的父子类型。")
print("- 但它们都遵守 DailyBriefPrintable，所以可以被统一处理。")

printDivider(title: "协议带来的统一调用方式")
for reporter in reporters {
    print("调用形式保持一致：\(reporter.dailyBrief())")
}
