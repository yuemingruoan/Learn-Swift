//
//  main.swift
//  48-swiftdata-engineering-modeling-dto-persistence-and-domain-boundaries
//
//  Created by Codex on 2026/4/4.
//

import Foundation
import SwiftData

let samplePlanJSON = """
{
  "plan_id": 101,
  "plan_title": "SwiftData 工程建模",
  "owner": {
    "display_name": "Alice"
  },
  "published_at": "2026-04-04T09:30:00Z",
  "tasks": [
    {
      "task_id": 1,
      "task_title": "识别 DTO 只服从接口结构",
      "estimated_minutes": 20,
      "is_finished": false
    },
    {
      "task_id": 2,
      "task_title": "把 JSON 映射成 SwiftData Record",
      "estimated_minutes": 35,
      "is_finished": true
    },
    {
      "task_id": 3,
      "task_title": "读取 Record 后再映射成 Domain",
      "estimated_minutes": 25,
      "is_finished": false
    }
  ]
}
"""

let updatedPlanJSON = """
{
  "plan_id": 101,
  "plan_title": "SwiftData 工程建模（第二次同步）",
  "owner": {
    "display_name": "Alice"
  },
  "published_at": "2026-04-04T09:30:00Z",
  "tasks": [
    {
      "task_id": 3,
      "task_title": "读取 Record 后再映射成 Domain",
      "estimated_minutes": 25,
      "is_finished": true
    },
    {
      "task_id": 4,
      "task_title": "区分远程字段、本地字段和业务推导字段",
      "estimated_minutes": 30,
      "is_finished": false
    },
    {
      "task_id": 2,
      "task_title": "把 JSON 映射成 SwiftData Record",
      "estimated_minutes": 40,
      "is_finished": true
    }
  ]
}
"""

func printDivider(_ title: String) {
    print("\n======== \(title) ========")
}

func printDTO(_ dto: StudyPlanDTO) {
    print("DTO.planID = \(dto.planID)")
    print("DTO.planTitle = \(dto.planTitle)")
    print("DTO.owner.displayName = \(dto.owner.displayName)")
    print("DTO.publishedAt = \(dto.publishedAt)")
    print("DTO.tasks.count = \(dto.tasks.count)")
    for task in dto.tasks {
        print("- DTO task #\(task.taskID) \(task.taskTitle) / \(task.estimatedMinutes) 分钟 / finished=\(task.isFinished)")
    }
}

func printRecords(_ plans: [StudyPlanRecord]) {
    if plans.isEmpty {
        print("(没有持久化记录)")
        return
    }

    for plan in plans {
        print("Record.remoteID = \(plan.remoteID)")
        print("Record.title = \(plan.title)")
        print("Record.ownerName = \(plan.ownerName)")
        print("Record.syncedAt = \(plan.syncedAt)")
        print("Record 持久化字段：publishedAt=\(plan.publishedAt)")
        for task in plan.tasks.sorted(by: { $0.sortOrder < $1.sortOrder }) {
            print("- Record task #\(task.remoteID) \(task.title) / order=\(task.sortOrder) / finished=\(task.isFinished)")
        }
    }
}

func printDomainPlans(_ plans: [StudyPlan]) {
    if plans.isEmpty {
        print("(没有领域模型)")
        return
    }

    for plan in plans {
        print("领域计划：\(plan.title)")
        print("作者：\(plan.ownerName)")
        print("未完成任务数：\(plan.unfinishedTaskCount)")
        print("总预估时长：\(plan.totalEstimatedMinutes) 分钟")
        print("完成进度：\(plan.completionSummary)")
        print("当前建议聚焦：\(plan.recommendedFocusTitle)")
        print("任务顺序：\(plan.tasks.map(\.title).joined(separator: " -> "))")
    }
}

func runDemo() {
    do {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let firstDTO = try decoder.decode(StudyPlanDTO.self, from: Data(samplePlanJSON.utf8))
        let secondDTO = try decoder.decode(StudyPlanDTO.self, from: Data(updatedPlanJSON.utf8))

        printDivider("第 1 步：第一次远程 DTO")
        printDTO(firstDTO)

        let storeURL = try DemoPaths.storeURL()
        DemoPaths.cleanStoreFiles(at: storeURL)
        printDivider("准备 SwiftData store")
        print("store 文件：\(storeURL.path)")

        let container1 = try DemoPaths.makeContainer(at: storeURL)
        let context1 = ModelContext(container1)
        let store1 = StudyPlanStore(context: context1)

        try store1.replaceStoredPlan(
            with: firstDTO,
            syncedAt: ISO8601DateFormatter().date(from: "2026-04-04T10:00:00Z") ?? .now
        )
        let recordsAfterSave = try store1.fetchStoredPlans()

        printDivider("第 2 步：第一次同步后保存成 SwiftData Record")
        printRecords(recordsAfterSave)

        let container2 = try DemoPaths.makeContainer(at: storeURL)
        let context2 = ModelContext(container2)
        let store2 = StudyPlanStore(context: context2)

        let persistedRecords = try store2.fetchStoredPlans()
        printDivider("第 3 步：重建容器后再次读取第一次同步的 Record")
        printRecords(persistedRecords)

        printDivider("第 4 步：第二次远程 DTO")
        printDTO(secondDTO)

        try store2.replaceStoredPlan(
            with: secondDTO,
            syncedAt: ISO8601DateFormatter().date(from: "2026-04-04T12:00:00Z") ?? .now
        )
        let recordsAfterSecondSync = try store2.fetchStoredPlans()
        printDivider("第 5 步：第二次同步覆盖本地 Record")
        printRecords(recordsAfterSecondSync)

        let container3 = try DemoPaths.makeContainer(at: storeURL)
        let context3 = ModelContext(container3)
        let store3 = StudyPlanStore(context: context3)

        let rebuiltRecords = try store3.fetchStoredPlans()
        printDivider("第 6 步：再次重建容器，证明不是内存假象")
        printRecords(rebuiltRecords)

        let domainPlans = try store3.fetchDomainPlans()
        printDivider("第 7 步：映射成领域模型并展示业务推导值")
        printDomainPlans(domainPlans)
    } catch {
        print("Demo 运行失败：\(error)")
    }
}

runDemo()
