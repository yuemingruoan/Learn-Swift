//
//  main.swift
//  24-generics-reusable-abstractions
//
//  Created by Codex on 2026/3/23.
//

func printDivider(title: String) {
    print("")
    print("======== \(title) ========")
}

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

struct ResourceBox<Item> {
    let item: Item
}

struct StudyQueue<Element> {
    var items: [Element] = []

    var count: Int {
        return items.count
    }

    mutating func enqueue(_ item: Element) {
        items.append(item)
    }

    mutating func dequeue() -> Element? {
        if items.count == 0 {
            return nil
        }

        let firstItem = items[0]
        var remainingItems: [Element] = []

        for index in 1..<items.count {
            remainingItems.append(items[index])
        }

        items = remainingItems
        return firstItem
    }

    func peek() -> Element? {
        if items.count == 0 {
            return nil
        }

        return items[0]
    }
}

func duplicate<T>(_ value: T) -> [T] {
    return [value, value]
}

func findFirstMatch<T: Equatable>(in items: [T], target: T) -> T? {
    for item in items {
        if item == target {
            return item
        }
    }

    return nil
}

func printPair<T>(_ first: T, _ second: T) {
    print("这一对数据属于同一种类型：\(first) | \(second)")
}

let tasks = [
    StudyTask(title: "补写泛型章节", estimatedHours: 2),
    StudyTask(title: "整理重载对比例子", estimatedHours: 1),
]

let chapterPlans = [
    ChapterPlan(title: "第 24 章", priority: 1),
    ChapterPlan(title: "第 25 章", priority: 2),
]

printDivider(title: "同名重载适合不同实现")
describe(24)
describe("泛型入门")
print("说明：")
print("- describe(_:) 名字相同。")
print("- 但 Int 和 String 的展示逻辑并不一样。")
print("- 这种场景更适合用重载。")

printDivider(title: "Any 可以混装不同类型")
let mixedValues: [Any] = [24, "闭包", true]
for value in mixedValues {
    print("混合资料项：\(value)")
}
print("说明：")
print("- [Any] 允许不同类型放在一起。")
print("- 但它没有表达“这两个值必须是同一种类型”这样的关系。")

printDivider(title: "泛型函数保留类型关系")
printPair("第 24 章", "第 25 章")
printPair(80, 95)
let duplicatedTask = duplicate(tasks[0])
print("duplicate(_:) 返回了 \(duplicatedTask.count) 个相同任务。")

printDivider(title: "泛型容器可以服务不同资料")
let taskBox = ResourceBox(item: tasks[0])
print("任务盒子里装的是：\(taskBox.item.title) - \(taskBox.item.estimatedHours) 小时")

let chapterBox = ResourceBox(item: chapterPlans[0])
print("章节盒子里装的是：\(chapterBox.item.title) - 优先级 \(chapterBox.item.priority)")

printDivider(title: "完整功能：学习资源调度中心")
var taskQueue = StudyQueue<StudyTask>()
for task in tasks {
    taskQueue.enqueue(task)
}

var chapterQueue = StudyQueue<ChapterPlan>()
for plan in chapterPlans {
    chapterQueue.enqueue(plan)
}

print("任务队列当前数量：\(taskQueue.count)")
print("章节队列当前数量：\(chapterQueue.count)")

if let nextTask = taskQueue.peek() {
    print("下一项任务：\(nextTask.title)")
}

while let task = taskQueue.dequeue() {
    print("开始处理任务：\(task.title)")
}

while let chapter = chapterQueue.dequeue() {
    print("开始安排章节：\(chapter.title)")
}

printDivider(title: "泛型约束让查找规则更清楚")
if let matchedTask = findFirstMatch(in: tasks, target: StudyTask(title: "整理重载对比例子", estimatedHours: 1)) {
    print("找到了目标任务：\(matchedTask.title)")
} else {
    print("没有找到目标任务。")
}

if let matchedChapter = findFirstMatch(in: chapterPlans, target: ChapterPlan(title: "第 26 章", priority: 3)) {
    print("找到了目标章节：\(matchedChapter.title)")
} else {
    print("没有找到目标章节。")
}

printDivider(title: "这一章最想演示的差别")
print("说明：")
print("- 重载：同名，但每种类型可以有不同实现。")
print("- Any：允许混装不同类型，但类型关系会被抹平。")
print("- 泛型：保留“这一套逻辑对某种类型成立”的关系。")
