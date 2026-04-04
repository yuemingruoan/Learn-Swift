//
//  main.swift
//  47-multi-file-project-organization-and-cross-file-collaboration
//
//  Created by Codex on 2026/4/4.
//

import Foundation

func printDivider(_ title: String) {
    print("\n======== \(title) ========")
}

func makeSeedPlan() -> StudyPlan {
    StudyPlan(
        title: "第 47 章 Demo：把项目拆成多个文件",
        tasks: [
            StudyTask(id: 1, title: "把领域模型拆到独立文件", estimatedHours: 1, isFinished: true),
            StudyTask(id: 2, title: "把仓储和服务职责分开", estimatedHours: 2, isFinished: false),
            StudyTask(id: 3, title: "让 main.swift 只负责组装流程", estimatedHours: 1, isFinished: false)
        ]
    )
}

func runDemo() {
    let repository = InMemoryStudyPlanRepository(seedPlan: makeSeedPlan())
    let service = StudyPlanService(repository: repository)
    let renderer = ConsoleRenderer()

    printDivider("main.swift 只负责组装依赖")
    print("已创建：repository -> service -> renderer")

    printDivider("第一次读取：跨文件协作已经形成链路")
    let initialPlan = service.loadPlan()
    print(renderer.renderPlan(initialPlan, headline: "当前学习计划"))

    printDivider("业务层修改状态，再回写到仓储")
    if let updatedPlan = service.finishTask(id: 2) {
        print(renderer.renderPlan(updatedPlan, headline: "完成第 2 项任务后"))
    } else {
        print("没有找到要完成的任务。")
    }

    printDivider("再次读取：证明不是 main.swift 手工拼接结果")
    let reloadedPlan = service.loadPlan()
    print(renderer.renderSummary(for: reloadedPlan))

    printDivider("访问控制提示")
    print("StudyPlan.tasks 现在是 private(set)。")
    print("渲染层可以读取它，但不能在文件外随手改写。")
    print("如果把它进一步收紧成 private，跨文件读取就会直接失效。")
}

runDemo()
