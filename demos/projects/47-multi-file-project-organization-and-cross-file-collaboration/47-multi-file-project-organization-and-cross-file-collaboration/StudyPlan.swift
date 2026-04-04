//
//  StudyPlan.swift
//  47-multi-file-project-organization-and-cross-file-collaboration
//
//  Created by Codex on 2026/4/4.
//

import Foundation

struct StudyPlan {
    let title: String
    private(set) var tasks: [StudyTask]

    init(title: String, tasks: [StudyTask]) {
        self.title = title
        self.tasks = tasks
    }

    var unfinishedTaskCount: Int {
        tasks.filter { !$0.isFinished }.count
    }

    var totalEstimatedHours: Int {
        tasks.reduce(0) { $0 + $1.estimatedHours }
    }

    mutating func markTaskFinished(id: Int) -> Bool {
        guard let index = tasks.firstIndex(where: { $0.id == id }) else {
            return false
        }

        tasks[index].isFinished = true
        return true
    }
}
