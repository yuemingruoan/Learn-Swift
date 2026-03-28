//
//  main.swift
//  35-json-advanced-field-mapping-and-nested-structures
//
//  Created by Codex on 2026/3/28.
//

import Foundation

func printDivider(title: String) {
    print("")
    print("======== \(title) ========")
}

func makeData(from jsonText: String) -> Data {
    return jsonText.data(using: .utf8)!
}

struct StudyLinkDTO: Decodable {
    let linkLabel: String
    let url: String
    let isPrimary: Bool

    enum CodingKeys: String, CodingKey {
        case linkLabel = "link_label"
        case url
        case isPrimary = "is_primary"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        linkLabel = try container.decode(String.self, forKey: .linkLabel)
        url = try container.decode(String.self, forKey: .url)
        isPrimary = try container.decodeIfPresent(Bool.self, forKey: .isPrimary) ?? false
    }
}

struct StudyOwnerContactDTO: Decodable {
    let links: [StudyLinkDTO]

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let value = try container.decode(OwnerContactPayload.self)
        links = value.links ?? []
    }

    private struct OwnerContactPayload: Decodable {
        let links: [StudyLinkDTO]?
    }
}

struct StudyOwnerDTO: Decodable {
    let name: String
    let level: String
    let contact: StudyOwnerContactDTO
}

struct StudyCheckpointDTO: Decodable {
    let title: String
    let isDone: Bool
    let references: [StudyLinkDTO]

    enum CodingKeys: String, CodingKey {
        case title
        case isDone = "is_done"
        case references
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        title = try container.decode(String.self, forKey: .title)
        isDone = try container.decodeIfPresent(Bool.self, forKey: .isDone) ?? false
        references = try container.decodeIfPresent([StudyLinkDTO].self, forKey: .references) ?? []
    }
}

struct StudyProgressDTO: Decodable {
    let currentStep: Int
    let checkpoints: [StudyCheckpointDTO]

    enum CodingKeys: String, CodingKey {
        case currentStep = "current_step"
        case checkpoints
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        currentStep = try container.decode(Int.self, forKey: .currentStep)
        checkpoints = try container.decodeIfPresent([StudyCheckpointDTO].self, forKey: .checkpoints) ?? []
    }
}

struct StudyResourceDTO: Decodable {
    let resourceTitle: String
    let kind: String
    let isRequired: Bool
    let links: [StudyLinkDTO]

    enum CodingKeys: String, CodingKey {
        case resourceTitle = "resource_title"
        case kind
        case isRequired = "is_required"
        case links
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        resourceTitle = try container.decode(String.self, forKey: .resourceTitle)
        kind = try container.decode(String.self, forKey: .kind)
        isRequired = try container.decodeIfPresent(Bool.self, forKey: .isRequired) ?? false
        links = try container.decodeIfPresent([StudyLinkDTO].self, forKey: .links) ?? []
    }
}

struct StudyTaskDTO: Decodable {
    let taskTitle: String
    let estimatedHours: Int
    let note: String?
    let isFinished: Bool
    let tags: [String]
    let owner: StudyOwnerDTO
    let progress: StudyProgressDTO
    let resources: [StudyResourceDTO]

    enum CodingKeys: String, CodingKey {
        case taskTitle = "task_title"
        case estimatedHours = "estimated_hours"
        case note
        case isFinished = "is_finished"
        case tags
        case owner
        case progress
        case resources
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        taskTitle = try container.decode(String.self, forKey: .taskTitle)
        estimatedHours = try container.decode(Int.self, forKey: .estimatedHours)
        note = try container.decodeIfPresent(String.self, forKey: .note)
        isFinished = try container.decodeIfPresent(Bool.self, forKey: .isFinished) ?? false
        tags = try container.decodeIfPresent([String].self, forKey: .tags) ?? []
        owner = try container.decode(StudyOwnerDTO.self, forKey: .owner)
        progress = try container.decode(StudyProgressDTO.self, forKey: .progress)
        resources = try container.decodeIfPresent([StudyResourceDTO].self, forKey: .resources) ?? []
    }
}

let completeTaskJSON = """
{
    "task_title": "复习闭包",
    "estimated_hours": 2,
    "note": "重点观察参数和返回值的关系",
    "is_finished": false,
    "tags": ["closure", "review"],
    "owner": {
        "name": "Alice",
        "level": "beginner",
        "contact": {
            "links": [
                {
                    "link_label": "Alice 的学习主页",
                    "url": "https://study.example.com/alice",
                    "is_primary": true
                },
                {
                    "link_label": "闭包讨论群",
                    "url": "https://chat.example.com/closure"
                }
            ]
        }
    },
    "progress": {
        "current_step": 2,
        "checkpoints": [
            {
                "title": "阅读闭包语法",
                "is_done": true,
                "references": [
                    {
                        "link_label": "官方文档",
                        "url": "https://swift.org/documentation/",
                        "is_primary": true
                    }
                ]
            },
            {
                "title": "手写排序闭包"
            }
        ]
    },
    "resources": [
        {
            "resource_title": "闭包语法卡片",
            "kind": "article",
            "is_required": true,
            "links": [
                {
                    "link_label": "文档页",
                    "url": "https://example.com/closure-card",
                    "is_primary": true
                }
            ]
        },
        {
            "resource_title": "Swift Playgrounds 练习",
            "kind": "exercise"
        }
    ]
}
"""

