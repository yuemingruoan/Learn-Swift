//
//  StudyPlanStore.swift
//  48-swiftdata-engineering-modeling-dto-persistence-and-domain-boundaries
//
//  Created by Codex on 2026/4/4.
//

import Foundation
import SwiftData

struct StudyPlanStore {
    let context: ModelContext

    func replaceStoredPlan(with dto: StudyPlanDTO, syncedAt: Date = .now) throws {
        let existingPlans = try context.fetch(FetchDescriptor<StudyPlanRecord>())
        for plan in existingPlans {
            context.delete(plan)
        }

        let record = StudyPlanMapper.makeRecord(from: dto, syncedAt: syncedAt)
        context.insert(record)
        try context.save()
    }

    func fetchStoredPlans() throws -> [StudyPlanRecord] {
        let descriptor = FetchDescriptor<StudyPlanRecord>(
            sortBy: [SortDescriptor(\StudyPlanRecord.publishedAt, order: .forward)]
        )
        return try context.fetch(descriptor)
    }

    func fetchDomainPlans() throws -> [StudyPlan] {
        try fetchStoredPlans().map(StudyPlanMapper.makeDomainPlan(from:))
    }
}
