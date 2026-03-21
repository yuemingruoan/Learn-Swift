//
//  main.swift
//  20-polymorphism-unified-interfaces-starter
//
//  Created by Codex on 2026/3/21.
//

import Foundation

func printDivider(title: String) {
    print("")
    print("======== \(title) ========")
}

// 这个版本已经有父类和子类，但“每日汇报”仍然依赖外部分支判断。
// 当前问题：
// 1. 调用方自己知道了太多子类细节。
// 2. 每增加一个新子类，都得继续补 if-else / as? 分支。
//
// 练习目标：
// - 在父类中提取统一接口 dailyFocus()。
// - 让不同子类分别 override。
// - 把 printFocusWithoutPolymorphism 改成统一调用版本。

class LearningMember {
    let name: String

    init(name: String) {
        self.name = name
    }
}

class StudentMember: LearningMember {
    let track: String

    init(name: String, track: String) {
        self.track = track
        super.init(name: name)
    }
}

class TeacherMember: LearningMember {
    let subject: String

    init(name: String, subject: String) {
        self.subject = subject
        super.init(name: name)
    }
}

class MentorMember: LearningMember {
    let groupName: String

    init(name: String, groupName: String) {
        self.groupName = groupName
        super.init(name: name)
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

let members: [LearningMember] = [
    StudentMember(name: "小林", track: "iOS"),
    TeacherMember(name: "周老师", subject: "Swift"),
    MentorMember(name: "阿杰", groupName: "晚间答疑组")
]

printDivider(title: "当前版本用分支完成统一汇报")
for member in members {
    printFocusWithoutPolymorphism(member: member)
}

printDivider(title: "下一步请你改成多态")
print("- 先在 LearningMember 中定义 dailyFocus()。")
print("- 再让 StudentMember / TeacherMember / MentorMember 分别提供自己的实现。")
print("- 最后把上面的分支调用改成统一的 member.dailyFocus()。")
