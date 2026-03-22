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

let validLine = "阅读错误处理章节,2,false"
let invalidLines = [
    "只剩两个字段,1",
    "   ,1,true",
    "完成本章 demo,两小时,false",
    "整理笔记,-2,true",
    "复盘 throwing 函数,2,done",
]

printDivider(title: "错误处理让失败原因单独建模")
print("我们希望把一行文本解析成 StudyTask：标题,时长,完成状态")

printDivider(title: "成功路径返回正常结果")
printParseResult(for: validLine)

printDivider(title: "do-catch 根据错误原因分别处理")
for line in invalidLines {
    printParseResult(for: line)
    print("---")
}

printDivider(title: "同一个 throwing 函数可以被不同调用方复用")
for line in [validLine] + invalidLines {
    do {
        let task = try parseStudyTask(from: line)
        print("收录任务：\(task.title)")
    } catch let error as StudyTaskParseError {
        print("跳过这一行：\(error.userMessage())")
    }
}

printDivider(title: "try? 会把失败折叠成 nil")
let quickResult = try? parseStudyTask(from: "补看第 23 章,3,true")
let quickFailure = try? parseStudyTask(from: "只有标题,")
print("quickResult 是否成功：\(quickResult != nil)")
print("quickFailure 是否成功：\(quickFailure != nil)")

printDivider(title: "错误处理不是为了让代码更花哨")
print("说明：")
print("- parseStudyTask(from:) 只负责解析，并在失败时抛出明确原因。")
print("- 调用方决定是提示用户、跳过该行，还是把失败转成 nil。")
print("- 这样成功路径和失败路径都会比“统一打印输入无效”更清楚。")
