import Foundation

struct Article: Codable, Equatable {
    let id: Int
    let title: String
}

protocol ArticleRemoteSource {
    func fetchArticles() async throws -> [Article]
}

protocol CacheStore {
    func read(key: String) throws -> Data?
    func write(key: String, data: Data) throws
    func remove(key: String) throws
}

protocol ArticleStore {
    func loadAll() throws -> [Article]
    func replaceAll(with articles: [Article]) throws
}

enum DemoRemoteError: Error, Equatable {
    case offline
}

struct ArticleService {
    private let remote: ArticleRemoteSource
    private let cache: CacheStore
    private let store: ArticleStore
    private let cacheKey = "articles.json"

    init(remote: ArticleRemoteSource, cache: CacheStore, store: ArticleStore) {
        self.remote = remote
        self.cache = cache
        self.store = store
    }

    private enum CacheLoadResult<Value> {
        case hit(Value)
        case miss
        case corrupted(underlying: Error)
    }

    private func loadCachedArticles() -> CacheLoadResult<[Article]> {
        do {
            guard let data = try cache.read(key: cacheKey) else {
                return .miss
            }

            let articles = try JSONDecoder().decode([Article].self, from: data)
            return .hit(articles)
        } catch {
            return .corrupted(underlying: error)
        }
    }

    func refresh() async throws -> [Article] {
        let articles: [Article]

        do {
            articles = try await remote.fetchArticles()
        } catch {
            let remoteError = error

            switch loadCachedArticles() {
            case .hit(let cachedArticles):
                return cachedArticles
            case .miss:
                throw remoteError
            case .corrupted:
                try? cache.remove(key: cacheKey)
                throw remoteError
            }
        }

        let data = try JSONEncoder().encode(articles)
        try? cache.write(key: cacheKey, data: data)
        try store.replaceAll(with: articles)
        return articles
    }
}
