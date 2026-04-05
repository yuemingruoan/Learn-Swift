//
//  PendingTaskMutationRecord.swift
//  49-swiftdata-sync-engineering-incremental-update-conflict-resolution-and-offline-consistency
//
//  Created by Codex on 2026/4/4.
//

import Foundation
import SwiftData

@Model
final class PendingTaskMutationRecord {
    var mutationID: String
    var taskRemoteID: Int
    var kindRaw: String
    var payloadJSON: String
    var createdAt: Date
    var retryCount: Int
    var lastAttemptAt: Date?
    var statusRaw: String

    init(
        mutationID: String,
        taskRemoteID: Int,
        kind: MutationKind,
        payloadJSON: String,
        createdAt: Date,
        retryCount: Int = 0,
        lastAttemptAt: Date? = nil,
        status: PendingMutationStatus = .queued
    ) {
        self.mutationID = mutationID
        self.taskRemoteID = taskRemoteID
        self.kindRaw = kind.rawValue
        self.payloadJSON = payloadJSON
        self.createdAt = createdAt
        self.retryCount = retryCount
        self.lastAttemptAt = lastAttemptAt
        self.statusRaw = status.rawValue
    }
}

extension PendingTaskMutationRecord {
    var kind: MutationKind {
        MutationKind(rawValue: kindRaw) ?? .setFinished
    }

    var status: PendingMutationStatus {
        get { PendingMutationStatus(rawValue: statusRaw) ?? .queued }
        set { statusRaw = newValue.rawValue }
    }

    var payload: TaskMutationPayload {
        get throws {
            let data = Data(payloadJSON.utf8)
            return try JSONDecoder().decode(TaskMutationPayload.self, from: data)
        }
    }

    static func make(from payload: TaskMutationPayload) throws -> PendingTaskMutationRecord {
        let data = try JSONEncoder().encode(payload)
        guard let json = String(data: data, encoding: .utf8) else {
            throw NSError(domain: "PendingTaskMutationRecord", code: 1)
        }

        return PendingTaskMutationRecord(
            mutationID: payload.mutationID,
            taskRemoteID: payload.taskRemoteID,
            kind: payload.kind,
            payloadJSON: json,
            createdAt: payload.createdAt
        )
    }
}
