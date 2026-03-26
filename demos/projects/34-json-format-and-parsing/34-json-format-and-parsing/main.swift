//
//  main.swift
//  34-json-format-and-parsing
//
//  Created by Codex on 2026/3/26.
//

import Foundation

struct StudyTaskDTO: Decodable {
    let title: String
    let estimatedHours: Int
    let isFinished: Bool
}

struct StudyBoardDTO: Decodable {
    let boardTitle: String
    let owner: BoardOwnerDTO
    let tasks: [StudyTaskDTO]
}

struct BoardOwnerDTO: Decodable {
    let name: String
    let level: String
}

func printDivider(title: String) {
    print("")
    print("======== \(title) ========")
}

func makeData(from jsonText: String) -> Data {
    return jsonText.data(using: .utf8)!
}

func parseJSONObject(from data: Data) throws -> [String: Any] {
    let object = try JSONSerialization.jsonObject(with: data)

    guard let dictionary = object as? [String: Any] else {
        fatalError("示例 JSON 最外层不是对象")
    }

    return dictionary
}

func decodeTask(from data: Data) throws -> StudyTaskDTO {
    let decoder = JSONDecoder()
    return try decoder.decode(StudyTaskDTO.self, from: data)
}

func decodeTaskList(from data: Data) throws -> [StudyTaskDTO] {
    let decoder = JSONDecoder()
    return try decoder.decode([StudyTaskDTO].self, from: data)
}

func decodeBoard(from data: Data) throws -> StudyBoardDTO {
    let decoder = JSONDecoder()
    return try decoder.decode(StudyBoardDTO.self, from: data)
}

let singleTaskJSON = """
{
    "title": "复习闭包",
    "estimatedHours": 2,
    "isFinished": false
}
"""

let taskListJSON = """
[
    {
        "title": "复习闭包",
        "estimatedHours": 2,
        "isFinished": false
    },
    {
        "title": "学习 JSON",
        "estimatedHours": 1,
        "isFinished": true
    }
]
"""

let boardJSON = """
{
    "boardTitle": "今日学习看板",
    "owner": {
        "name": "Alice",
        "level": "beginner"
    },
    "tasks": [
        {
            "title": "复习闭包",
            "estimatedHours": 2,
            "isFinished": false
        },
        {
            "title": "整理并发笔记",
            "estimatedHours": 1,
            "isFinished": false
        },
        {
            "title": "完成 JSON 练习",
            "estimatedHours": 1,
            "isFinished": true
        }
    ]
}
"""

printDivider(title: "最小 JSON 结构示例")
print(singleTaskJSON)
print("说明：")
print("- 最外层是对象，所以用了 {}。")
print("- title、estimatedHours、isFinished 都是 key。")
print("- 每个 key 后面都对应一个 value。")

printDivider(title: "JSONSerialization：先看最原始结构")
let singleTaskData = makeData(from: singleTaskJSON)
let taskObject = try parseJSONObject(from: singleTaskData)
let isFinishedValue = taskObject["isFinished"] as? Bool ?? false
print("title -> \(taskObject["title"] ?? "")")
print("estimatedHours -> \(taskObject["estimatedHours"] ?? 0)")
print("isFinished -> \(isFinishedValue)")
print("说明：")
print("- jsonObject(with:) 先把 JSON 打开成通用结构。")
print("- as? [String: Any] 表示“尝试把结果当成字典”。")

printDivider(title: "JSONDecoder：直接解码成结构体")
let decodedTask = try decodeTask(from: singleTaskData)
print("title: \(decodedTask.title)")
print("estimatedHours: \(decodedTask.estimatedHours)")
print("isFinished: \(decodedTask.isFinished)")
print("说明：")
print("- decode(StudyTaskDTO.self, from: data) 的意思是：")
print("  把这段 Data 按 StudyTaskDTO 的结构解出来。")

printDivider(title: "数组根结构的最小示例")
let taskListData = makeData(from: taskListJSON)
let decodedTasks = try decodeTaskList(from: taskListData)
print("一共解析出 \(decodedTasks.count) 个任务。")
for task in decodedTasks {
    print("- \(task.title) / \(task.estimatedHours) 小时 / 已完成：\(task.isFinished)")
}
print("说明：")
print("- 如果 JSON 最外层是 []，decode 的目标类型也应该是数组。")
print("- 这里写成 [StudyTaskDTO].self。")

printDivider(title: "具体场景：学习看板配置")
let boardData = makeData(from: boardJSON)
let board = try decodeBoard(from: boardData)
let unfinishedCount = board.tasks.filter { task in
    task.isFinished == false
}.count

print("看板标题：\(board.boardTitle)")
print("负责人：\(board.owner.name) / \(board.owner.level)")
print("任务列表：")
for task in board.tasks {
    let status = task.isFinished ? "已完成" : "未完成"
    print("- \(task.title) / \(task.estimatedHours) 小时 / \(status)")
}
print("未完成任务数：\(unfinishedCount)")
print("说明：")
print("- boardTitle 对应字符串。")
print("- owner 对应嵌套对象。")
print("- tasks 对应“对象数组”。")
