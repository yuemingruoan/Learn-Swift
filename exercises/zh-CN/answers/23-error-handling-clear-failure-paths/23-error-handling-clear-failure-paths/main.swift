//
//  main.swift
//  23-error-handling-clear-failure-paths
//
//  Created by Codex on 2026/3/21.
//

import Foundation

func printDivider(title: String) {
    print("")
    print("======== \(title) ========")
}

struct StudyTask {
    let title: String
    let estimatedHours: Int
    var isFinished: Bool
}

enum StudyTaskParseError: Error {
    case wrongFieldCount(expected: Int, actual: Int)
    case emptyTitle
    case invalidEstimatedHours(text: String)
    case negativeEstimatedHours(Int)
    case invalidFinishedFlag(text: String)

    func userMessage() -> String {
        switch self {
        case .wrongFieldCount(let expected, let actual):
            return "字段数量不对。期望 \(expected) 段，实际拿到 \(actual) 段。"
        case .emptyTitle:
            return "标题不能为空。"
        case .invalidEstimatedHours(let text):
            return "时长必须是整数，当前拿到的是：\(text)"
        case .negativeEstimatedHours(let value):
            return "时长不能是负数，当前拿到的是：\(value)"
        case .invalidFinishedFlag(let text):
            return "完成状态只能是 true 或 false，当前拿到的是：\(text)"
        }
    }
}

func parseFinishedFlag(_ text: String) throws -> Bool {
    let normalizedText = text.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

    switch normalizedText {
    case "true":
        return true
    case "false":
        return false
    default:
        throw StudyTaskParseError.invalidFinishedFlag(text: text)
    }
}

func parseStudyTask(from line: String) throws -> StudyTask {
    let parts = line
        .split(separator: ",", omittingEmptySubsequences: false)
        .map { String($0).trimmingCharacters(in: .whitespacesAndNewlines) }

    guard parts.count == 3 else {
        throw StudyTaskParseError.wrongFieldCount(expected: 3, actual: parts.count)
    }

    let title = parts[0]
    let estimatedHoursText = parts[1]
    let finishedFlagText = parts[2]

    guard !title.isEmpty else {
        throw StudyTaskParseError.emptyTitle
    }

    guard let estimatedHours = Int(estimatedHoursText) else {
        throw StudyTaskParseError.invalidEstimatedHours(text: estimatedHoursText)
    }

    guard estimatedHours >= 0 else {
        throw StudyTaskParseError.negativeEstimatedHours(estimatedHours)
    }

    let isFinished = try parseFinishedFlag(finishedFlagText)

    return StudyTask(title: title, estimatedHours: estimatedHours, isFinished: isFinished)
}

func summaryLine(for task: StudyTask) -> String {
    let status = task.isFinished ? "已完成" : "未完成"
    return "\(task.title) - \(task.estimatedHours) 小时 - \(status)"
}

func printParseResult(for line: String) {
    print("输入：\(line)")

    do {
        let task = try parseStudyTask(from: line)
        print("解析成功：\(summaryLine(for: task))")
    } catch let error as StudyTaskParseError {
        print("解析失败：\(error.userMessage())")
    } catch {
        print("解析失败：出现了未预期的错误 \(error)")
    }
}

let trustedDemoLine = "阅读错误处理章节,2,false"
let invalidLines = [
    "只剩两个字段,1",
    "   ,1,true",
    "完成本章 demo,两小时,false",
    "整理笔记,-2,true",
    "复盘 throwing 函数,2,done",
]

printDivider(title: "当前版本已经能解析 StudyTask")
print("参考答案版本已经把失败原因细化为多个明确错误。")

printDivider(title: "成功输入")
printParseResult(for: trustedDemoLine)

printDivider(title: "失败输入目前都会落入同一类错误")
for line in invalidLines {
    printParseResult(for: line)
    print("---")
}

printDivider(title: "当前批量导入流程还看不见细粒度失败原因")
for line in [trustedDemoLine] + invalidLines {
    do {
        let task = try parseStudyTask(from: line)
        print("收录任务：\(task.title)")
    } catch let error as StudyTaskParseError {
        print("跳过这一行：\(error.userMessage())")
    } catch {
        print("跳过这一行：出现了未预期的错误 \(error)")
    }
}

printDivider(title: "try? 会把失败折叠成 nil")
let quickResult = try? parseStudyTask(from: "补看第 23 章,3,true")
let quickFailure = try? parseStudyTask(from: "只有标题,")
print("quickResult 是否成功：\(quickResult != nil)")
print("quickFailure 是否成功：\(quickFailure != nil)")

printDivider(title: "思考题请比较 do-catch 和 try!")
print("说明：")
print("- trustedDemoLine 是写死在程序里的可信示例数据。")
print("- 在当前前提下，它可以作为 try! 的候选场景。")
print("- 但 invalidLines 这类不可靠输入，通常不适合使用 try!。")

printDivider(title: "do-catch 和 try! 的对照")
do {
    let task = try parseStudyTask(from: trustedDemoLine)
    print("do-catch 写法：\(summaryLine(for: task))")
} catch {
    print("这里理论上不应失败：\(error)")
}

let trustedTask = try! parseStudyTask(from: trustedDemoLine)
print("try! 写法：\(summaryLine(for: trustedTask))")
print("说明：")
print("- 这里之所以可以使用 try!，是因为 trustedDemoLine 由当前代码写死并控制。")
print("- 如果这条数据后来被改坏，程序会在运行时直接失败。")
