//
//  main.swift
//  49-swiftdata-sync-engineering-incremental-update-conflict-resolution-and-offline-consistency
//
//  Created by Codex on 2026/4/4.
//

import Foundation
import SwiftData

let semaphore = DispatchSemaphore(value: 0)
Task {
    await runDemo()
    semaphore.signal()
}
semaphore.wait()

private func runDemo() async {
    do {
        let storeURL = try DemoPaths.storeURL()
        DemoPaths.cleanStoreFiles(at: storeURL)

        let remote = ScriptedStudyPlanRemoteSource(snapshots: makeRemoteSnapshots())

        printDivider("准备本地 SwiftData store")
        print("store 文件：\(storeURL.path)")
        print("远程当前版本：v\(await remote.currentVersion())")

        let container1 = try DemoPaths.makeContainer(at: storeURL)
        let context1 = ModelContext(container1)
        let store1 = StudyPlanStore(context: context1)
        let sync1 = StudyPlanSyncService(remote: remote, store: store1)

        let firstReport = try await sync1.performSync()
        SyncReportPrinter.printReport(firstReport, headline: "第 1 步：首次 pull，建立本地记录")
        try printRecords(store: store1, headline: "第 2 步：首次同步后的 Record 层")
        try printDomain(store: store1, headline: "第 3 步：首次同步后的 Domain 层")

        try sync1.markTaskFinished(
            taskRemoteID: 1,
            isFinished: true,
            changedAt: date("2026-04-04T10:05:00Z")
        )
        try sync1.updateLocalNote(
            taskRemoteID: 2,
            note: "本地备注：这类提示只服务当前设备，不应该被远程覆盖。",
            changedAt: date("2026-04-04T10:07:00Z")
        )
        printDivider("第 4 步：离线本地修改")
        print("task #1 被标记为完成，并进入 dirty + pending queue。")
        print("task #2 新增 localNote，但不进入待上传队列。")
        try printRecords(store: store1, headline: "第 5 步：离线修改后的 Record 层")
        try printPendingQueue(store: store1, headline: "第 6 步：离线修改后的 Pending Queue")

        let container2 = try DemoPaths.makeContainer(at: storeURL)
        let context2 = ModelContext(container2)
        let store2 = StudyPlanStore(context: context2)
        let sync2 = StudyPlanSyncService(remote: remote, store: store2)
        printDivider("第 7 步：重建容器，验证状态不是内存假象")
        try printRecords(store: store2, headline: "重建容器后的 Record 层")
        try printPendingQueue(store: store2, headline: "重建容器后的 Pending Queue")

        await remote.advanceToNextSnapshot()
        printDivider("第 8 步：远程推进到 v2")
        print("v2 会更新任务标题和顺序，并新增一条远程任务。")
        let secondReport = try await sync2.performSync()
        SyncReportPrinter.printReport(secondReport, headline: "第 9 步：第二轮同步（先 push，再 pull v2）")
        try printRecords(store: store2, headline: "第 10 步：v2 合并后的 Record 层")
        try printPendingQueue(store: store2, headline: "第 11 步：v2 合并后的 Pending Queue")
        try printDomain(store: store2, headline: "第 12 步：v2 合并后的 Domain 层")

        try sync2.markTaskFinished(
            taskRemoteID: 3,
            isFinished: true,
            changedAt: date("2026-04-04T10:25:00Z")
        )
        printDivider("第 13 步：再次离线修改")
        print("task #3 新增一条待上传完成状态，下一轮会制造删除冲突。")
        try printPendingQueue(store: store2, headline: "第 14 步：第二次离线修改后的 Pending Queue")

        await remote.advanceToNextSnapshot()
        printDivider("第 15 步：远程推进到 v3")
        print("v3 会删除 task #3（本地仍有待上传 mutation）和 task #4（本地无待上传 mutation）。")

        let container3 = try DemoPaths.makeContainer(at: storeURL)
        let context3 = ModelContext(container3)
        let store3 = StudyPlanStore(context: context3)
        let sync3 = StudyPlanSyncService(remote: remote, store: store3)
        let thirdReport = try await sync3.performSync()
        SyncReportPrinter.printReport(thirdReport, headline: "第 16 步：第三轮同步，观察 delete conflict 与 tombstone")
        try printRecords(store: store3, headline: "第 17 步：v3 合并后的 Record 层")
        try printPendingQueue(store: store3, headline: "第 18 步：v3 合并后的 Pending Queue")
        try printDomain(store: store3, headline: "第 19 步：最终 Domain 层")
    } catch {
        print("Demo 运行失败：\(error)")
    }
}

private func printDivider(_ title: String) {
    print("\n======== \(title) ========")
}

private func printRecords(store: StudyPlanStore, headline: String) throws {
    print("\n======== \(headline) ========")
    if let plan = try store.fetchPlanRecord() {
        print("Plan.remoteID = \(plan.remoteID)")
        print("Plan.remoteVersion = \(plan.remoteVersion)")
        print("Plan.title = \(plan.title)")
        print("Plan.lastSyncedAt = \(formatted(plan.lastSyncedAt))")
    } else {
        print("(没有 StudyPlanRecord)")
    }

    let tasks = try store.fetchTaskRecords()
    if tasks.isEmpty {
        print("(没有 StudyTaskRecord)")
        return
    }

    for task in tasks {
        let localModified = task.lastLocalModifiedAt.map(formatted(_:)) ?? "nil"
        let conflict = task.conflictKind?.rawValue ?? "nil"
        print("- task #\(task.remoteID) \(task.title)")
        print("  estimatedMinutes=\(task.estimatedMinutes) sortOrder=\(task.sortOrder) finished=\(task.isFinished)")
        print("  localNote=\(task.localNote.isEmpty ? "无" : task.localNote)")
        print("  syncState=\(task.syncState.rawValue) tombstoned=\(task.isTombstoned) conflictKind=\(conflict)")
        print("  lastRemoteUpdatedAt=\(formatted(task.lastRemoteUpdatedAt)) lastLocalModifiedAt=\(localModified)")
    }
}

