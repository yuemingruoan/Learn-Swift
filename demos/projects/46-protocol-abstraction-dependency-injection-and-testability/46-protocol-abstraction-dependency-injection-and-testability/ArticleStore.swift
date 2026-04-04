//
//  ArticleStore.swift
//  46-protocol-abstraction-dependency-injection-and-testability
//
//  Created by Codex on 2026/4/4.
//

import Foundation

protocol ArticleStore {
    func loadAll() throws -> [String]
    func replaceAll(with articles: [String]) throws
}
