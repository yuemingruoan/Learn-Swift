//
//  StudyPlanMapper.swift
//  48-swiftdata-engineering-modeling-dto-persistence-and-domain-boundaries
//
//  Created by Codex on 2026/4/4.
//

import Foundation

enum StudyPlanMapper {
    static func makeRecord(from dto: StudyPlanDTO, syncedAt: Date = .now) -> StudyPlanRecord {
        let record = StudyPlanRecord(
            remoteID: dto.planID,
            title: dto.planTitle,
            ownerName: dto.owner.displayName,
            publishedAt: dto.publishedAt,
            syncedAt: syncedAt
        )

        record.tasks = dto.tasks.enumerated().map { index, taskDTO in
            StudyTaskRecord(
                remoteID: taskDTO.taskID,
                title: taskDTO.taskTitle,
                estimatedMinutes: taskDTO.estimatedMinutes,
                isFinished: taskDTO.isFinished,
                sortOrder: index,
                plan: record
            )
        }

        return record
    }

    static func makeDomainPlan(from record: StudyPlanRecord) -> StudyPlan {
        let tasks = record.tasks
            .sorted(by: { $0.sortOrder < $1.sortOrder })
            .map(makeDomainTask(from:))

        return StudyPlan(
            title: record.title,
            ownerName: record.ownerName,
            publishedAt: record.publishedAt,
            tasks: tasks
        )
    }

    static func makeDomainTask(from record: StudyTaskRecord) -> StudyTask {
        StudyTask(
            title: record.title,
            estimatedMinutes: record.estimatedMinutes,
            isFinished: record.isFinished
        )
    }
}
