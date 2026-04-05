//
//  StudyTask.swift
//  49-swiftdata-sync-engineering-incremental-update-conflict-resolution-and-offline-consistency
//
//  Created by Codex on 2026/4/4.
//

import Foundation

struct StudyTask {
    let remoteID: Int
    let title: String
    let estimatedMinutes: Int
    let isFinished: Bool
    let localNote: String
    let syncState: SyncState
    let conflictHint: String?
}
