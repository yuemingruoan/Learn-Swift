//
//  main.swift
//  23-error-handling-clear-failure-paths-starter
//
//  Created by Codex on 2026/3/21.
//

import Foundation

func printDivider(title: String) {
    print("")
    print("======== \(title) ========")
}

// 这个版本已经能把一行文本解析成 StudyTask，也已经用上了错误处理。
// 当前问题：
// 1. 所有失败都被压成了同一个 invalidLine。
// 2. 调用方只能得到“格式不正确”，看不见更具体的失败原因。
// 3. 关于 try! 的使用场景，还没有被单独拿出来比较。
//
// 练习目标：
// - 保留当前代码骨架，不从零开始重写。
// - 把粗粒度错误改造成更清楚的错误类型。
// - 让 do-catch 能根据不同错误分别处理。
// - 思考哪些“写死且可信”的数据可以使用 try!。
//
// TODO 使用建议：
// - 先完成练习 1，再思考 try! 的使用场景。
// - 优先查看 StudyTaskParseError、parseFinishedFlag(_:)、parseStudyTask(from:)、
//   printParseResult(for:) 这几个位置的 TODO。

struct StudyTask {
    let title: String
    let estimatedHours: Int
    var isFinished: Bool
}

enum StudyTaskParseError: Error {
    // TODO(练习 1)：
    // 当前只有一个 invalidLine，信息过于粗糙。
    // 请把它改造成更具体的错误，例如：
    // - wrongFieldCount(expected:actual:)
    // - emptyTitle
    // - invalidEstimatedHours(text:)
    // - negativeEstimatedHours(Int)
    // - invalidFinishedFlag(text:)
    case invalidLine

    func userMessage() -> String {
        // TODO(练习 1)：
        // 当前所有错误都只返回“输入格式不正确”。
        // 当你把错误类型细化后，请在这里分别返回更明确的提示。
        return "输入格式不正确。"
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
        // TODO(练习 1)：
        // 这里目前统一抛出 invalidLine。
        // 当错误类型细化后，这里应抛出“完成状态不合法”之类的明确错误。
        throw StudyTaskParseError.invalidLine
    }
}

func parseStudyTask(from line: String) throws -> StudyTask {
    let parts = line
        .split(separator: ",", omittingEmptySubsequences: false)
        .map { String($0).trimmingCharacters(in: .whitespacesAndNewlines) }

    guard parts.count == 3 else {
        // TODO(练习 1)：
        // 这里目前只知道“这一行不对”。
        // 请改成能表达“字段数量不正确”的错误。
        throw StudyTaskParseError.invalidLine
    }

    let title = parts[0]
    let estimatedHoursText = parts[1]
    let finishedFlagText = parts[2]

    guard !title.isEmpty else {
        // TODO(练习 1)：
        // 请改成能表达“标题为空”的错误。
        throw StudyTaskParseError.invalidLine
    }

    guard let estimatedHours = Int(estimatedHoursText) else {
        // TODO(练习 1)：
        // 请改成能表达“时长不是整数”的错误，
        // 并尽量把原始输入一起保留下来。
        throw StudyTaskParseError.invalidLine
    }

    guard estimatedHours >= 0 else {
        // TODO(练习 1)：
        // 请改成能表达“时长为负数”的错误。
        throw StudyTaskParseError.invalidLine
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
    } catch {
        // 练习 1：
        // 当前这里只能统一处理错误。
        // 请在你把错误类型细化之后，把这里改成“按错误原因分别提示”。
        //
        // TODO(练习 1)：
        // 目标效果不是只有一个 catch，而是能根据不同错误分别输出提示。
        let error = error as? StudyTaskParseError ?? .invalidLine
        print("解析失败：\(error.userMessage())")
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
print("当前版本已经具备基本骨架，但错误类型还比较粗。")

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
    } catch {
        let error = error as? StudyTaskParseError ?? .invalidLine
        print("跳过这一行：\(error.userMessage())")
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
print("- 你可以思考：这种场景在什么前提下可以改写成 try!。")
print("- 但 invalidLines 这类不可靠输入，通常不适合使用 try!。")

// TODO(思考题)：
// 在不影响主流程演示的前提下，尝试单独新增一小段代码，比较下面两种写法：
//
// 写法一：
// do {
//     let task = try parseStudyTask(from: trustedDemoLine)
//     print(task)
// } catch {
//     print(error)
// }
//
// 写法二：
// let task = try! parseStudyTask(from: trustedDemoLine)
// print(task)
//
// 思考重点：
// 1. 为什么 trustedDemoLine 比用户输入更接近 try! 的使用场景？
// 2. try! 省掉了什么样板代码？
// 3. 如果你后来把 trustedDemoLine 改坏了，会发生什么？
