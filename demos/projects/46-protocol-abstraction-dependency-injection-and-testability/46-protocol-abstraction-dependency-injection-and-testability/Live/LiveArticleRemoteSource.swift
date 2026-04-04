//
//  LiveArticleRemoteSource.swift
//  46-protocol-abstraction-dependency-injection-and-testability
//
//  Created by Codex on 2026/4/4.
//

import Foundation

struct LiveArticleRemoteSource: ArticleRemoteSource {
    func fetchArticles() async throws -> [String] {
        try await Task.sleep(for: .milliseconds(100))
        return [
            "第 39 章：把请求细节收口到 NetworkClient",
            "第 43 章：缓存命中、缺失、损坏要分三种状态",
            "第 45 章：关系和删除规则会影响读取边界"
        ]
    }
}
