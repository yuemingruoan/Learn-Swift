import Testing
@testable import StudyPlanCore

private final class InMemoryRepository: StudyPlanRepository {
    var plan: StudyPlan
    var saveCallCount = 0

    init(plan: StudyPlan) {
        self.plan = plan
    }

    func loadPlan() throws -> StudyPlan {
        plan
    }

    func savePlan(_ plan: StudyPlan) throws {
        self.plan = plan
        saveCallCount += 1
    }
}

@Test("完成已有任务时会保存更新后的计划")
func completeTaskUpdatesAndPersistsPlan() throws {
    let repository = InMemoryRepository(
        plan: StudyPlan(
            title: "Swift 进阶学习计划",
            tasks: [
                StudyTask(id: 1, title: "协议", estimatedHours: 2, isFinished: false),
                StudyTask(id: 2, title: "SPM", estimatedHours: 2, isFinished: false),
            ]
        )
    )
    let service = StudyPlanService(repository: repository)

    let updated = try service.completeTask(id: 2)

    #expect(updated.unfinishedTaskCount == 1)
    #expect(repository.plan.tasks.last?.isFinished == true)
    #expect(repository.saveCallCount == 1)
}

@Test("完成不存在的任务时会抛出业务错误")
func completeTaskThrowsWhenTaskDoesNotExist() throws {
    let repository = InMemoryRepository(
        plan: StudyPlan(
            title: "Swift 进阶学习计划",
            tasks: [
                StudyTask(id: 1, title: "协议", estimatedHours: 2, isFinished: false),
            ]
        )
    )
    let service = StudyPlanService(repository: repository)

    do {
        _ = try service.completeTask(id: 99)
        Issue.record("预期应该抛出 taskNotFound 错误")
    } catch let error as StudyPlanServiceError {
        #expect(error == .taskNotFound(id: 99))
        #expect(repository.saveCallCount == 0)
    } catch {
        Issue.record("抛出了不符合预期的错误：\(error)")
    }
}
