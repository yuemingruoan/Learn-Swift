//
//  StudyPlanSyncService.swift
//  49-swiftdata-sync-engineering-incremental-update-conflict-resolution-and-offline-consistency
//
//  Created by Codex on 2026/4/4.
//

import Foundation
import SwiftData

struct StudyPlanSyncService {
    let remote: StudyPlanRemoteSource
    let store: StudyPlanStore

    func markTaskFinished(taskRemoteID: Int, isFinished: Bool, changedAt: Date = .now) throws {
        guard let task = try store.taskRecord(remoteID: taskRemoteID) else {
            return
        }

        task.isFinished = isFinished
        task.lastLocalModifiedAt = changedAt
        task.syncState = .dirty
        task.conflictKind = nil

        let payload = TaskMutationPayload(
            mutationID: UUID().uuidString,
            taskRemoteID: taskRemoteID,
            kind: .setFinished,
            isFinished: isFinished,
            createdAt: changedAt
        )
        let pending = try PendingTaskMutationRecord.make(from: payload)
        store.context.insert(pending)
        try store.save()
    }

    func updateLocalNote(taskRemoteID: Int, note: String, changedAt: Date = .now) throws {
        guard let task = try store.taskRecord(remoteID: taskRemoteID) else {
            return
        }

        task.localNote = note
        task.lastLocalModifiedAt = changedAt
        try store.save()
    }

    func performSync() async throws -> SyncReport {
        var pushedMutationCount = 0
        let activeMutations = try store.fetchActivePendingMutationRecords()

        if !activeMutations.isEmpty {
            do {
                let payloads = try activeMutations.map { try $0.payload }
                let result = try await remote.push(payloads)
                let appliedIDs = Set(result.appliedMutationIDs)
                let rejectedReasons = Dictionary(
                    uniqueKeysWithValues: result.rejectedMutations.map { ($0.mutationID, $0.reason) }
                )

                for mutation in activeMutations {
                    mutation.lastAttemptAt = .now

                    if appliedIDs.contains(mutation.mutationID) {
                        mutation.status = .applied
                        pushedMutationCount += 1
                    } else if rejectedReasons[mutation.mutationID] != nil {
                        mutation.status = .failed
                        mutation.retryCount += 1
                    }
                }

                try store.save()
            } catch {
                for mutation in activeMutations {
                    mutation.lastAttemptAt = .now
                    mutation.retryCount += 1
                    mutation.status = .failed
                }
                try store.save()
                throw error
            }
        }

        let snapshot = try await remote.fetchLatestPlan()
        let merge = try StudyPlanMerger.merge(snapshot: snapshot, store: store, syncedAt: .now)
        try store.deleteAppliedMutations()
        try store.save()

        let pendingCount = try store.fetchActivePendingMutationRecords().count
        return SyncReport(
            pushedMutationCount: pushedMutationCount,
            pulledCreatedCount: merge.createdCount,
            pulledUpdatedCount: merge.updatedCount,
            pulledDeletedCount: merge.deletedCount,
            conflictCount: merge.conflictCount,
            skippedCount: merge.skippedCount,
            pendingMutationCountAfterSync: pendingCount,
            conflicts: merge.conflicts
        )
    }
}
