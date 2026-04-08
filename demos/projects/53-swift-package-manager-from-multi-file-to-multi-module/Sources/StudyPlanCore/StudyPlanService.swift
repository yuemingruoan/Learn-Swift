import Foundation

public enum StudyPlanServiceError: Error, Equatable {
    case taskNotFound(id: Int)
}

public struct StudyPlanService {
    private let repository: any StudyPlanRepository

    public init(repository: any StudyPlanRepository) {
        self.repository = repository
    }

    public func loadPlan() throws -> StudyPlan {
        try repository.loadPlan()
    }

    public func completeTask(id: Int) throws -> StudyPlan {
        var plan = try repository.loadPlan()

        guard plan.markTaskFinished(id: id) else {
            throw StudyPlanServiceError.taskNotFound(id: id)
        }

        try repository.savePlan(plan)
        return plan
    }
}
