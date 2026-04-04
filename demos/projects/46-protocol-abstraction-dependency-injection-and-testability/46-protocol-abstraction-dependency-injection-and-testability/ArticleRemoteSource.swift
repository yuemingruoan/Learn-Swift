//
//  ArticleRemoteSource.swift
//  46-protocol-abstraction-dependency-injection-and-testability
//
//  Created by Codex on 2026/4/4.
//

import Foundation

protocol ArticleRemoteSource {
    func fetchArticles() async throws -> [String]
}