private func printPendingQueue(store: StudyPlanStore, headline: String) throws {
    print("\n======== \(headline) ========")
    let queue = try store.fetchPendingMutationRecords()
    if queue.isEmpty {
        print("(没有 PendingTaskMutationRecord)")
        return
    }

    for mutation in queue {
        print("- mutationID=\(mutation.mutationID)")
        print("  taskRemoteID=\(mutation.taskRemoteID) kind=\(mutation.kind.rawValue) status=\(mutation.status.rawValue)")
        print("  retryCount=\(mutation.retryCount) lastAttemptAt=\(mutation.lastAttemptAt.map(formatted(_:)) ?? "nil")")
        print("  payloadJSON=\(mutation.payloadJSON)")
    }
}

private func printDomain(store: StudyPlanStore, headline: String) throws {
    print("\n======== \(headline) ========")
    guard let plan = try store.makeDomainPlan() else {
        print("(没有领域计划)")
        return
    }

    print("领域计划：\(plan.title)")
    print("作者：\(plan.ownerName)")
    print("完成进度：\(plan.completionSummary)")
    print("有冲突的任务数：\(plan.conflictTaskCount)")
    print("包含本地备注的任务数：\(plan.localNoteCount)")

    for task in plan.tasks {
        print("- task #\(task.remoteID) \(task.title) / finished=\(task.isFinished) / syncState=\(task.syncState.rawValue)")
        print("  note=\(task.localNote.isEmpty ? "无" : task.localNote)")
        print("  conflictHint=\(task.conflictHint ?? "无")")
    }
}

private func makeRemoteSnapshots() -> [RemoteStudyPlanSnapshotDTO] {
    [
        RemoteStudyPlanSnapshotDTO(
            version: 1,
            planID: 101,
            planTitle: "SwiftData 同步工程",
            ownerName: "Alice",
            publishedAt: date("2026-04-04T09:00:00Z"),
            tasks: [
                RemoteStudyTaskDTO(
                    remoteID: 1,
                    title: "识别整包覆盖为什么会丢本地修改",
                    estimatedMinutes: 20,
                    isFinished: false,
                    sortOrder: 0,
                    updatedAt: date("2026-04-04T09:00:00Z")
                ),
                RemoteStudyTaskDTO(
                    remoteID: 2,
                    title: "建立 DTO / Record / Domain 分层",
                    estimatedMinutes: 30,
                    isFinished: false,
                    sortOrder: 1,
                    updatedAt: date("2026-04-04T09:01:00Z")
                ),
                RemoteStudyTaskDTO(
                    remoteID: 3,
                    title: "把本地修改放进待上传队列",
                    estimatedMinutes: 25,
                    isFinished: false,
                    sortOrder: 2,
                    updatedAt: date("2026-04-04T09:02:00Z")
                )
            ]
        ),
        RemoteStudyPlanSnapshotDTO(
            version: 2,
            planID: 101,
            planTitle: "SwiftData 同步工程（v2）",
            ownerName: "Alice",
            publishedAt: date("2026-04-04T09:00:00Z"),
            tasks: [
                RemoteStudyTaskDTO(
                    remoteID: 1,
                    title: "识别整包覆盖为什么会丢本地修改",
                    estimatedMinutes: 20,
                    isFinished: false,
                    sortOrder: 0,
                    updatedAt: date("2026-04-04T10:10:00Z")
                ),
                RemoteStudyTaskDTO(
                    remoteID: 2,
                    title: "把 DTO 映射升级成增量合并",
                    estimatedMinutes: 45,
                    isFinished: false,
                    sortOrder: 2,
                    updatedAt: date("2026-04-04T10:12:00Z")
                ),
                RemoteStudyTaskDTO(
                    remoteID: 3,
                    title: "把本地修改放进待上传队列",
                    estimatedMinutes: 25,
                    isFinished: false,
                    sortOrder: 1,
                    updatedAt: date("2026-04-04T10:11:00Z")
                ),
                RemoteStudyTaskDTO(
                    remoteID: 4,
                    title: "给每轮同步补一份 SyncReport",
                    estimatedMinutes: 18,
                    isFinished: false,
                    sortOrder: 3,
                    updatedAt: date("2026-04-04T10:13:00Z")
                )
            ]
        ),
        RemoteStudyPlanSnapshotDTO(
            version: 3,
            planID: 101,
            planTitle: "SwiftData 同步工程（v3）",
            ownerName: "Alice",
            publishedAt: date("2026-04-04T09:00:00Z"),
            tasks: [
                RemoteStudyTaskDTO(
                    remoteID: 1,
                    title: "识别整包覆盖为什么会丢本地修改",
                    estimatedMinutes: 20,
                    isFinished: true,
                    sortOrder: 0,
                    updatedAt: date("2026-04-04T10:20:00Z")
                ),
                RemoteStudyTaskDTO(
                    remoteID: 2,
                    title: "把 DTO 映射升级成增量合并",
                    estimatedMinutes: 45,
                    isFinished: false,
                    sortOrder: 1,
                    updatedAt: date("2026-04-04T10:21:00Z")
                )
            ]
        )
    ]
}

private func date(_ value: String) -> Date {
    let formatter = ISO8601DateFormatter()
    guard let date = formatter.date(from: value) else {
        fatalError("Invalid ISO8601 date: \(value)")
    }
    return date
}

private func formatted(_ date: Date) -> String {
    let formatter = ISO8601DateFormatter()
    return formatter.string(from: date)
}
