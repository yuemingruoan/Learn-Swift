//
//  AppBootstrap.swift
//  47-multi-file-project-organization-and-cross-file-collaboration
//
//  Created by Codex on 2026/4/4.
//

import Foundation

struct StudyPlanApp {
    let service: StudyPlanService
    let renderer: ConsoleRenderer
}

enum AppBootstrap {
    static func makeApp() -> StudyPlanApp {
        let repository = InMemoryStudyPlanRepository(seedPlan: makeSeedPlan())
        let service = StudyPlanService(repository: repository)
        let renderer = ConsoleRenderer()
        return StudyPlanApp(service: service, renderer: renderer)
    }

    static func makeSeedPlan() -> StudyPlan {
        StudyPlan(
            title: "第 47 章 Demo：把项目拆成多个文件",
            tasks: [
                StudyTask(id: 1, title: "把领域模型拆到独立文件", estimatedHours: 1, isFinished: true),
                StudyTask(id: 2, title: "把仓储和服务职责分开", estimatedHours: 2, isFinished: false),
                StudyTask(id: 3, title: "让 main.swift 只负责组装流程", estimatedHours: 1, isFinished: false)
            ]
        )
    }
}
