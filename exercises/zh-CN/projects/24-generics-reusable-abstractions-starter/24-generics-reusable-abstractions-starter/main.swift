//
//  main.swift
//  24-generics-reusable-abstractions-starter
//
//  Created by Codex on 2026/3/23.
//

func printDivider(title: String) {
    print("")
    print("======== \(title) ========")
}

// 这个 starter project 当前可以运行，但“同结构、不同类型”的重复非常多。
//
// 当前问题：
// 1. StudyTaskQueue 和 ChapterPlanQueue 几乎一模一样。
// 2. duplicateTask / duplicateChapterPlan、findTask / findChapterPlan 也是重复逻辑。
// 3. 某些地方用 [Any] 混装，类型关系很模糊。
// 4. describe(_:) 这类重载本来是合理的，但其它地方却把“该泛型化”的重复也继续分开写。
//
// 练习目标：
// - 只用本章知识，把“同结构、不同类型”的重复收拢起来。
// - 保留真正适合用重载的地方。
// - 不改变当前输出的核心业务含义。
//
// TODO 建议优先查看：
// - StudyTaskQueue
// - ChapterPlanQueue
// - duplicateTask(_:)
// - duplicateChapterPlan(_:)
// - findTask(in:title:)
// - findChapterPlan(in:title:)

struct StudyTask: Equatable {
    let title: String
    let estimatedHours: Int
}

struct ChapterPlan: Equatable {
    let title: String
    let priority: Int
}

func describe(_ value: Int) {
    print("整数资料编号：\(value)")
}

func describe(_ value: String) {
    print("字符串资料标题：\(value)")
}

struct StudyTaskQueue {
    var items: [StudyTask] = []

    mutating func enqueue(_ item: StudyTask) {
        items.append(item)
    }

    mutating func dequeue() -> StudyTask? {
        if items.count == 0 {
            return nil
        }

        let firstItem = items[0]
        var newItems: [StudyTask] = []

        if items.count > 1 {
            for index in 1..<items.count {
                newItems.append(items[index])
            }
        }

        items = newItems
        return firstItem
    }

    func peek() -> StudyTask? {
        if items.count == 0 {
            return nil
        }

        return items[0]
    }
}

struct ChapterPlanQueue {
    var items: [ChapterPlan] = []

    mutating func enqueue(_ item: ChapterPlan) {
        items.append(item)
    }

    mutating func dequeue() -> ChapterPlan? {
        if items.count == 0 {
            return nil
        }

        let firstItem = items[0]
        var newItems: [ChapterPlan] = []

        if items.count > 1 {
            for index in 1..<items.count {
                newItems.append(items[index])
            }
        }

        items = newItems
        return firstItem
    }

    func peek() -> ChapterPlan? {
        if items.count == 0 {
            return nil
        }

        return items[0]
    }
}

func duplicateTask(_ task: StudyTask) -> [StudyTask] {
    return [task, task]
}

func duplicateChapterPlan(_ plan: ChapterPlan) -> [ChapterPlan] {
    return [plan, plan]
}

func findTask(in tasks: [StudyTask], title: String) -> StudyTask? {
    for task in tasks {
        if task.title == title {
            return task
        }
    }

    return nil
}

func findChapterPlan(in plans: [ChapterPlan], title: String) -> ChapterPlan? {
    for plan in plans {
        if plan.title == title {
            return plan
        }
    }

    return nil
}

let tasks = [
    StudyTask(title: "补写泛型章节", estimatedHours: 2),
    StudyTask(title: "整理重载对比例子", estimatedHours: 1),
]

let chapterPlans = [
    ChapterPlan(title: "第 24 章", priority: 1),
    ChapterPlan(title: "第 25 章", priority: 2),
]

printDivider(title: "当前项目可以正常运行")
describe(24)
describe("泛型入门")

printDivider(title: "当前项目也在混用 Any")
let mixedValues: [Any] = [24, "闭包", true]
for value in mixedValues {
    print("混合资料项：\(value)")
}

printDivider(title: "重复的复制函数")
let duplicatedTasks = duplicateTask(tasks[0])
let duplicatedPlans = duplicateChapterPlan(chapterPlans[0])
print("duplicatedTasks 数量：\(duplicatedTasks.count)")
print("duplicatedPlans 数量：\(duplicatedPlans.count)")

printDivider(title: "重复的队列结构")
var taskQueue = StudyTaskQueue()
for task in tasks {
    taskQueue.enqueue(task)
}

var chapterQueue = ChapterPlanQueue()
for plan in chapterPlans {
    chapterQueue.enqueue(plan)
}

if let task = taskQueue.peek() {
    print("下一项任务：\(task.title)")
}

if let chapter = chapterQueue.peek() {
    print("下一章计划：\(chapter.title)")
}

while let task = taskQueue.dequeue() {
    print("处理任务：\(task.title)")
}

while let chapter = chapterQueue.dequeue() {
    print("处理章节：\(chapter.title)")
}

printDivider(title: "重复的查找函数")
if let task = findTask(in: tasks, title: "整理重载对比例子") {
    print("找到了任务：\(task.title)")
}

if let chapter = findChapterPlan(in: chapterPlans, title: "第 26 章") {
    print("找到了章节：\(chapter.title)")
} else {
    print("没有找到目标章节。")
}

printDivider(title: "TODO")
print("请把“同结构、不同类型”的重复收拢成泛型函数或泛型类型。")
