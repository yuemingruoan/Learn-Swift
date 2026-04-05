//
//  ScriptedStudyPlanRemoteSource.swift
//  49-swiftdata-sync-engineering-incremental-update-conflict-resolution-and-offline-consistency
//
//  Created by Codex on 2026/4/4.
//

import Foundation

actor ScriptedStudyPlanRemoteSource: StudyPlanRemoteSource {
    private var snapshots: [RemoteStudyPlanSnapshotDTO]
    private var currentIndex: Int
    private var processedMutationIDs: Set<String>

    init(
        snapshots: [RemoteStudyPlanSnapshotDTO],
        currentIndex: Int = 0,
        processedMutationIDs: Set<String> = []
    ) {
        self.snapshots = snapshots
        self.currentIndex = currentIndex
        self.processedMutationIDs = processedMutationIDs
    }

    func fetchLatestPlan() async throws -> RemoteStudyPlanSnapshotDTO {
        snapshots[currentIndex]
    }

    func push(_ mutations: [TaskMutationPayload]) async throws -> PushResultDTO {
        var snapshot = snapshots[currentIndex]
        var applied: [String] = []
        var rejected: [RejectedMutationResultDTO] = []

        for mutation in mutations {
            if processedMutationIDs.contains(mutation.mutationID) {
                applied.append(mutation.mutationID)
                continue
            }

            guard let index = snapshot.tasks.firstIndex(where: { $0.remoteID == mutation.taskRemoteID }) else {
                rejected.append(
                    RejectedMutationResultDTO(
                        mutationID: mutation.mutationID,
                        reason: "remote_missing"
                    )
                )
                continue
            }

            switch mutation.kind {
            case .setFinished:
                snapshot.tasks[index].isFinished = mutation.isFinished ?? snapshot.tasks[index].isFinished
                snapshot.tasks[index].updatedAt = mutation.createdAt
            }

            applied.append(mutation.mutationID)
            processedMutationIDs.insert(mutation.mutationID)
        }

        snapshots[currentIndex] = snapshot
        return PushResultDTO(appliedMutationIDs: applied, rejectedMutations: rejected)
    }

    func advanceToNextSnapshot() {
        guard currentIndex + 1 < snapshots.count else { return }
        currentIndex += 1
    }

    func currentVersion() -> Int {
        snapshots[currentIndex].version
    }
}
