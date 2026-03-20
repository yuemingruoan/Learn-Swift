//
//  main.swift
//  20-polymorphism-unified-interfaces
//
//  Created by 时雨 on 2026/3/20.
//

import Foundation

func printDivider(title: String) {
    print("")
    print("======== \(title) ========")
}

class LearningMember {
    let name: String

    init(name: String) {
        self.name = name
    }

    func dailyFocus() -> String {
        return "完成今天的学习安排"
    }

    func printDailyBrief() {
        print("\(name)：\(dailyFocus())")
    }
}

class StudentMember: LearningMember {
    let track: String

    init(name: String, track: String) {
        self.track = track
        super.init(name: name)
    }

    override func dailyFocus() -> String {
        return "继续完成 \(track) 方向的练习"
    }
}

class TeacherMember: LearningMember {
    let subject: String

    init(name: String, subject: String) {
        self.subject = subject
        super.init(name: name)
    }

    override func dailyFocus() -> String {
        return "准备 \(subject) 的授课内容"
    }
}

class MentorMember: LearningMember {
    let groupName: String

    init(name: String, groupName: String) {
        self.groupName = groupName
        super.init(name: name)
    }

    override func dailyFocus() -> String {
        return "整理 \(groupName) 的答疑记录"
    }
}

func runMorningBriefing(members: [LearningMember]) {
    print("晨会开始：")

    for member in members {
        member.printDailyBrief()
    }
}

let members: [LearningMember] = [
    StudentMember(name: "小林", track: "iOS"),
    TeacherMember(name: "周老师", subject: "Swift"),
    MentorMember(name: "阿杰", groupName: "晚间答疑组"),
]

printDivider(title: "父类数组里放入多个不同子类")
runMorningBriefing(members: members)

printDivider(title: "统一调用，不同对象给出不同结果")
for member in members {
    print("\(member.name) 的今日重点：\(member.dailyFocus())")
}

printDivider(title: "父类类型变量也可以持有不同子类")
var currentMember: LearningMember = StudentMember(name: "小周", track: "SwiftUI")
currentMember.printDailyBrief()

currentMember = TeacherMember(name: "李老师", subject: "协议与抽象")
currentMember.printDailyBrief()

printDivider(title: "多态减少外部的类型判断")
print("说明：")
print("- 调用方只要求对象能按 LearningMember 的接口工作。")
print("- 具体输出由各个子类自己重写 dailyFocus() 决定。")
