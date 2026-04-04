//
//  StudyTaskRecord.swift
//  48-swiftdata-engineering-modeling-dto-persistence-and-domain-boundaries
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
    var plan: StudyPlanRecord?

    init(
        remoteID: Int,
        title: String,
        estimatedMinutes: Int,
        isFinished: Bool,
        sortOrder: Int,
        plan: StudyPlanRecord? = nil
    ) {
        self.remoteID = remoteID
        self.title = title
        self.estimatedMinutes = estimatedMinutes
        self.isFinished = isFinished
        self.sortOrder = sortOrder
        self.plan = plan
    }
}
