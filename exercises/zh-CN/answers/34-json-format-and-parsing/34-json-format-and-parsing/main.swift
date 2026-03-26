//
//  main.swift
//  34-json-format-and-parsing
//
//  Created by Codex on 2026/3/26.
//

import Foundation

func printDivider(title: String) {
    print("")
    print("======== \(title) ========")
}

func makeData(from jsonText: String) -> Data {
    return jsonText.data(using: .utf8)!
}

struct StudyTaskDTO: Decodable {
    let title: String
    let estimatedHours: Int
    let isFinished: Bool
}

struct ChapterNoteDTO: Decodable {
    let chapterNumber: Int
    let title: String
    let tags: [String]
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

let singleTaskJSON = """
{
    "title": "复习闭包",
    "estimatedHours": 2,
    "isFinished": false
}
"""

let chapterListJSON = """
[
    {
        "chapterNumber": 24,
        "title": "泛型：让同一套逻辑适配更多类型",
        "tags": ["泛型", "复用", "约束"]
    },
    {
        "chapterNumber": 25,
        "title": "闭包：把函数当成值来传递",
        "tags": ["闭包", "排序", "回调"]
    },
    {
        "chapterNumber": 34,
        "title": "JSON 格式与解析",
        "tags": ["JSON", "Data", "解码"]
    }
]
"""

let boardJSON = """
{
    "boardTitle": "周末复习看板",
    "owner": {
        "name": "Alice",
        "level": "beginner"
    },
    "tasks": [
        {
            "title": "整理 JSON 笔记",
            "estimatedHours": 1,
            "isFinished": true
        },
        {
            "title": "练习数组根结构解码",
            "estimatedHours": 2,
            "isFinished": false
        },
        {
            "title": "复习嵌套对象解析",
            "estimatedHours": 1,
            "isFinished": false
        }
    ]
}
"""

func decodeTask(from data: Data) throws -> StudyTaskDTO {
    let decoder = JSONDecoder()
    return try decoder.decode(StudyTaskDTO.self, from: data)
}

func decodeChapterNotes(from data: Data) throws -> [ChapterNoteDTO] {
    let decoder = JSONDecoder()
    return try decoder.decode([ChapterNoteDTO].self, from: data)
}

func decodeBoard(from data: Data) throws -> StudyBoardDTO {
    let decoder = JSONDecoder()
    return try decoder.decode(StudyBoardDTO.self, from: data)
}

func printSingleTaskResult() throws {
    printDivider(title: "练习 1：单个对象")
    let data = makeData(from: singleTaskJSON)
    let task = try decodeTask(from: data)
    print("标题：\(task.title)")
    print("预计小时数：\(task.estimatedHours)")
    print("完成状态：\(task.isFinished)")
}

func printChapterListResult() throws {
    printDivider(title: "练习 2：数组根结构")
    let data = makeData(from: chapterListJSON)
    let notes = try decodeChapterNotes(from: data)

    for note in notes {
        print("第 \(note.chapterNumber) 章：\(note.title)")
        print("标签：\(note.tags.joined(separator: " / "))")
    }
}

func printBoardResult() throws {
    printDivider(title: "练习 3：嵌套对象与对象数组")
    let data = makeData(from: boardJSON)
    let board = try decodeBoard(from: data)

    print("看板标题：\(board.boardTitle)")
    print("负责人：\(board.owner.name) / \(board.owner.level)")

    for task in board.tasks {
        let status = task.isFinished ? "已完成" : "未完成"
        print("- \(task.title) / \(task.estimatedHours) 小时 / \(status)")
    }
}

do {
    try printSingleTaskResult()
    try printChapterListResult()
    try printBoardResult()
} catch {
    print("解析失败：\(error)")
}
