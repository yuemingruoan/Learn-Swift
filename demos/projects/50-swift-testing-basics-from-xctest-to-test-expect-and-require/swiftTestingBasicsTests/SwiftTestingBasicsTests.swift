import Testing
@testable import swiftTestingBasics

struct SwiftTestingBasicsTests {
    private let sampleTasks = [
        StudyTask(title: "阅读第 50 章", estimatedMinutes: 20, isCompleted: true),
        StudyTask(title: "运行示例", estimatedMinutes: 30, isCompleted: false),
        StudyTask(title: "整理笔记", estimatedMinutes: 15, isCompleted: true),
    ]

    @Test("summary 会统计已完成数量、剩余数量和总时长")
    func summaryTracksCountsAndMinutes() {
        let summary = StudyProgress.summary(for: sampleTasks)

        #expect(summary.completedCount == 2)
        #expect(summary.remainingCount == 1)
        #expect(summary.totalMinutes == 65)
    }

    @Test("nextTask 会返回第一项未完成任务")
    func nextTaskReturnsFirstIncompleteTask() throws {
        let nextTask = try #require(StudyProgress.nextTask(in: sampleTasks))

        #expect(nextTask.title == "运行示例")
        #expect(nextTask.estimatedMinutes == 30)
    }

    @Test("当所有任务都已完成时，nextTask 返回 nil")
    func nextTaskReturnsNilWhenEverythingIsDone() {
        let completedTasks = sampleTasks.map { task in
            StudyTask(title: task.title, estimatedMinutes: task.estimatedMinutes, isCompleted: true)
        }

        #expect(StudyProgress.nextTask(in: completedTasks) == nil)
    }

    @Test("标题校验会过滤空白字符串")
    func titleValidationRejectsBlankTitles() {
        let invalidTasks = sampleTasks + [
            StudyTask(title: "   ", estimatedMinutes: 10, isCompleted: false),
        ]

        #expect(StudyProgress.allTaskTitlesAreValid(sampleTasks))
        #expect(!StudyProgress.allTaskTitlesAreValid(invalidTasks))
    }
}
