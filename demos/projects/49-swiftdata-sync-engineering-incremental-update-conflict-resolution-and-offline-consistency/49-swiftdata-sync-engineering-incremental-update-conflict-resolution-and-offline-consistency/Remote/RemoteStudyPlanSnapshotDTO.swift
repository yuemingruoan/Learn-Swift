//
//  RemoteStudyPlanSnapshotDTO.swift
//  49-swiftdata-sync-engineering-incremental-update-conflict-resolution-and-offline-consistency
//
//  Created by Codex on 2026/4/4.
//

import Foundation

struct RemoteStudyPlanSnapshotDTO: Codable {
    let version: Int
    let planID: Int
    let planTitle: String
    let ownerName: String
    let publishedAt: Date
    var tasks: [RemoteStudyTaskDTO]
}

struct RemoteStudyTaskDTO: Codable {
    let remoteID: Int
    var title: String
    var estimatedMinutes: Int
    var isFinished: Bool
    var sortOrder: Int
    var updatedAt: Date
}

protocol StudyPlanRemoteSource {
    func fetchLatestPlan() async throws -> RemoteStudyPlanSnapshotDTO
    func push(_ mutations: [TaskMutationPayload]) async throws -> PushResultDTO
}
