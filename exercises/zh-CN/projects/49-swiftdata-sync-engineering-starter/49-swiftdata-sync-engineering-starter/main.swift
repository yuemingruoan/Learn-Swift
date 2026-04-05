//
//  main.swift
//  49-swiftdata-sync-engineering-starter
//
//  Created by Codex on 2026/4/4.
//

import Foundation
import SwiftData

enum SyncState: String {
    case synced
    case dirty
    case conflict
    case tombstoned
}

struct RemoteTaskSnapshot {
    let remoteID: Int
    let title: String
    let isFinished: Bool
    let updatedAt: Date
}

struct SyncReport {
    let createdCount: Int
    let updatedCount: Int
    let deletedCount: Int
    let conflictCount: Int
    let pendingCount: Int
}

@Model
final class LocalTaskRecord {
    var remoteID: Int
    var title: String
    var isFinished: Bool
    var localNote: String
    var lastRemoteUpdatedAt: Date
    var lastLocalModifiedAt: Date?
    var syncStateRaw: String
    var isTombstoned: Bool

    init(
        remoteID: Int,
        title: String,
        isFinished: Bool,
        localNote: String = "",
        lastRemoteUpdatedAt: Date,
        lastLocalModifiedAt: Date? = nil,
        syncState: SyncState = .synced,
        isTombstoned: Bool = false
    ) {
        self.remoteID = remoteID
        self.title = title
        self.isFinished = isFinished
        self.localNote = localNote
        self.lastRemoteUpdatedAt = lastRemoteUpdatedAt
        self.lastLocalModifiedAt = lastLocalModifiedAt
        self.syncStateRaw = syncState.rawValue
        self.isTombstoned = isTombstoned
    }

    var syncState: SyncState {
        get { SyncState(rawValue: syncStateRaw) ?? .synced }
        set { syncStateRaw = newValue.rawValue }
    }
}

@Model
final class PendingMutationRecord {
    var mutationID: String
    var taskRemoteID: Int
    var payload: String

    init(mutationID: String, taskRemoteID: Int, payload: String) {
        self.mutationID = mutationID
        self.taskRemoteID = taskRemoteID
        self.payload = payload
    }
}

struct TaskStore {
    let context: ModelContext

    func fetchTasks() throws -> [LocalTaskRecord] {
        try context.fetch(FetchDescriptor<LocalTaskRecord>())
            .sorted(by: { $0.remoteID < $1.remoteID })
    }

    func fetchPendingMutations() throws -> [PendingMutationRecord] {
        try context.fetch(FetchDescriptor<PendingMutationRecord>())
            .sorted(by: { $0.mutationID < $1.mutationID })
    }

    func replaceAll(with remoteTasks: [RemoteTaskSnapshot]) throws -> SyncReport {
        let oldRecords = try fetchTasks()
        for record in oldRecords {
            context.delete(record)
        }

        for task in remoteTasks {
            context.insert(
                LocalTaskRecord(
                    remoteID: task.remoteID,
                    title: task.title,
                    isFinished: task.isFinished,
                    lastRemoteUpdatedAt: task.updatedAt
                )
            )
        }

        try context.save()

        return SyncReport(
            createdCount: remoteTasks.count,
            updatedCount: 0,
            deletedCount: oldRecords.count,
            conflictCount: 0,
            pendingCount: try fetchPendingMutations().count
        )
    }

    func updateLocalNote(taskRemoteID: Int, note: String) throws {
        guard let task = try fetchTasks().first(where: { $0.remoteID == taskRemoteID }) else {
            return
        }

        task.localNote = note
        task.lastLocalModifiedAt = .now
        try context.save()
    }

    func markFinished(taskRemoteID: Int, isFinished: Bool) throws {
        guard let task = try fetchTasks().first(where: { $0.remoteID == taskRemoteID }) else {
            return
        }

        task.isFinished = isFinished
        try context.save()
    }
}

let snapshotV1 = [
    RemoteTaskSnapshot(remoteID: 1, title: "识别整包覆盖的问题", isFinished: false, updatedAt: date("2026-04-04T09:00:00Z")),
    RemoteTaskSnapshot(remoteID: 2, title: "保留本地备注", isFinished: false, updatedAt: date("2026-04-04T09:01:00Z"))
]

let snapshotV2 = [
    RemoteTaskSnapshot(remoteID: 2, title: "保留本地备注并做增量合并", isFinished: false, updatedAt: date("2026-04-04T10:00:00Z")),
    RemoteTaskSnapshot(remoteID: 3, title: "给同步补一份报告", isFinished: false, updatedAt: date("2026-04-04T10:01:00Z"))
]

do {
    let storeURL = try makeStoreURL()
    cleanStoreFiles(at: storeURL)
    let configuration = ModelConfiguration(url: storeURL)
    let container = try ModelContainer(
        for: LocalTaskRecord.self,
        PendingMutationRecord.self,
        configurations: configuration
    )
    let context = ModelContext(container)
    let store = TaskStore(context: context)

    _ = try store.replaceAll(with: snapshotV1)
    try store.updateLocalNote(taskRemoteID: 2, note: "这段备注应该在远程标题变化后仍然保留。")
    try store.markFinished(taskRemoteID: 1, isFinished: true)

    let report = try store.replaceAll(with: snapshotV2)

    print("======== 当前 starter 的输出 ========")
    print("created=\(report.createdCount) updated=\(report.updatedCount) deleted=\(report.deletedCount) conflict=\(report.conflictCount) pending=\(report.pendingCount)")
    print("当前任务：")
    for task in try store.fetchTasks() {
        print("- #\(task.remoteID) \(task.title) / finished=\(task.isFinished) / note=\(task.localNote.isEmpty ? "无" : task.localNote) / syncState=\(task.syncState.rawValue) / tombstoned=\(task.isTombstoned)")
    }
    print("待上传队列数：\(try store.fetchPendingMutations().count)")

    print(
        """

        ======== 你需要修复的地方 ========
        1. `replaceAll(with:)` 现在仍是“全删全建”，会丢掉 `localNote`。
        2. `markFinished(taskRemoteID:isFinished:)` 还没有把记录标成 dirty，也没有写待上传队列。
        3. 第二轮同步时，远程缺失的 task #1 应该进入 tombstone 或 conflict，而不是直接消失。
        4. `SyncReport` 现在只会报“删了多少旧记录”，并不能解释真正的同步结果。
        5. 请把 starter 改成按 `remoteID` 做 upsert，并保留本地专属字段。
        """
    )
} catch {
    print("Starter 运行失败：\(error)")
}

func date(_ value: String) -> Date {
    let formatter = ISO8601DateFormatter()
    guard let date = formatter.date(from: value) else {
        fatalError("Invalid date: \(value)")
    }
    return date
}

func makeStoreURL() throws -> URL {
    let caches = try FileManager.default.url(
        for: .cachesDirectory,
        in: .userDomainMask,
        appropriateFor: nil,
        create: true
    )
    let folder = caches
        .appendingPathComponent("learn-swift", isDirectory: true)
        .appendingPathComponent("49-swiftdata-sync-starter", isDirectory: true)
    try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
    return folder.appendingPathComponent("starter.store")
}

func cleanStoreFiles(at storeURL: URL) {
    let candidates = [
        storeURL,
        URL(fileURLWithPath: storeURL.path + "-shm"),
        URL(fileURLWithPath: storeURL.path + "-wal")
    ]

    for url in candidates where FileManager.default.fileExists(atPath: url.path) {
        try? FileManager.default.removeItem(at: url)
    }
}
