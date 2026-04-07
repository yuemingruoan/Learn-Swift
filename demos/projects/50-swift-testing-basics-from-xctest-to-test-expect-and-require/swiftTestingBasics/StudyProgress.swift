import Foundation

struct StudyTask: Equatable {
    let title: String
    let estimatedMinutes: Int
    let isCompleted: Bool
}

struct StudySummary: Equatable {
    let completedCount: Int
    let remainingCount: Int
    let totalMinutes: Int
    let completionRate: Double
}

enum StudyProgress {
    static func summary(for tasks: [StudyTask]) -> StudySummary {
        let completedCount = tasks.filter(\.isCompleted).count
        let totalMinutes = tasks.reduce(0) { $0 + $1.estimatedMinutes }
        let completionRate = tasks.isEmpty ? 0 : Double(completedCount) / Double(tasks.count)

        return StudySummary(
            completedCount: completedCount,
            remainingCount: tasks.count - completedCount,
            totalMinutes: totalMinutes,
            completionRate: completionRate
        )
    }

    static func nextTask(in tasks: [StudyTask]) -> StudyTask? {
        tasks.first { !$0.isCompleted }
    }

    static func completionLabel(for summary: StudySummary) -> String {
        if summary.completedCount == 0 {
            return "刚刚开始"
        }

        if summary.remainingCount == 0 {
            return "已完成"
        }

        if summary.completionRate >= 0.5 {
            return "过半"
        }

        return "继续推进"
    }

    static func allTaskTitlesAreValid(_ tasks: [StudyTask]) -> Bool {
        tasks.allSatisfy { task in
            !task.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
    }
}
