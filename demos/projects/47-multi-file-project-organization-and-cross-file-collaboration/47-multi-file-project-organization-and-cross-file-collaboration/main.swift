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

func runDemo() {
    let app = AppBootstrap.makeApp()

    printDivider("main.swift 只负责组装依赖")
    print(app.renderer.renderDependencyGraph())

    printDivider("第一次读取：跨文件协作已经形成链路")
    let initialPlan = app.service.loadPlan()
    print(app.renderer.renderPlan(initialPlan, headline: "当前学习计划"))

    printDivider("业务层修改状态，再回写到仓储")
    if let updatedPlan = app.service.finishTask(id: 2) {
        print(app.renderer.renderPlan(updatedPlan, headline: "完成第 2 项任务后"))
    } else {
        print("没有找到要完成的任务。")
    }

    printDivider("再次读取：证明不是 main.swift 手工拼接结果")
    let reloadedPlan = app.service.loadPlan()
    print(app.renderer.renderSummary(for: reloadedPlan))

    printDivider("访问控制提示")
    print(app.renderer.renderAccessControlNotes())

    printDivider("错误拆分对照")
    print(BadSplitExample.notes)
}

runDemo()
