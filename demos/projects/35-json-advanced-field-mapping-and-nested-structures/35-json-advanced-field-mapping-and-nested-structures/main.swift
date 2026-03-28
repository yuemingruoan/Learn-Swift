//
//  main.swift
//  35-json-advanced-field-mapping-and-nested-structures
//
//  Created by Codex on 2026/3/28.
//

import Foundation

struct StudyTaskDTO: Decodable {
    let taskTitle: String
    let estimatedHours: Int
    let note: String?
    let isFinished: Bool
    let tags: [String]

    enum CodingKeys: String, CodingKey {
        case taskTitle = "task_title"
        case estimatedHours = "estimated_hours"
        case note
        case isFinished = "is_finished"
        case tags
    }

    // 这里故意展示第 35 章的两个重点：
    // 1. 用 CodingKeys 处理字段映射
    // 2. 用 decodeIfPresent + 默认值处理缺字段
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        taskTitle = try container.decode(String.self, forKey: .taskTitle)
        estimatedHours = try container.decode(Int.self, forKey: .estimatedHours)
        note = try container.decodeIfPresent(String.self, forKey: .note)
        isFinished = try container.decodeIfPresent(Bool.self, forKey: .isFinished) ?? false
        tags = try container.decodeIfPresent([String].self, forKey: .tags) ?? []
    }
}

struct BoardOwnerDTO: Decodable {
    let name: String
    let level: String
}

struct StudyBoardDTO: Decodable {
    let boardTitle: String
    let owner: BoardOwnerDTO
    let tasks: [StudyTaskDTO]

    enum CodingKeys: String, CodingKey {
        case boardTitle = "board_title"
        case owner
        case tasks
    }
}

// 响应包装类型专门对应最外层 message + data 结构，
// 用来强调“decode 的目标类型要和 JSON 根结构一致”。
struct StudyBoardResponseDTO: Decodable {
    let message: String
    let data: StudyBoardDTO
}

func printDivider(title: String) {
    print("")
    print("======== \(title) ========")
}

func makeData(from jsonText: String) -> Data {
    return jsonText.data(using: .utf8)!
}

func decodeTask(from data: Data) throws -> StudyTaskDTO {
    let decoder = JSONDecoder()
    return try decoder.decode(StudyTaskDTO.self, from: data)
}

func decodeBoardResponse(from data: Data) throws -> StudyBoardResponseDTO {
    let decoder = JSONDecoder()
    return try decoder.decode(StudyBoardResponseDTO.self, from: data)
}

func printTaskSummary(_ task: StudyTaskDTO) {
    let status = task.isFinished ? "已完成" : "未完成"
    let noteText = task.note ?? "无"
    let tagsText = task.tags.isEmpty ? "无标签" : task.tags.joined(separator: " / ")

    print("标题：\(task.taskTitle)")
    print("预计小时数：\(task.estimatedHours)")
    print("备注：\(noteText)")
    print("完成状态：\(status)")
    print("标签：\(tagsText)")
}

let mappedTaskJSON = """
{
    "task_title": "复习闭包",
    "estimated_hours": 2,
    "note": "重点观察参数和返回值的关系",
    "is_finished": false,
    "tags": ["closure", "review"]
}
"""

let minimalTaskJSON = """
{
    "task_title": "整理 JSON 笔记",
    "estimated_hours": 1
}
"""

let wrappedBoardJSON = """
{
    "message": "success",
    "data": {
        "board_title": "周末复习看板",
        "owner": {
            "name": "Alice",
            "level": "beginner"
        },
        "tasks": [
            {
                "task_title": "复习闭包",
                "estimated_hours": 2,
                "tags": ["closure", "review"]
            },
            {
                "task_title": "整理 JSON 笔记",
                "estimated_hours": 1,
                "note": "补充 CodingKeys 示例",
                "is_finished": true
            },
            {
                "task_title": "练习嵌套对象解码",
                "estimated_hours": 1,
                "is_finished": false,
                "tags": ["json", "nested"]
            }
        ]
    }
}
"""

// 这一段演示 snake_case -> camelCase 的字段映射。
printDivider(title: "字段映射：CodingKeys")
let mappedTask = try decodeTask(from: makeData(from: mappedTaskJSON))
printTaskSummary(mappedTask)

// 这一段演示字段缺失时的两种处理方式：
// note 用 Optional 保留“可能没有”的语义，
// isFinished 和 tags 则用默认值兜底。
printDivider(title: "缺字段与默认值")
let minimalTask = try decodeTask(from: makeData(from: minimalTaskJSON))
printTaskSummary(minimalTask)

// 这一段把三个概念放到同一个例子里：
// 1. 最外层响应包装
// 2. owner 这样的嵌套对象
// 3. tasks 这样的对象数组
printDivider(title: "外层包装与嵌套结构")
let response = try decodeBoardResponse(from: makeData(from: wrappedBoardJSON))
let board = response.data
print("响应消息：\(response.message)")
print("看板标题：\(board.boardTitle)")
print("负责人：\(board.owner.name) / \(board.owner.level)")
print("任务列表：")
for task in board.tasks {
    let status = task.isFinished ? "已完成" : "未完成"
    let noteText = task.note ?? "无备注"
    let tagsText = task.tags.isEmpty ? "无标签" : task.tags.joined(separator: " / ")
    print("- \(task.taskTitle) / \(task.estimatedHours) 小时 / \(status)")
    print("  备注：\(noteText)")
    print("  标签：\(tagsText)")
}
