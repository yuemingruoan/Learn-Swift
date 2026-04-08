import StudyPlanCore

final class InMemoryStudyPlanRepository: StudyPlanRepository {
    private var plan = StudyPlan(
        title: "Swift 进阶学习计划",
        tasks: [
            StudyTask(id: 1, title: "复习协议与扩展", estimatedHours: 2, isFinished: true),
            StudyTask(id: 2, title: "阅读 Swift Testing 章节", estimatedHours: 3, isFinished: false),
            StudyTask(id: 3, title: "尝试拆出第一个 Swift Package", estimatedHours: 2, isFinished: false),
        ]
    )

    func loadPlan() throws -> StudyPlan {
        plan
    }

    func savePlan(_ plan: StudyPlan) throws {
        self.plan = plan
    }
}

let repository = InMemoryStudyPlanRepository()
let service = StudyPlanService(repository: repository)

let before = try service.loadPlan()
print("当前计划：\(before.title)")
print("总预估学时：\(before.totalEstimatedHours)")
print("未完成任务数：\(before.unfinishedTaskCount)")

let updated = try service.completeTask(id: 2)
print("完成任务后，未完成任务数：\(updated.unfinishedTaskCount)")
