//
//  StudyPlanService.swift
//  47-multi-file-project-organization-and-cross-file-collaboration
//
//  Created by Codex on 2026/4/4.
//

import Foundation

struct StudyPlanService {
    private let repository: StudyPlanRepository

    init(repository: StudyPlanRepository) {
        self.repository = repository
    }

    func loadPlan() -> StudyPlan {
        repository.loadPlan()
    }

    func finishTask(id: Int) -> StudyPlan? {
        var plan = repository.loadPlan()
        guard plan.markTaskFinished(id: id) else {
            return nil
        }

        repository.savePlan(plan)
        return plan
    }

    func unfinishedTaskCount() -> Int {
        repository.loadPlan().unfinishedTaskCount
    }
}
