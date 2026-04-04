//
//  StudyPlanRepository.swift
//  47-multi-file-project-organization-and-cross-file-collaboration
//
//  Created by Codex on 2026/4/4.
//

import Foundation

protocol StudyPlanRepository {
    func loadPlan() -> StudyPlan
    func savePlan(_ plan: StudyPlan)
}

struct InMemoryStudyPlanRepository: StudyPlanRepository {
    private final class Storage {
        var plan: StudyPlan

        init(plan: StudyPlan) {
            self.plan = plan
        }
    }

    private let storage: Storage

    init(seedPlan: StudyPlan) {
        self.storage = Storage(plan: seedPlan)
    }

    func loadPlan() -> StudyPlan {
        storage.plan
    }

    func savePlan(_ plan: StudyPlan) {
        storage.plan = plan
    }
}
