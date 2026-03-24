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

struct StudyDashboard {
    let tasks: [StudyTask]
    let reminder: String
    let summary: String
}

enum DashboardLoadError: Error {
    case emptyTasks
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

func loadDashboardData() async throws -> ([StudyTask], String) {
    let tasksTask = Task {
        try await loadTaskTitles()
    }

    let reminderTask = Task {
        await loadReminderText()
    }

    let tasks = try await tasksTask.value
    let reminder = await reminderTask.value
    return (tasks, reminder)
}

func buildSummaryLine(tasks: [StudyTask], reminder: String) -> String {
    let unfinishedCount = tasks.filter { task in
        task.isFinished == false
    }.count

    return "未完成 \(unfinishedCount) 项任务，提醒：\(reminder)"
}

func printDashboard(_ dashboard: StudyDashboard) {
    print("今日任务：")
    for task in dashboard.tasks {
        let status = task.isFinished ? "已完成" : "未完成"
        print("- \(task.title) / \(task.estimatedHours) 小时 / \(status)")
    }

    print("今日提醒：\(dashboard.reminder)")
    print("摘要：\(dashboard.summary)")
}

func runDashboardDemo() async throws -> StudyDashboard {
    let (tasks, reminder) = try await loadDashboardData()
    let summary = buildSummaryLine(tasks: tasks, reminder: reminder)

    let dashboard = StudyDashboard(tasks: tasks, reminder: reminder, summary: summary)
    printDashboard(dashboard)
    return dashboard
}

func buildStudyReportLines(from dashboard: StudyDashboard) async throws -> [String] {
    try Task.checkCancellation()
    var lines: [String] = []

    print("报告：开始整理任务标题")
    try await Task.sleep(nanoseconds: 400_000_000)
    try Task.checkCancellation()

    for task in dashboard.tasks {
        lines.append("任务：\(task.title) / \(task.estimatedHours) 小时")
    }

    print("报告：开始整理提醒和摘要")
    try await Task.sleep(nanoseconds: 400_000_000)
    try Task.checkCancellation()

    lines.append("提醒：\(dashboard.reminder)")
    lines.append("摘要：\(dashboard.summary)")

    return lines
}

func runReportExportDemo(dashboard: StudyDashboard) async {
    let reportTask = Task {
        try await buildStudyReportLines(from: dashboard)
    }

    reportTask.cancel()

    do {
        let lines = try await reportTask.value

        print("报告导出结果：")
        for line in lines {
            print(line)
        }
    } catch is CancellationError {
        print("报告导出已取消")
    } catch {
        print("报告导出失败")
    }
}

printDivider(title: "完整功能：学习看板")

do {
    let dashboard = try await runDashboardDemo()

    printDivider(title: "完整功能：导出学习报告")
    await runReportExportDemo(dashboard: dashboard)
} catch DashboardLoadError.emptyTasks {
    print("学习看板加载失败：任务列表为空")
} catch {
    print("学习看板加载失败")
}

printDivider(title: "重构结果")
print("异步流程已重构：独立加载会并发启动，字符串整理不再额外创建任务，报告导出会响应取消。")
