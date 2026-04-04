//
//  InMemoryArticleStore.swift
//  46-protocol-abstraction-dependency-injection-and-testability
//
//  Created by Codex on 2026/4/4.
//

import Foundation

final class InMemoryArticleStore: ArticleStore {
    private var articles: [String] = []

    func loadAll() throws -> [String] {
        articles
    }

    func replaceAll(with articles: [String]) throws {
        self.articles = articles
    }
}
