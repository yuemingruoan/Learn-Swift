//
//  StudyPlanDTO.swift
//  48-swiftdata-engineering-modeling-dto-persistence-and-domain-boundaries
//
//  Created by Codex on 2026/4/4.
//

import Foundation

struct StudyPlanDTO: Decodable {
    let planID: Int
    let planTitle: String
    let owner: OwnerDTO
    let publishedAt: Date
    let tasks: [StudyTaskDTO]

    enum CodingKeys: String, CodingKey {
        case planID = "plan_id"
        case planTitle = "plan_title"
        case owner
        case publishedAt = "published_at"
        case tasks
    }
}

struct OwnerDTO: Decodable {
    let displayName: String

    enum CodingKeys: String, CodingKey {
        case displayName = "display_name"
    }
}

struct StudyTaskDTO: Decodable {
    let taskID: Int
    let taskTitle: String
    let estimatedMinutes: Int
    let isFinished: Bool

    enum CodingKeys: String, CodingKey {
        case taskID = "task_id"
        case taskTitle = "task_title"
        case estimatedMinutes = "estimated_minutes"
        case isFinished = "is_finished"
    }
}
