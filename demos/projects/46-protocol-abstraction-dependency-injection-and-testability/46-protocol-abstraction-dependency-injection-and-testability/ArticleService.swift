//
//  ArticleService.swift
//  46-protocol-abstraction-dependency-injection-and-testability
//
//  Created by Codex on 2026/4/4.
//

import Foundation

enum CacheLoadResult<Value> {
    case hit(Value)
    case miss
    case corrupted(underlying: Error)
}

final class ArticleService {
    private let remote: ArticleRemoteSource
    private let cache: CacheStore
    private let store: ArticleStore

    init(remote: ArticleRemoteSource, cache: CacheStore, store: ArticleStore) {
        self.remote = remote
        self.cache = cache
        self.store = store
    }

    private func loadCachedArticles() -> CacheLoadResult<[String]> {
        do {
            guard let data = try cache.read(key: "articles.json") else {
                return .miss
            }

            let articles = try JSONDecoder().decode([String].self, from: data)
            return .hit(articles)
        } catch {
            return .corrupted(underlying: error)
        }
    }

    func refresh() async throws -> [String] {
        let articles: [String]

        do {
            articles = try await remote.fetchArticles()
        } catch {
            switch loadCachedArticles() {
            case .hit(let cached):
                return cached
            case .miss:
                throw error
            case .corrupted:
                try? cache.remove(key: "articles.json")
                throw error
            }
        }

        let data = try JSONEncoder().encode(articles)
        try? cache.write(key: "articles.json", data: data)
        try store.replaceAll(with: articles)
        return articles
    }
}
