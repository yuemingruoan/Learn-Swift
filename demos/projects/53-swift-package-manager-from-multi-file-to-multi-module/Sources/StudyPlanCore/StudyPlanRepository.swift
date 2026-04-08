import Foundation

public protocol StudyPlanRepository {
    func loadPlan() throws -> StudyPlan
    func savePlan(_ plan: StudyPlan) throws
}
