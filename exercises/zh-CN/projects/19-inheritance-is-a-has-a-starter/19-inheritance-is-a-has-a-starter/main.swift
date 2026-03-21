//
//  main.swift
//  19-inheritance-is-a-has-a-starter
//
//  Created by Codex on 2026/3/21.
//

import Foundation

func printDivider(title: String) {
    print("")
    print("======== \(title) ========")
}

// 这是一个“功能已经够用，但关系还没整理好”的版本。
// 当前问题：
// 1. StudentMember 和 TeacherMember 有明显重复。
// 2. 还没有共同父类表达“成员”的共性。
// 3. Projector / StudyCenter / TeacherMember 的关系需要用建模语言说清楚。
//
// 练习目标：
// - 提取 LearningMember 作为共同父类。
// - 让 StudentMember / TeacherMember 用 is-a 建模共性。
// - 保持 StudyCenter has-a Projector。
// - 保持 TeacherMember uses-a Projector。

class Projector {
    let model: String
    private(set) var isOn: Bool

    init(model: String, isOn: Bool = false) {
        self.model = model
        self.isOn = isOn
    }

    func turnOn() {
        isOn = true
        print("\(model) 已开机。")
    }
}

class StudentMember {
    let name: String
    let track: String

    init(name: String, track: String) {
        self.name = name
        self.track = track
    }

    func roleDescription() -> String {
        return "学生，当前学习方向是 \(track)"
    }

    func introduce() {
        print("你好，我是 \(name)，我的身份是：\(roleDescription())")
    }
}

class TeacherMember {
    let name: String
    let subject: String

    init(name: String, subject: String) {
        self.name = name
        self.subject = subject
    }

    func roleDescription() -> String {
        return "老师，当前授课方向是 \(subject)"
    }

    func introduce() {
        print("你好，我是 \(name)，我的身份是：\(roleDescription())")
        print("我今天要准备 \(subject) 方向的讲解。")
    }

    func use(projector: Projector) {
        if !projector.isOn {
            projector.turnOn()
        }

        print("\(name) 正在使用 \(projector.model) 进行授课。")
    }
}

class StudyCenter {
    let name: String
    let projector: Projector

    init(name: String, projector: Projector) {
        self.name = name
        self.projector = projector
    }

    func printResourceSummary() {
        print("\(name) 当前配备的投影仪型号是：\(projector.model)")
    }
}

let student = StudentMember(name: "小林", track: "iOS")
let teacher = TeacherMember(name: "周老师", subject: "Swift 面向对象设计")
let center = StudyCenter(name: "晚间学习中心", projector: Projector(model: "Epson-X100"))

printDivider(title: "当前版本能运行，但结构还有重复")
student.introduce()
teacher.introduce()

printDivider(title: "资源与使用关系")
center.printResourceSummary()
teacher.use(projector: center.projector)

printDivider(title: "请开始整理关系")
print("- StudentMember 和 TeacherMember 更像 is-a LearningMember。")
print("- StudyCenter 和 Projector 更像 has-a。")
print("- TeacherMember 在 use(projector:) 里体现 uses-a。")
print("- 先想清楚关系，再决定怎么抽共同父类。")
