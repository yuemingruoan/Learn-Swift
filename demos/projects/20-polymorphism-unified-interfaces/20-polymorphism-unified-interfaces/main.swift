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

func printFocusWithoutPolymorphism(member: LearningMember) {
    if let student = member as? StudentMember {
        print("\(student.name)：继续完成 \(student.track) 方向的练习")
    } else if let teacher = member as? TeacherMember {
        print("\(teacher.name)：准备 \(teacher.subject) 的授课内容")
    } else if let mentor = member as? MentorMember {
        print("\(mentor.name)：整理 \(mentor.groupName) 的答疑记录")
    } else {
        print("\(member.name)：完成今天的学习安排")
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

printDivider(title: "不用多态时，外部需要自己判断具体子类")
for member in members {
    printFocusWithoutPolymorphism(member: member)
}

printDivider(title: "用多态后，外部只保留统一接口调用")
for member in members {
    member.printDailyBrief()
}

printDivider(title: "父类类型变量也可以持有不同子类")
var currentMember: LearningMember = StudentMember(name: "小周", track: "SwiftUI")
currentMember.printDailyBrief()

currentMember = TeacherMember(name: "李老师", subject: "协议与抽象")
currentMember.printDailyBrief()

printDivider(title: "父类视角只能访问父类接口")
print("当前名字：\(currentMember.name)")
print("当前重点：\(currentMember.dailyFocus())")
print("说明：")
print("- currentMember 现在按 LearningMember 使用。")
print("- 因此可以访问 name 和 dailyFocus()。")
print("- 但不能直接访问 TeacherMember 才有的 subject。")

printDivider(title: "多态减少外部的类型判断")
print("说明：")
print("- 调用方只要求对象能按 LearningMember 的接口工作。")
print("- 如果不用多态，外部就得自己写 as? 和 if-else 分支。")
print("- 具体输出由各个子类自己重写 dailyFocus() 决定。")
