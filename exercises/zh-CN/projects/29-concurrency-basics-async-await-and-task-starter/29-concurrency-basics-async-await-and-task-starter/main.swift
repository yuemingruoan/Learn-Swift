//
//  main.swift
//  29-concurrency-basics-async-await-and-task-starter
//
//  Created by Codex on 2026/3/24.
//

func printDivider(title: String) {
    print("")
    print("======== \(title) ========")
}

// 这个 starter project 不是“功能没做完”，而是“异步流程写乱了”。
//
// 当前项目已经能：
// 1. 生成学习看板。
// 2. 导出学习报告。
//
// 但现在主要有下面几类问题：
// 1. 两项彼此独立的加载工作，被写成了顺序等待。
// 2. 某些已经在 async 流程里的逻辑，又额外包了一层 Task。
// 3. 报告导出虽然调用了 cancel()，但任务并没有真正停下来。
//
// 请按 TODO 1 到 TODO 5 的顺序修改。
// 不要改业务功能，只整理异步流程。
//
// 作业中可能会用到的语法：
// - async / await
// - async throws / try await
// - Task { ... }
// - task.value
// - Task.checkCancellation()

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
    // TODO 1：
    // 当前这两项工作彼此独立，但这里还是顺序等待。
    // 请保留这个函数签名不变，然后把函数体改成：
    // 1. 用 Task { ... } 启动 loadTaskTitles()。
    // 2. 用 Task { ... } 启动 loadReminderText()。
    // 3. 用 tasksTask.value / reminderTask.value 在后面取结果。
    
    let tasks = try await loadTaskTitles()
    let reminder = await loadReminderText()
    return (tasks, reminder)
}

func buildSummaryLine(tasks: [StudyTask], reminder: String) async -> String {
    // TODO 2：
    // 这里只是在整理字符串，并没有真正的异步等待。
    // 所以这里不应该再额外包一层 Task。
    //
    // 请把这个函数改成同步函数：
    //   func buildSummaryLine(tasks: [StudyTask], reminder: String) -> String
    //
    // 然后：
    // 1. 删除内部的 Task { ... }。
    // 2. 直接 return 最终字符串。
    let summaryTask = Task {
        let unfinishedCount = tasks.filter { task in
            task.isFinished == false
        }.count

        return "未完成 \(unfinishedCount) 项任务，提醒：\(reminder)"
    }

    return await summaryTask.value
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
    // TODO 3：
    // 如果你已经把 buildSummaryLine 改成同步函数，
    // 这里就不该再写 await buildSummaryLine(...)。
    //
    // 也就是说，这里最终应该接近：
    // - let (tasks, reminder) = try await loadDashboardData()
    // - let summary = buildSummaryLine(tasks: tasks, reminder: reminder)
    let (tasks, reminder) = try await loadDashboardData()
    let summary = await buildSummaryLine(tasks: tasks, reminder: reminder)

    let dashboard = StudyDashboard(tasks: tasks, reminder: reminder, summary: summary)
    printDashboard(dashboard)
    return dashboard
}

func buildStudyReportLines(from dashboard: StudyDashboard) async -> [String] {
    // TODO 4：
    // 当前版本的问题是：
    // - 就算任务已经被 cancel()，这里也只是打印一句话，然后继续整理完整报告。
    //
    // 请把这个函数改成：
    //   func buildStudyReportLines(from dashboard: StudyDashboard) async throws -> [String]
    //
    // 然后：
    // 1. 保留现有两个等待点。
    // 2. 在等待点之后补上 try Task.checkCancellation()。
    // 3. 让被取消的任务提前结束，而不是继续把 lines 填满。
    var lines: [String] = []

    print("报告：开始整理任务标题")
    do {
        try await Task.sleep(nanoseconds: 400_000_000)
    } catch {
        print("报告任务收到取消，但当前版本继续整理")
    }

    for task in dashboard.tasks {
        lines.append("任务：\(task.title) / \(task.estimatedHours) 小时")
    }

    print("报告：开始整理提醒和摘要")
    do {
        try await Task.sleep(nanoseconds: 400_000_000)
    } catch {
        print("报告任务收到取消，但当前版本继续整理")
    }

    lines.append("提醒：\(dashboard.reminder)")
    lines.append("摘要：\(dashboard.summary)")

    return lines
}

func runReportExportDemo(dashboard: StudyDashboard) async {
    // TODO 5：
    // 如果你把 buildStudyReportLines 改成了 async throws，
    // 这里也要一起改：
    //
    // 1. 用 Task { try await buildStudyReportLines(from: dashboard) } 启动任务。
    // 2. 用 try await reportTask.value 取结果。
    // 3. 用 do-catch 处理取消。
    // 4. 如果任务被取消，就不要继续打印完整报告内容。
    let reportTask = Task {
        await buildStudyReportLines(from: dashboard)
    }

    reportTask.cancel()

    let lines = await reportTask.value

    print("报告导出结果：")
    for line in lines {
        print(line)
    }

    print("TODO：当前 cancel() 后报告仍会继续整理，请改成真正响应取消。")
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

printDivider(title: "TODO")
print("请按 TODO 1 到 TODO 5 的要求重构，不要改业务功能。")
