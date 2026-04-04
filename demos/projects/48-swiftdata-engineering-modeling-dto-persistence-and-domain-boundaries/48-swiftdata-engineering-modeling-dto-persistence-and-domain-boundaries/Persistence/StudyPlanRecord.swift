//
//  StudyPlanRecord.swift
//  48-swiftdata-engineering-modeling-dto-persistence-and-domain-boundaries
//
//  Created by Codex on 2026/4/4.
//

import Foundation
import SwiftData

@Model
final class StudyPlanRecord {
    var remoteID: Int
    var title: String
    var ownerName: String
    var publishedAt: Date
    var syncedAt: Date

    @Relationship(deleteRule: .cascade, inverse: \StudyTaskRecord.plan)
    var tasks: [StudyTaskRecord] = []

    init(
        remoteID: Int,
        title: String,
        ownerName: String,
        publishedAt: Date,
        syncedAt: Date
    ) {
        self.remoteID = remoteID
        self.title = title
        self.ownerName = ownerName
        self.publishedAt = publishedAt
        self.syncedAt = syncedAt
    }
}
