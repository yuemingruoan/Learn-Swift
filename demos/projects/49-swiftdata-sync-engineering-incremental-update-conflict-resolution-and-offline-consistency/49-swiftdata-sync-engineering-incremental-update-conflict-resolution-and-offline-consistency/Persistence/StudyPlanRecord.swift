//
//  StudyPlanRecord.swift
//  49-swiftdata-sync-engineering-incremental-update-conflict-resolution-and-offline-consistency
//
//  Created by Codex on 2026/4/4.
//

import Foundation
import SwiftData

@Model
final class StudyPlanRecord {
    var remoteID: Int
    var remoteVersion: Int
    var title: String
    var ownerName: String
    var publishedAt: Date
    var lastSyncedAt: Date

    @Relationship(deleteRule: .cascade, inverse: \StudyTaskRecord.plan)
    var tasks: [StudyTaskRecord] = []

    init(
        remoteID: Int,
        remoteVersion: Int,
        title: String,
        ownerName: String,
        publishedAt: Date,
        lastSyncedAt: Date
    ) {
        self.remoteID = remoteID
        self.remoteVersion = remoteVersion
        self.title = title
        self.ownerName = ownerName
        self.publishedAt = publishedAt
        self.lastSyncedAt = lastSyncedAt
    }
}
