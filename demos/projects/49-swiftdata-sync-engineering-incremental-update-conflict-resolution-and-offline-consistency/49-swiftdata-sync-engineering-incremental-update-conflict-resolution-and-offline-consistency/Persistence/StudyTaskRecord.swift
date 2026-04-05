//
//  StudyTaskRecord.swift
//  49-swiftdata-sync-engineering-incremental-update-conflict-resolution-and-offline-consistency
//
//  Created by Codex on 2026/4/4.
//

import Foundation
import SwiftData

@Model
final class StudyTaskRecord {
    var remoteID: Int
    var title: String
    var estimatedMinutes: Int
    var isFinished: Bool
    var sortOrder: Int
    var lastRemoteUpdatedAt: Date
    var lastLocalModifiedAt: Date?
    var syncStateRaw: String
    var localNote: String
    var isTombstoned: Bool
    var conflictKindRaw: String?
    var plan: StudyPlanRecord?

    init(
        remoteID: Int,
        title: String,
        estimatedMinutes: Int,
        isFinished: Bool,
        sortOrder: Int,
        lastRemoteUpdatedAt: Date,
        lastLocalModifiedAt: Date? = nil,
        syncState: SyncState = .synced,
        localNote: String = "",
        isTombstoned: Bool = false,
        conflictKind: SyncConflictKind? = nil,
        plan: StudyPlanRecord? = nil
    ) {
        self.remoteID = remoteID
        self.title = title
        self.estimatedMinutes = estimatedMinutes
        self.isFinished = isFinished
        self.sortOrder = sortOrder
        self.lastRemoteUpdatedAt = lastRemoteUpdatedAt
        self.lastLocalModifiedAt = lastLocalModifiedAt
        self.syncStateRaw = syncState.rawValue
        self.localNote = localNote
        self.isTombstoned = isTombstoned
        self.conflictKindRaw = conflictKind?.rawValue
        self.plan = plan
    }
}

extension StudyTaskRecord {
    var syncState: SyncState {
        get { SyncState(rawValue: syncStateRaw) ?? .synced }
        set { syncStateRaw = newValue.rawValue }
    }

    var conflictKind: SyncConflictKind? {
        get { conflictKindRaw.flatMap(SyncConflictKind.init(rawValue:)) }
        set { conflictKindRaw = newValue?.rawValue }
    }

    var visibleInDomain: Bool {
        !isTombstoned || syncState == .conflict
    }
}
