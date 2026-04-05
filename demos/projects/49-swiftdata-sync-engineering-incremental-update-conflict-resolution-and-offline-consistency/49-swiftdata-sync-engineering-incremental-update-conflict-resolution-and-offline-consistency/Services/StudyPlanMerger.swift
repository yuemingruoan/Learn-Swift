//
//  StudyPlanMerger.swift
//  49-swiftdata-sync-engineering-incremental-update-conflict-resolution-and-offline-consistency
//
//  Created by Codex on 2026/4/4.
//

import Foundation
import SwiftData

struct MergeOutcome {
    let createdCount: Int
    let updatedCount: Int
    let deletedCount: Int
    let conflictCount: Int
    let skippedCount: Int
    let conflicts: [SyncConflict]
}

enum StudyPlanMerger {
    static func merge(
        snapshot: RemoteStudyPlanSnapshotDTO,
        store: StudyPlanStore,
        syncedAt: Date = .now
    ) throws -> MergeOutcome {
        let plan = try store.ensurePlanRecord(from: snapshot, syncedAt: syncedAt)
        let existingTasks = Dictionary(uniqueKeysWithValues: try store.fetchTaskRecords().map { ($0.remoteID, $0) })
        let activeMutations = try store.fetchActivePendingMutationRecords()
        let activeMutationRecordsByTaskID = Dictionary(grouping: activeMutations, by: \.taskRemoteID)

        var seenRemoteIDs = Set<Int>()
        var createdCount = 0
        var updatedCount = 0
        var deletedCount = 0
        var conflictCount = 0
        var skippedCount = 0
        var conflicts: [SyncConflict] = []

        for remoteTask in snapshot.tasks {
            seenRemoteIDs.insert(remoteTask.remoteID)

            if let localTask = existingTasks[remoteTask.remoteID] {
                var changed = false
                let hasPendingSharedMutation = activeMutationRecordsByTaskID[remoteTask.remoteID]?.contains(where: { $0.kind == .setFinished }) ?? false

                if localTask.title != remoteTask.title {
                    localTask.title = remoteTask.title
                    changed = true
                }
                if localTask.estimatedMinutes != remoteTask.estimatedMinutes {
                    localTask.estimatedMinutes = remoteTask.estimatedMinutes
                    changed = true
                }
                if localTask.sortOrder != remoteTask.sortOrder {
                    localTask.sortOrder = remoteTask.sortOrder
                    changed = true
                }
                if localTask.lastRemoteUpdatedAt != remoteTask.updatedAt {
                    localTask.lastRemoteUpdatedAt = remoteTask.updatedAt
                    changed = true
                }
                if localTask.plan == nil || localTask.plan?.remoteID != plan.remoteID {
                    localTask.plan = plan
                    changed = true
                }
                if localTask.isTombstoned {
                    localTask.isTombstoned = false
                    changed = true
                }
                if localTask.conflictKind != nil && localTask.syncState != .conflict {
                    localTask.conflictKind = nil
                    changed = true
                }

                if hasPendingSharedMutation,
                   let localModifiedAt = localTask.lastLocalModifiedAt,
                   localModifiedAt > remoteTask.updatedAt {
                    if localTask.syncState != .dirty {
                        localTask.syncState = .dirty
                        changed = true
                    }
                } else {
                    if localTask.isFinished != remoteTask.isFinished {
                        localTask.isFinished = remoteTask.isFinished
                        changed = true
                    }
                    if localTask.syncState != .conflict && localTask.syncState != .synced {
                        localTask.syncState = .synced
                        changed = true
                    }
                    if localTask.conflictKind != nil {
                        localTask.conflictKind = nil
                        changed = true
                    }
                }

                if changed {
                    updatedCount += 1
                } else {
                    skippedCount += 1
                }
            } else {
                let newTask = StudyTaskRecord(
                    remoteID: remoteTask.remoteID,
                    title: remoteTask.title,
                    estimatedMinutes: remoteTask.estimatedMinutes,
                    isFinished: remoteTask.isFinished,
                    sortOrder: remoteTask.sortOrder,
                    lastRemoteUpdatedAt: remoteTask.updatedAt,
                    syncState: .synced,
                    localNote: "",
                    isTombstoned: false,
                    plan: plan
                )
                store.context.insert(newTask)
                createdCount += 1
            }
        }

        for (remoteID, localTask) in existingTasks where !seenRemoteIDs.contains(remoteID) {
            let hasPendingSharedMutation = activeMutationRecordsByTaskID[remoteID]?.contains(where: { $0.kind == .setFinished }) ?? false

            if hasPendingSharedMutation {
                if localTask.syncState != .conflict || localTask.conflictKind != .deletedRemotelyWithPendingMutation || !localTask.isTombstoned {
                    localTask.syncState = .conflict
                    localTask.conflictKind = .deletedRemotelyWithPendingMutation
                    localTask.isTombstoned = true
                    conflictCount += 1
                    conflicts.append(
                        SyncConflict(
                            taskRemoteID: remoteID,
                            kind: .deletedRemotelyWithPendingMutation,
                            message: "任务 #\(remoteID) 在远程已被删除，但本地仍有待上传完成状态。"
                        )
                    )
                } else {
                    skippedCount += 1
                }
            } else {
                if !localTask.isTombstoned || localTask.syncState != .tombstoned {
                    localTask.isTombstoned = true
                    localTask.syncState = .tombstoned
                    localTask.conflictKind = nil
                    deletedCount += 1
                } else {
                    skippedCount += 1
                }
            }
        }

        return MergeOutcome(
            createdCount: createdCount,
            updatedCount: updatedCount,
            deletedCount: deletedCount,
            conflictCount: conflictCount,
            skippedCount: skippedCount,
            conflicts: conflicts
        )
    }
}
