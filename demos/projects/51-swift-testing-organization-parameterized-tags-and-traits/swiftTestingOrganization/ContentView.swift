import SwiftUI

struct ContentView: View {
    private let tasks = DemoFixtures.tasks

    var body: some View {
        let recommended = StudyPlanOrganizer.sorted(tasks, strategy: .recommended)

        VStack(alignment: .leading, spacing: 12) {
            Text("Swift Testing 组织与参数化 Demo")
                .font(.title2)
                .fontWeight(.semibold)

            Text("推荐排序后的第一项：\(recommended.first?.title ?? "无")")
            Text("今天需要复习的分桶：\(StudyPlanOrganizer.reviewBucket(for: 0).rawValue)")
            Text("包含 Swift 的任务数量：\(StudyPlanOrganizer.filter(tasks, searchText: "Swift", onlyIncomplete: false).count)")
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}

#Preview {
    ContentView()
}
