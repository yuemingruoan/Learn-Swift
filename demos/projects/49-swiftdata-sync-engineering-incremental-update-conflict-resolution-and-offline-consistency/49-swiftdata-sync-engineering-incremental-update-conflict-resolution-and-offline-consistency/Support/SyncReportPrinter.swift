//
//  SyncReportPrinter.swift
//  49-swiftdata-sync-engineering-incremental-update-conflict-resolution-and-offline-consistency
//
//  Created by Codex on 2026/4/4.
//

import Foundation

enum SyncReportPrinter {
    static func printReport(_ report: SyncReport, headline: String) {
        print("\n======== \(headline) ========")
        print("push 成功数量：\(report.pushedMutationCount)")
        print("pull 新建数量：\(report.pulledCreatedCount)")
        print("pull 更新数量：\(report.pulledUpdatedCount)")
        print("pull 删除数量：\(report.pulledDeletedCount)")
        print("冲突数量：\(report.conflictCount)")
        print("跳过数量：\(report.skippedCount)")
        print("同步后待上传 mutation：\(report.pendingMutationCountAfterSync)")

        if report.conflicts.isEmpty {
            print("冲突详情：无")
        } else {
            print("冲突详情：")
            for conflict in report.conflicts {
                print("- task #\(conflict.taskRemoteID) / \(conflict.kind.rawValue) / \(conflict.message)")
            }
        }
    }
}
