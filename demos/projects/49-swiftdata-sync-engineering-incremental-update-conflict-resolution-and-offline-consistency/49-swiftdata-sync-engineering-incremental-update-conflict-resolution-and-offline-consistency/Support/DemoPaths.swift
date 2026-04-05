//
//  DemoPaths.swift
//  49-swiftdata-sync-engineering-incremental-update-conflict-resolution-and-offline-consistency
//
//  Created by Codex on 2026/4/4.
//

import Foundation
import SwiftData

enum DemoPaths {
    static func storeURL() throws -> URL {
        let fm = FileManager.default
        let caches = try fm.url(
            for: .cachesDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )

        let folder = caches
            .appendingPathComponent("learn-swift", isDirectory: true)
            .appendingPathComponent("49-swiftdata-sync-demo", isDirectory: true)

        try fm.createDirectory(at: folder, withIntermediateDirectories: true)
        return folder.appendingPathComponent("study-plan-sync.store")
    }

    static func cleanStoreFiles(at storeURL: URL) {
        let fm = FileManager.default
        let candidates = [
            storeURL,
            URL(fileURLWithPath: storeURL.path + "-shm"),
            URL(fileURLWithPath: storeURL.path + "-wal")
        ]

        for url in candidates where fm.fileExists(atPath: url.path) {
            try? fm.removeItem(at: url)
        }
    }

    static func makeContainer(at storeURL: URL) throws -> ModelContainer {
        let configuration = ModelConfiguration(url: storeURL)
        return try ModelContainer(
            for: StudyPlanRecord.self,
            StudyTaskRecord.self,
            PendingTaskMutationRecord.self,
            configurations: configuration
        )
    }
}
