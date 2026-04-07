import SwiftUI

struct ContentView: View {
    private let sampleTasks = [
        StudyTask(title: "阅读第 50 章", estimatedMinutes: 20, isCompleted: true),
        StudyTask(title: "运行 Swift Testing demo", estimatedMinutes: 25, isCompleted: false),
        StudyTask(title: "整理测试笔记", estimatedMinutes: 15, isCompleted: true),
    ]

    var body: some View {
        let summary = StudyProgress.summary(for: sampleTasks)

        VStack(alignment: .leading, spacing: 12) {
            Text("Swift Testing 基础 Demo")
                .font(.title2)
                .fontWeight(.semibold)

            Text("已完成 \(summary.completedCount) / \(sampleTasks.count)")
            Text("总时长 \(summary.totalMinutes) 分钟")
            Text("进度标签：\(StudyProgress.completionLabel(for: summary))")

            if let nextTask = StudyProgress.nextTask(in: sampleTasks) {
                Text("下一项：\(nextTask.title)")
            } else {
                Text("当前没有未完成任务")
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}

#Preview {
    ContentView()
}
