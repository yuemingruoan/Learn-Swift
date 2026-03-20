//
//  main.swift
//  19-inheritance-is-a-has-a
//
//  Created by 时雨 on 2026/3/20.
//

import Foundation

func printDivider(title: String) {
    print("")
    print("======== \(title) ========")
}

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

class LearningMember {
    let name: String

    init(name: String) {
        self.name = name
    }

    func roleDescription() -> String {
        return "学习中心成员"
    }

    func introduce() {
        print("你好，我是 \(name)，我的身份是：\(roleDescription())")
    }
}

class StudentMember: LearningMember {
    let track: String

    init(name: String, track: String) {
        self.track = track
        super.init(name: name)
    }

    override func roleDescription() -> String {
        return "学生，当前学习方向是 \(track)"
    }
}

class TeacherMember: LearningMember {
    let subject: String

    init(name: String, subject: String) {
        self.subject = subject
        super.init(name: name)
    }

    override func roleDescription() -> String {
        return "老师，当前授课方向是 \(subject)"
    }

    override func introduce() {
        super.introduce()
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

printDivider(title: "is-a：学生和老师都是成员的一种")
student.introduce()
teacher.introduce()
print("说明：StudentMember is-a LearningMember")
print("说明：TeacherMember is-a LearningMember")

printDivider(title: "has-a：学习中心拥有投影仪")
center.printResourceSummary()
print("说明：StudyCenter has-a Projector")

printDivider(title: "uses-a：老师在动作里使用投影仪")
teacher.use(projector: center.projector)
print("说明：TeacherMember uses-a Projector")

printDivider(title: "什么时候适合继承")
print("- 能自然说出“X 是一种 Y”时，优先考虑继承。")
print("- 如果更像“拥有某个对象”，通常更适合组合。")
print("- 如果只是“在某个动作里会用到某个对象”，通常是 uses-a。")
