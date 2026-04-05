//
//  StudyPlan.swift
//  49-swiftdata-sync-engineering-incremental-update-conflict-resolution-and-offline-consistency
//
//  Created by Codex on 2026/4/4.
//

import Foundation

struct StudyPlan {
    let remoteID: Int
    let title: String
    let ownerName: String
    let publishedAt: Date
    let tasks: [StudyTask]

    var unfinishedTaskCount: Int {
        tasks.filter { !$0.isFinished }.count
    }

    var conflictTaskCount: Int {
        tasks.filter { $0.syncState == .conflict }.count
    }

    var localNoteCount: Int {
        tasks.filter { !$0.localNote.isEmpty }.count
    }

    var completionSummary: String {
        "\(tasks.count - unfinishedTaskCount)/\(tasks.count) 已完成"
    }
}
