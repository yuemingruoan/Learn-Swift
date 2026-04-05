//
//  SyncTypes.swift
//  49-swiftdata-sync-engineering-incremental-update-conflict-resolution-and-offline-consistency
//
//  Created by Codex on 2026/4/4.
//

import Foundation

enum SyncState: String, Codable {
    case synced
    case dirty
    case conflict
    case tombstoned
}

enum SyncConflictKind: String, Codable {
    case sharedFieldDiverged
    case deletedRemotelyWithPendingMutation
}

enum MutationKind: String, Codable {
    case setFinished
}

enum PendingMutationStatus: String, Codable {
    case queued
    case failed
    case applied
}

struct TaskMutationPayload: Codable {
    let mutationID: String
    let taskRemoteID: Int
    let kind: MutationKind
    let isFinished: Bool?
    let createdAt: Date
}

struct RejectedMutationResultDTO: Codable {
    let mutationID: String
    let reason: String
}

struct PushResultDTO: Codable {
    let appliedMutationIDs: [String]
    let rejectedMutations: [RejectedMutationResultDTO]
}

struct SyncConflict: Codable {
    let taskRemoteID: Int
    let kind: SyncConflictKind
    let message: String
}

struct SyncReport {
    let pushedMutationCount: Int
    let pulledCreatedCount: Int
    let pulledUpdatedCount: Int
    let pulledDeletedCount: Int
    let conflictCount: Int
    let skippedCount: Int
    let pendingMutationCountAfterSync: Int
    let conflicts: [SyncConflict]
}
