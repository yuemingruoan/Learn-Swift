//
//  main.swift
//  27-protocol-extensions-and-default-implementations
//
//  Created by Codex on 2026/3/23.
//

func printDivider(title: String) {
    print("")
    print("======== \(title) ========")
}

protocol ProgressTrackable {
    var title: String { get }
    var completedSteps: Int { get }
    var totalSteps: Int { get }
}

extension ProgressTrackable {
    var isFinished: Bool {
        return completedSteps >= totalSteps
    }

    var progressRateText: String {
        if totalSteps == 0 {
            return "0%"
        }

        let rate = completedSteps * 100 / totalSteps
        return "\(rate)%"
    }

    func progressSummary() -> String {
        let status = isFinished ? "已完成" : "进行中"
        return "\(title) - \(completedSteps)/\(totalSteps) - \(progressRateText) - \(status)"
    }

    func nextSuggestion() -> String {
        if isFinished {
            return "可以进入下一项学习。"
        } else {
            return "继续完成剩余步骤。"
        }
    }
}

struct StudyTask: ProgressTrackable {
    let title: String
    let completedSteps: Int
    let totalSteps: Int
}

struct ChapterPlan: ProgressTrackable {
    let title: String
    let completedSteps: Int
    let totalSteps: Int
}

struct ReviewSession: ProgressTrackable {
    let title: String
    let completedSteps: Int
    let totalSteps: Int
}

func printProgressBoard(items: [ProgressTrackable]) {
    for item in items {
        print(item.progressSummary())
        print("建议：\(item.nextSuggestion())")
        print("---")
    }
}

let boardItems: [ProgressTrackable] = [
    StudyTask(title: "整理泛型示例", completedSteps: 2, totalSteps: 3),
    ChapterPlan(title: "第 27 章", completedSteps: 4, totalSteps: 4),
    ReviewSession(title: "复盘协议扩展", completedSteps: 1, totalSteps: 2),
]

printDivider(title: "协议定义共同要求")
for item in boardItems {
    print("标题：\(item.title)")
}

printDivider(title: "协议扩展补统一默认实现")
for item in boardItems {
    print(item.progressSummary())
}

printDivider(title: "完整功能：统一进度看板")
printProgressBoard(items: boardItems)

printDivider(title: "不同类型也能共享同一套默认行为")
print("说明：")
print("- StudyTask、ChapterPlan、ReviewSession 没有父子关系。")
print("- 但它们都遵守 ProgressTrackable。")
print("- 因此都能直接使用 progressSummary() 和 nextSuggestion()。")

printDivider(title: "这一章最想演示的差别")
print("说明：")
print("- 协议负责定义 title / completedSteps / totalSteps 这些要求。")
print("- 协议扩展负责提供共享的 isFinished、progressRateText 和 progressSummary()。")
print("- 这样新类型只要满足要求，就能立刻接入整个进度看板。")