let defaultedTaskJSON = """
{
    "task_title": "整理 JSON 笔记",
    "estimated_hours": 1,
    "owner": {
        "name": "Bob",
        "level": "beginner",
        "contact": {}
    },
    "progress": {
        "current_step": 1
    }
}
"""

let emptyValueTaskJSON = """
{
    "task_title": "检查空字符串和空数组",
    "estimated_hours": 1,
    "note": "",
    "is_finished": true,
    "tags": [],
    "owner": {
        "name": "Carol",
        "level": "intermediate",
        "contact": {
            "links": []
        }
    },
    "progress": {
        "current_step": 3,
        "checkpoints": []
    },
    "resources": []
}
"""

func decodeTask(from data: Data) throws -> StudyTaskDTO {
    let decoder = JSONDecoder()
    return try decoder.decode(StudyTaskDTO.self, from: data)
}

func formatNote(_ note: String?) -> String {
    guard let note else {
        return "无"
    }

    return note.isEmpty ? "（空字符串）" : note
}

func formatTags(_ tags: [String]) -> String {
    return tags.isEmpty ? "无标签" : tags.joined(separator: " / ")
}

func formatCheckpointStatus(_ isDone: Bool) -> String {
    return isDone ? "已完成" : "未完成"
}

func formatResourceRequirement(_ isRequired: Bool) -> String {
    return isRequired ? "必学" : "选学"
}

func formatLinkRole(_ isPrimary: Bool) -> String {
    return isPrimary ? "主链接" : "普通链接"
}

func printLinks(_ links: [StudyLinkDTO], emptyLabel: String, indent: String = "") {
    if links.isEmpty {
        print("\(indent)\(emptyLabel)")
        return
    }

    for link in links {
        print("\(indent)- \(link.linkLabel) / \(link.url) / \(formatLinkRole(link.isPrimary))")
    }
}

func printTaskSummary(_ task: StudyTaskDTO) {
    let status = task.isFinished ? "已完成" : "未完成"

    print("标题：\(task.taskTitle)")
    print("预计小时数：\(task.estimatedHours)")
    print("备注：\(formatNote(task.note))")
    print("完成状态：\(status)")
    print("标签：\(formatTags(task.tags))")
    print("负责人：\(task.owner.name) / \(task.owner.level)")

    if task.owner.contact.links.isEmpty {
        print("负责人链接：无")
    } else {
        print("负责人链接：")
        printLinks(task.owner.contact.links, emptyLabel: "无")
    }

    print("当前步骤：\(task.progress.currentStep)")

    if task.progress.checkpoints.isEmpty {
        print("检查点：无")
    } else {
        print("检查点：")
        for checkpoint in task.progress.checkpoints {
            print("- \(checkpoint.title) / \(formatCheckpointStatus(checkpoint.isDone))")
            if checkpoint.references.isEmpty {
                print("  参考链接：无")
            } else {
                print("  参考链接：")
                printLinks(checkpoint.references, emptyLabel: "无", indent: "  ")
            }
        }
    }

    if task.resources.isEmpty {
        print("资源：无")
    } else {
        print("资源：")
        for resource in task.resources {
            print("- \(resource.resourceTitle) / \(resource.kind) / \(formatResourceRequirement(resource.isRequired))")
            if resource.links.isEmpty {
                print("  链接：无")
            } else {
                print("  链接：")
                printLinks(resource.links, emptyLabel: "无", indent: "  ")
            }
        }
    }
}

func printCompleteTaskResult() throws {
    printDivider(title: "练习 1：共享子结构与多层嵌套")
    let task = try decodeTask(from: makeData(from: completeTaskJSON))
    printTaskSummary(task)
}

func printDefaultedTaskResult() throws {
    printDivider(title: "练习 2：缺失字段与默认值")
    let task = try decodeTask(from: makeData(from: defaultedTaskJSON))
    printTaskSummary(task)
}

func printEmptyValueTaskResult() throws {
    printDivider(title: "练习 3：空字符串与空数组")
    let task = try decodeTask(from: makeData(from: emptyValueTaskJSON))
    printTaskSummary(task)
}

do {
    try printCompleteTaskResult()
    try printDefaultedTaskResult()
    try printEmptyValueTaskResult()
} catch {
    print("解析失败：\(error)")
}
