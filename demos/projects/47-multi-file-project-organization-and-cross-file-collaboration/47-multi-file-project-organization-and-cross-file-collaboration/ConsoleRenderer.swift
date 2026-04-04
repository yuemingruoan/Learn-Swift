//
//  ConsoleRenderer.swift
//  47-multi-file-project-organization-and-cross-file-collaboration
//
//  Created by Codex on 2026/4/4.
//

import Foundation

struct ConsoleRenderer {
    func renderDependencyGraph() -> String {
        """
        依赖方向：
        main.swift -> AppBootstrap -> StudyPlanRepository -> StudyPlanService -> ConsoleRenderer
        数据流向：
        repository.loadPlan() -> service.finishTask(id:) -> renderer.renderPlan(...)
        """
    }

    func renderPlan(_ plan: StudyPlan, headline: String) -> String {
        var lines = [headline]
        lines.append("计划标题：\(plan.title)")
        lines.append("总预估时长：\(plan.totalEstimatedHours) 小时")

        for task in plan.tasks {
            let status = task.isFinished ? "已完成" : "未完成"
            lines.append("- [\(status)] #\(task.id) \(task.title) / \(task.estimatedHours) 小时")
        }

        lines.append("未完成数量：\(plan.unfinishedTaskCount)")
        return lines.joined(separator: "\n")
    }

    func renderSummary(for plan: StudyPlan) -> String {
        """
        重新读取后的计划标题：\(plan.title)
        未完成任务数：\(plan.unfinishedTaskCount)
        当前任务标题顺序：\(plan.tasks.map(\.title).joined(separator: " -> "))
        """
    }

    func renderAccessControlNotes() -> String {
        """
        访问控制观察：
        - StudyPlan.tasks 使用 private(set)，文件外可读但不能直接改写
        - 真正允许修改任务状态的位置被收口在 StudyPlan.markTaskFinished(id:)
        - 如果把 tasks 再收紧成 private，渲染层跨文件读取也会失效
        """
    }
}
