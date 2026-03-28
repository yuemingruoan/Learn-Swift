//
//  main.swift
//  35-json-advanced-field-mapping-and-nested-structures-starter
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

// 练习说明
//
// 本题只有 1 份 JSON 结构。
// 下面给出的 3 段 JSON 文本，都对应同一个学习任务对象，只是每段数据提供的字段情况不同。
//
// 结构属性：
//
// {
//     "key": 类型，是否可选，默认值
// }
//
// 结构声明：
//
// {
//     "task_title": String，否，无默认值
//     "estimated_hours": Int，否，无默认值
//     "note": String，是，默认值为 nil
//     "is_finished": Bool，是，默认值为 false
//     "tags": [String]，是，默认值为 []
//     "owner": {
//         "name": String，否，无默认值
//         "level": String，否，无默认值
//         "contact": {
//             "links": [
//                 {
//                     "link_label": String，否，无默认值
//                     "url": String，否，无默认值
//                     "is_primary": Bool，是，默认值为 false
//                 }
//             ]，是，默认值为 []
//         }，否，无默认值
//     }，否，无默认值
//     "progress": {
//         "current_step": Int，否，无默认值
//         "checkpoints": [
//             {
//                 "title": String，否，无默认值
//                 "is_done": Bool，是，默认值为 false
//                 "references": [Link]，是，默认值为 []
//             }
//         ]，是，默认值为 []
//     }，否，无默认值
//     "resources": [
//         {
//             "resource_title": String，否，无默认值
//             "kind": String，否，无默认值
//             "is_required": Bool，是，默认值为 false
//             "links": [Link]，是，默认值为 []
//         }
//     ]，是，默认值为 []
// }
//
// 提示：
//
// 1. `Link` 不是额外的一份根 JSON，而是同一个根结构里会被重复复用的子结构。
// 2. 这个子结构同时出现在 owner.contact.links、checkpoint.references、resource.links 里。
//
// 实现要求：
//
// 1. 声明你需要的类型，本题不再提供现成模型。
// 2. 为需要映射的字段写 CodingKeys。
// 3. 处理根对象和嵌套对象里的 Optional 与默认值。
// 4. 实现解码逻辑，把下面 3 段 JSON 解成同一个根模型。
// 5. 实现格式化输出函数，对齐文稿中的目标输出。

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

// 目标输出请对齐下面这份固定格式：
//
// ======== 练习 1：共享子结构与多层嵌套 ========
// 标题：复习闭包
// 预计小时数：2
// 备注：重点观察参数和返回值的关系
// 完成状态：未完成
// 标签：closure / review
// 负责人：Alice / beginner
// 负责人链接：
// - Alice 的学习主页 / https://study.example.com/alice / 主链接
// - 闭包讨论群 / https://chat.example.com/closure / 普通链接
// 当前步骤：2
// 检查点：
// - 阅读闭包语法 / 已完成
//   参考链接：
//   - 官方文档 / https://swift.org/documentation/ / 主链接
// - 手写排序闭包 / 未完成
//   参考链接：无
// 资源：
// - 闭包语法卡片 / article / 必学
//   链接：
//   - 文档页 / https://example.com/closure-card / 主链接
// - Swift Playgrounds 练习 / exercise / 选学
//   链接：无
//
// ======== 练习 2：缺失字段与默认值 ========
// 标题：整理 JSON 笔记
// 预计小时数：1
// 备注：无
// 完成状态：未完成
// 标签：无标签
// 负责人：Bob / beginner
// 负责人链接：无
// 当前步骤：1
// 检查点：无
// 资源：无
//
// ======== 练习 3：空字符串与空数组 ========
// 标题：检查空字符串和空数组
// 预计小时数：1
// 备注：（空字符串）
// 完成状态：已完成
// 标签：无标签
// 负责人：Carol / intermediate
// 负责人链接：无
// 当前步骤：3
// 检查点：无
// 资源：无

// 建议实现顺序：
//
// 1. 先声明根对象，再补齐 owner、contact、progress、checkpoint、resource、link 这些嵌套结构。
// 2. 再处理字段映射、Optional 和默认值。
// 3. 然后分别解码 completeTaskJSON、defaultedTaskJSON、emptyValueTaskJSON。
// 4. 最后按目标格式输出。
