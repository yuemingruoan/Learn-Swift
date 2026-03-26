//
//  main.swift
//  34-json-format-and-parsing-starter
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

// 这道题的重点不是“把 JSON 原文背下来”，
// 而是练习把三种常见结构真正解码出来：
// 1. 单个对象
// 2. 数组根结构
// 3. 嵌套对象 + 对象数组
//
// 请按 TODO 完成：
// 1. 在 decodeTask(from:) 里把 Data 解成 StudyTaskDTO。
// 2. 在 decodeChapterNotes(from:) 里把 Data 解成 [ChapterNoteDTO]。
// 3. 在 decodeBoard(from:) 里把 Data 解成 StudyBoardDTO。
// 4. 在 printSingleTaskResult() 里按字段输出单个任务。
// 5. 在 printChapterListResult() 里逐项输出每条章节笔记。
// 6. 在 printBoardResult() 里输出看板标题、负责人和每一条任务。
//
// 这道题不要自由发挥输出格式，请尽量对齐下面这份目标输出：
//
// ======== 练习 1：单个对象 ========
// 标题：复习闭包
// 预计小时数：2
// 完成状态：false
//
// ======== 练习 2：数组根结构 ========
// 第 24 章：泛型：让同一套逻辑适配更多类型
// 标签：泛型 / 复用 / 约束
// 第 25 章：闭包：把函数当成值来传递
// 标签：闭包 / 排序 / 回调
// 第 34 章：JSON 格式与解析
// 标签：JSON / Data / 解码
//
// ======== 练习 3：嵌套对象与对象数组 ========
// 看板标题：周末复习看板
// 负责人：Alice / beginner
// - 整理 JSON 笔记 / 1 小时 / 已完成
// - 练习数组根结构解码 / 2 小时 / 未完成
// - 复习嵌套对象解析 / 1 小时 / 未完成

func decodeTask(from data: Data) throws -> StudyTaskDTO {
    // TODO 1：
    // 请改成 JSONDecoder().decode(StudyTaskDTO.self, from: data)
    return StudyTaskDTO(title: "TODO", estimatedHours: 0, isFinished: false)
}

func decodeChapterNotes(from data: Data) throws -> [ChapterNoteDTO] {
    // TODO 2：
    // 请改成 JSONDecoder().decode([ChapterNoteDTO].self, from: data)
    return []
}

func decodeBoard(from data: Data) throws -> StudyBoardDTO {
    // TODO 3：
    // 请改成 JSONDecoder().decode(StudyBoardDTO.self, from: data)
    return StudyBoardDTO(
        boardTitle: "TODO",
        owner: BoardOwnerDTO(name: "TODO", level: "TODO"),
        tasks: []
    )
}

func printSingleTaskResult() throws {
    printDivider(title: "练习 1：单个对象")
    let data = makeData(from: singleTaskJSON)
    let task = try decodeTask(from: data)

    // TODO 4：
    // 请按下面固定格式输出：
    // 标题：复习闭包
    // 预计小时数：2
    // 完成状态：false
    print("TODO：请输出单个任务的字段内容。")
    _ = task
}

func printChapterListResult() throws {
    printDivider(title: "练习 2：数组根结构")
    let data = makeData(from: chapterListJSON)
    let notes = try decodeChapterNotes(from: data)

    // TODO 5：
    // 请逐项输出，并尽量对齐下面格式：
    // 第 24 章：泛型：让同一套逻辑适配更多类型
    // 标签：泛型 / 复用 / 约束
    print("TODO：请逐项输出章节笔记。")
    _ = notes
}

func printBoardResult() throws {
    printDivider(title: "练习 3：嵌套对象与对象数组")
    let data = makeData(from: boardJSON)
    let board = try decodeBoard(from: data)

    // TODO 6：
    // 请按下面固定格式输出：
    // 看板标题：周末复习看板
    // 负责人：Alice / beginner
    // - 整理 JSON 笔记 / 1 小时 / 已完成
    print("TODO：请输出看板和任务列表。")
    _ = board
}

do {
    try printSingleTaskResult()
    try printChapterListResult()
    try printBoardResult()
} catch {
    print("解析失败：\(error)")
}
