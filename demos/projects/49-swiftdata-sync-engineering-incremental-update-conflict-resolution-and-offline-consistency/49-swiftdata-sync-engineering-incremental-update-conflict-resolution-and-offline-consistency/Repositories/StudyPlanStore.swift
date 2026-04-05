//
//  StudyPlanStore.swift
//  49-swiftdata-sync-engineering-incremental-update-conflict-resolution-and-offline-consistency
//
//  Created by Codex on 2026/4/4.
//

import Foundation
import SwiftData

struct StudyPlanStore {
    let context: ModelContext

    func save() throws {
        try context.save()
    }

    func fetchPlanRecord() throws -> StudyPlanRecord? {
        try context.fetch(FetchDescriptor<StudyPlanRecord>()).first
    }

    func fetchTaskRecords() throws -> [StudyTaskRecord] {
        try context.fetch(FetchDescriptor<StudyTaskRecord>())
            .sorted(by: { lhs, rhs in
                if lhs.sortOrder == rhs.sortOrder {
                    return lhs.remoteID < rhs.remoteID
                }
                return lhs.sortOrder < rhs.sortOrder
            })
    }

    func fetchPendingMutationRecords() throws -> [PendingTaskMutationRecord] {
        try context.fetch(FetchDescriptor<PendingTaskMutationRecord>())
            .sorted(by: { lhs, rhs in
                if lhs.createdAt == rhs.createdAt {
                    return lhs.mutationID < rhs.mutationID
                }
                return lhs.createdAt < rhs.createdAt
            })
    }

    func fetchActivePendingMutationRecords() throws -> [PendingTaskMutationRecord] {
        try fetchPendingMutationRecords().filter { $0.status != .applied }
    }

    func taskRecord(remoteID: Int) throws -> StudyTaskRecord? {
        try fetchTaskRecords().first(where: { $0.remoteID == remoteID })
    }

    @discardableResult
    func ensurePlanRecord(
        from snapshot: RemoteStudyPlanSnapshotDTO,
        syncedAt: Date
    ) throws -> StudyPlanRecord {
        if let existing = try fetchPlanRecord() {
            existing.remoteID = snapshot.planID
            existing.remoteVersion = snapshot.version
            existing.title = snapshot.planTitle
            existing.ownerName = snapshot.ownerName
            existing.publishedAt = snapshot.publishedAt
            existing.lastSyncedAt = syncedAt
            return existing
        }

        let record = StudyPlanRecord(
            remoteID: snapshot.planID,
            remoteVersion: snapshot.version,
            title: snapshot.planTitle,
            ownerName: snapshot.ownerName,
            publishedAt: snapshot.publishedAt,
            lastSyncedAt: syncedAt
        )
        context.insert(record)
        return record
    }

    func makeDomainPlan() throws -> StudyPlan? {
        guard let plan = try fetchPlanRecord() else {
            return nil
        }

        let tasks = try fetchTaskRecords()
            .filter { $0.visibleInDomain }
            .map { record in
                StudyTask(
                    remoteID: record.remoteID,
                    title: record.title,
                    estimatedMinutes: record.estimatedMinutes,
                    isFinished: record.isFinished,
                    localNote: record.localNote,
                    syncState: record.syncState,
                    conflictHint: record.conflictKind.map { StudyPlanStore.conflictMessage(for: $0) }
                )
            }

        return StudyPlan(
            remoteID: plan.remoteID,
            title: plan.title,
            ownerName: plan.ownerName,
            publishedAt: plan.publishedAt,
            tasks: tasks
        )
    }

    func deleteAppliedMutations() throws {
        let applied = try fetchPendingMutationRecords().filter { $0.status == .applied }
        for mutation in applied {
            context.delete(mutation)
        }
    }

    static func conflictMessage(for kind: SyncConflictKind) -> String {
        switch kind {
        case .sharedFieldDiverged:
            return "共享字段出现冲突，当前保留了更晚的本地值。"
        case .deletedRemotelyWithPendingMutation:
            return "远程已删除该任务，但本地仍有待上传修改。"
        }
    }
}
