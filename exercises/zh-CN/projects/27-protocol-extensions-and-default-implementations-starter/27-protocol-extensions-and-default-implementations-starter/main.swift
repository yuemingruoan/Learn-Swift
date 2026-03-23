//
//  main.swift
//  27-protocol-extensions-and-default-implementations-starter
//
//  Created by Codex on 2026/3/23.
//

func printDivider(title: String) {
    print("")
    print("======== \(title) ========")
}

// 这个 starter project 当前最大的问题是：
// 1. 多种进度对象都在各写各的完成判断。
// 2. 百分比文本、摘要文本、建议文案高度重复。
// 3. 这些逻辑本来属于“所有进度对象共享的能力”，但现在完全散落在具体类型里。
//
// 练习目标：
// - 提炼出共同协议。
// - 把真正通用的逻辑放进协议扩展。
// - 保留那些只属于具体类型自己的部分。

struct StudyTask {
    let title: String
    let completedSteps: Int
    let totalSteps: Int

    var isFinished: Bool {
        return completedSteps >= totalSteps
    }

    var progressRateText: String {
        if totalSteps == 0 {
            return "0%"
        }

        return "\(completedSteps * 100 / totalSteps)%"
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

struct ChapterPlan {
    let title: String
    let completedSteps: Int
    let totalSteps: Int

    var isFinished: Bool {
        return completedSteps >= totalSteps
    }

    var progressRateText: String {
        if totalSteps == 0 {
            return "0%"
        }

        return "\(completedSteps * 100 / totalSteps)%"
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

struct ReviewSession {
    let title: String
    let completedSteps: Int
    let totalSteps: Int

    var isFinished: Bool {
        return completedSteps >= totalSteps
    }

    var progressRateText: String {
        if totalSteps == 0 {
            return "0%"
        }

        return "\(completedSteps * 100 / totalSteps)%"
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

let task = StudyTask(title: "整理泛型示例", completedSteps: 2, totalSteps: 3)
let chapter = ChapterPlan(title: "第 27 章", completedSteps: 4, totalSteps: 4)
let review = ReviewSession(title: "复盘协议扩展", completedSteps: 1, totalSteps: 2)

printDivider(title: "当前项目能输出进度")
print(task.progressSummary())
print(chapter.progressSummary())
print(review.progressSummary())

printDivider(title: "当前项目也重复了很多逻辑")
print(task.nextSuggestion())
print(chapter.nextSuggestion())
print(review.nextSuggestion())

printDivider(title: "TODO")
print("请把这些共享行为从具体类型里收拢到协议和协议扩展中。")
