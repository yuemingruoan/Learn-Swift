//
//  main.swift
//  18-oop-basics-object-collaboration
//
//  Created by 时雨 on 2026/3/20.
//

import Foundation

func printDivider(title: String) {
    print("")
    print("======== \(title) ========")
}

class StudyTask {
    let title: String
    let estimatedHours: Int
    var isFinished: Bool

    init(title: String, estimatedHours: Int, isFinished: Bool = false) {
        self.title = title
        self.estimatedHours = estimatedHours
        self.isFinished = isFinished
    }

    func markFinished() {
        isFinished = true
    }

    func summary(index: Int) -> String {
        let status = isFinished ? "已完成" : "未完成"
        return "\(index). \(title) - 预计 \(estimatedHours) 小时 - \(status)"
    }
}

class StudyPlan {
    let name: String
    var tasks: [StudyTask]

    init(name: String, tasks: [StudyTask]) {
        self.name = name
        self.tasks = tasks
    }

    func finishedTaskCount() -> Int {
        var count = 0

        for task in tasks {
            if task.isFinished {
                count += 1
            }
        }

        return count
    }

    func progressText() -> String {
        return "已完成 \(finishedTaskCount())/\(tasks.count)"
    }

    func finishTask(at index: Int) {
        if index >= 0 && index < tasks.count {
            tasks[index].markFinished()
        }
    }

    func printTasks() {
        for index in 0..<tasks.count {
            print(tasks[index].summary(index: index + 1))
        }
    }
}

class Student {
    let name: String
    let plan: StudyPlan

    init(name: String, plan: StudyPlan) {
        self.name = name
        self.plan = plan
    }

    func beginStudyDay() {
        print("\(name) 今天开始执行学习计划：\(plan.name)")
        print("当前进度：\(plan.progressText())")
    }

    func completeTask(at index: Int) {
        plan.finishTask(at: index)
        print("\(name) 完成了一项任务，当前进度：\(plan.progressText())")
    }
}

class LearningCenter {
    let name: String
    var students: [Student]

    init(name: String, students: [Student]) {
        self.name = name
        self.students = students
    }

    func printOverview() {
        print("学习中心：\(name)")

        for student in students {
            print("- \(student.name)：\(student.plan.progressText())")
        }
    }
}

let swiftTasks = [
    StudyTask(title: "阅读第 18 章", estimatedHours: 1),
    StudyTask(title: "运行本章 demo", estimatedHours: 1),
    StudyTask(title: "整理 OOP 笔记", estimatedHours: 2),
]

let swiftPlan = StudyPlan(name: "Swift 面向对象入门计划", tasks: swiftTasks)
let student = Student(name: "小林", plan: swiftPlan)
let center = LearningCenter(name: "晚间学习中心", students: [student])

printDivider(title: "对象各自负责自己的状态")
print("计划名称：\(swiftPlan.name)")
swiftPlan.printTasks()

printDivider(title: "学生对象通过学习计划对象完成任务")
student.beginStudyDay()
student.completeTask(at: 0)
student.completeTask(at: 1)

printDivider(title: "学习中心对象观察多个对象的整体情况")
center.printOverview()

printDivider(title: "同一件事不再由 main.swift 亲自管理")
print("当前任务列表：")
student.plan.printTasks()
print("说明：")
print("- StudyTask 负责单个任务状态")
print("- StudyPlan 负责管理任务与进度")
print("- Student 负责发起学习动作")
print("- LearningCenter 负责查看整体概览")
