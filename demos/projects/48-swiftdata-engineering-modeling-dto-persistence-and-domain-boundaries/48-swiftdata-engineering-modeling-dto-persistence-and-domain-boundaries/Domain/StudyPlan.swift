//
//  StudyPlan.swift
//  48-swiftdata-engineering-modeling-dto-persistence-and-domain-boundaries
//
//  Created by Codex on 2026/4/4.
//

import Foundation

struct StudyPlan {
    let title: String
    let ownerName: String
    let publishedAt: Date
    let tasks: [StudyTask]

    var unfinishedTaskCount: Int {
        tasks.filter { !$0.isFinished }.count
    }

    var totalEstimatedMinutes: Int {
        tasks.reduce(0) { $0 + $1.estimatedMinutes }
    }
}
