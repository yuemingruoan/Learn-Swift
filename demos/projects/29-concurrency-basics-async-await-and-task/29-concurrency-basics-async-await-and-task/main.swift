//
//  main.swift
//  29-concurrency-basics-async-await-and-task
//
//  Created by Codex on 2026/3/24.
//

func printDivider(title: String) {
    print("")
    print("======== \(title) ========")
}

struct StudyTask {
    let title: String
    let estimatedHours: Int
    let isFinished: Bool
}

enum DashboardLoadError: Error {
    case emptyTasks
}

func pause(label: String, nanoseconds: UInt64) async {
    print("\(label)：开始等待")

    do {
        try await Task.sleep(nanoseconds: nanoseconds)
    } catch {
        print("\(label)：等待被取消")
        return
    }

    print("\(label)：等待结束")
}

func fetchReminderPreview() async -> String {
    await pause(label: "提醒预览", nanoseconds: 300_000_000)
    return "先完成最重要的一项任务"
}

func loadTaskTitles() async throws -> [StudyTask] {
    print("任务列表：开始")
    try await Task.sleep(nanoseconds: 600_000_000)

    let tasks = [
        StudyTask(title: "复习闭包", estimatedHours: 1, isFinished: true),
        StudyTask(title: "整理 ARC 笔记", estimatedHours: 2, isFinished: false),
        StudyTask(title: "开始学习并发", estimatedHours: 3, isFinished: false),
    ]

    if tasks.isEmpty {
        throw DashboardLoadError.emptyTasks
    }

    print("任务列表：完成")
    return tasks
}

func loadReminderText() async -> String {
    print("提醒：开始")

    do {
        try await Task.sleep(nanoseconds: 500_000_000)
    } catch {
        return "提醒加载被取消，先保留旧提醒"
    }

    print("提醒：完成")
    return "先完成最重要的一项任务"
}

func makeSummaryLine(tasks: [StudyTask], reminder: String) -> String {
    let unfinishedCount = tasks.filter { task in
        task.isFinished == false
    }.count

    return "未完成 \(unfinishedCount) 项任务，提醒：\(reminder)"
}

func buildStudyReportLines(tasks: [StudyTask], reminder: String, summary: String) async throws -> [String] {
    var lines: [String] = []

    print("报告：开始整理任务标题")
    try await Task.sleep(nanoseconds: 400_000_000)
    try Task.checkCancellation()

    for task in tasks {
        lines.append("任务：\(task.title) / \(task.estimatedHours) 小时")
    }

    print("报告：开始整理提醒和摘要")
    try await Task.sleep(nanoseconds: 400_000_000)
    try Task.checkCancellation()

    lines.append("提醒：\(reminder)")
    lines.append("摘要：\(summary)")
    return lines
}

printDivider(title: "最小 async 函数和 await")
print("先发起提醒预览")
let preview = await fetchReminderPreview()
print("提醒预览：\(preview)")

printDivider(title: "顺序等待")
let tasksBySequence = try await loadTaskTitles()
let reminderBySequence = await loadReminderText()
print("顺序等待结果：")
print("- 任务数：\(tasksBySequence.count)")
print("- 提醒：\(reminderBySequence)")

printDivider(title: "先启动，再等待")
let tasksTask = Task {
    try await loadTaskTitles()
}

let reminderTask = Task {
    await loadReminderText()
}

let tasksByConcurrentStart = try await tasksTask.value
let reminderByConcurrentStart = await reminderTask.value
print("先启动，再等待结果：")
print("- 任务数：\(tasksByConcurrentStart.count)")
print("- 提醒：\(reminderByConcurrentStart)")

printDivider(title: "完整功能：异步学习看板")
let dashboardTasksTask = Task {
    try await loadTaskTitles()
}

let dashboardReminderTask = Task {
    await loadReminderText()
}

let dashboardTasks = try await dashboardTasksTask.value
let dashboardReminder = await dashboardReminderTask.value
let summaryLine = makeSummaryLine(tasks: dashboardTasks, reminder: dashboardReminder)

print("今日任务：")
for task in dashboardTasks {
    let status = task.isFinished ? "已完成" : "未完成"
    print("- \(task.title) / \(task.estimatedHours) 小时 / \(status)")
}
print("今日提醒：\(dashboardReminder)")
print("摘要：\(summaryLine)")

printDivider(title: "取消会真正影响流程")
let reportTask = Task {
    try await buildStudyReportLines(tasks: dashboardTasks, reminder: dashboardReminder, summary: summaryLine)
}

reportTask.cancel()

do {
    let reportLines = try await reportTask.value
    print("报告导出结果：")
    for line in reportLines {
        print(line)
    }
} catch is CancellationError {
    print("报告导出已取消")
} catch {
    print("报告导出失败")
}

printDivider(title: "这一章最想演示的差别")
print("说明：")
print("- async：声明这里的函数执行过程中可能会等待。")
print("- await：把等待点明确写在调用位置。")
print("- Task：先把独立的异步工作启动起来。")
print("- task.value：在真正需要结果时，再把任务结果取回来。")
print("- Task.checkCancellation()：让 cancel() 不只是发信号，而是真的影响执行流程。")
