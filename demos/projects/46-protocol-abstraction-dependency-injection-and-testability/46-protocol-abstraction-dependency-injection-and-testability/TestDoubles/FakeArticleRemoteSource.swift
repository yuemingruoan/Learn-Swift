//
//  FakeArticleRemoteSource.swift
//  46-protocol-abstraction-dependency-injection-and-testability
//
//  Created by Codex on 2026/4/4.
//

import Foundation

enum FakeRemoteError: Error {
    case forcedFailure
}

final class FakeArticleRemoteSource: ArticleRemoteSource {
    enum Mode {
        case success([String])
        case failure
    }

    private let mode: Mode

    init(mode: Mode) {
        self.mode = mode
    }

    func fetchArticles() async throws -> [String] {
        switch mode {
        case .success(let articles):
            return articles
        case .failure:
            throw FakeRemoteError.forcedFailure
        }
    }
}
