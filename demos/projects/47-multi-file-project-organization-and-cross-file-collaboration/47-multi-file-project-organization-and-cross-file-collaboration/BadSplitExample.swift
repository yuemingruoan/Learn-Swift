//
//  BadSplitExample.swift
//  47-multi-file-project-organization-and-cross-file-collaboration
//
//  Created by Codex on 2026/4/4.
//

import Foundation

enum BadSplitExample {
    static let notes = """
    反例 1：按“谁都方便访问”来拆
    var sharedTasks: [StudyTask] = []
    func finishTask() { sharedTasks[0].isFinished = true }

    反例 2：把输出逻辑直接塞回 service
    struct StudyPlanService {
        func finishTask(id: Int) { print("任务完成") }
    }

    反例 3：让 main.swift 继续保存所有业务细节
    // main.swift 里同时写模型、仓储、服务、渲染，会让依赖方向重新混在一起。
    """
}
