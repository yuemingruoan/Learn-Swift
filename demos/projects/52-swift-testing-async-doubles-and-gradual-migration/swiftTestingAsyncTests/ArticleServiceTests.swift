import Foundation
import Testing
@testable import swiftTestingAsync

private enum CacheFailure: Error {
    case corrupted
}

private final class StubArticleRemoteSource: ArticleRemoteSource {
    private let result: Result<[Article], Error>
    private(set) var fetchCallCount = 0

    /// Creates a stub remote source with a predefined fetch result.
    ///
    /// - Parameter result: The result to return when `fetchArticles()` is called.
    init(result: Result<[Article], Error>) {
        self.result = result
    }

    /// Returns the predefined fetch result and records the invocation count.
    ///
    /// - Returns: The predefined array of articles.
    /// - Throws: The error carried by `result` when the stub is configured to fail.
    func fetchArticles() async throws -> [Article] {
        fetchCallCount += 1
        return try result.get()
    }
}

private final class SpyCacheStore: CacheStore {
    var readResult: Result<Data?, Error> = .success(nil)
    private(set) var writeCalls: [(key: String, data: Data)] = []
    private(set) var removedKeys: [String] = []
    private(set) var persistedDataByKey: [String: Data] = [:]

    /// Returns the predefined cache read result.
    ///
    /// - Parameter key: The cache key requested by the service.
    /// - Returns: The predefined cached data, or `nil` when simulating a cache miss.
    /// - Throws: The error carried by `readResult` when the spy is configured to fail.
    func read(key: String) throws -> Data? {
        try readResult.get()
    }

    /// Records a cache write and keeps the latest data in memory for assertions.
    ///
    /// - Parameters:
    ///   - key: The cache key being written.
    ///   - data: The data being stored for that key.
    func write(key: String, data: Data) throws {
        persistedDataByKey[key] = data
        writeCalls.append((key, data))
    }

    /// Records that a cache key was removed and clears its in-memory value.
    ///
    /// - Parameter key: The cache key being removed.
    func remove(key: String) throws {
        persistedDataByKey[key] = nil
        removedKeys.append(key)
    }
}

private final class SpyArticleStore: ArticleStore {
    private(set) var replaceAllCalls: [[Article]] = []

    /// Returns the latest articles previously recorded by `replaceAll(with:)`.
    ///
    /// - Returns: The most recent stored article list, or an empty array if nothing was recorded.
    func loadAll() throws -> [Article] {
        replaceAllCalls.last ?? []
    }

    /// Records a full replacement request for later assertions.
    ///
    /// - Parameter articles: The articles passed to the store replacement operation.
    func replaceAll(with articles: [Article]) throws {
        replaceAllCalls.append(articles)
    }
}

@Suite("ArticleService.refresh()")
struct ArticleServiceTests {
    @Test("远程成功时会返回结果，并写入缓存和存储")
    func refreshReturnsRemoteArticlesAndPersistsThem() async throws {
        let remoteArticles = [
            Article(id: 1, title: "Swift Testing 入门"),
            Article(id: 2, title: "参数化测试"),
        ]
        let remote = StubArticleRemoteSource(result: .success(remoteArticles))
        let cache = SpyCacheStore()
        let store = SpyArticleStore()
        let service = ArticleService(remote: remote, cache: cache, store: store)

        let received = try await service.refresh()

        #expect(received == remoteArticles)
        #expect(remote.fetchCallCount == 1)
        #expect(store.replaceAllCalls == [remoteArticles])
        #expect(cache.writeCalls.count == 1)

        let cachedData = try #require(cache.persistedDataByKey["articles.json"])
        let decoded = try JSONDecoder().decode([Article].self, from: cachedData)
        #expect(decoded == remoteArticles)
    }

    @Test("远程失败但缓存命中时，refresh 会回退到缓存")
    func refreshFallsBackToCacheWhenRemoteFails() async throws {
        let cachedArticles = [
            Article(id: 10, title: "缓存里的文章"),
        ]
        let remote = StubArticleRemoteSource(result: .failure(DemoRemoteError.offline))
        let cache = SpyCacheStore()
        cache.readResult = .success(try JSONEncoder().encode(cachedArticles))
        let store = SpyArticleStore()
        let service = ArticleService(remote: remote, cache: cache, store: store)

        let received = try await service.refresh()

        #expect(received == cachedArticles)
        #expect(remote.fetchCallCount == 1)
        #expect(store.replaceAllCalls.isEmpty)
        #expect(cache.writeCalls.isEmpty)
    }

    @Test("缓存损坏时会清理坏缓存，并把原始远程错误继续抛出")
    func refreshRemovesCorruptedCacheBeforeRethrowingRemoteError() async {
        let remote = StubArticleRemoteSource(result: .failure(DemoRemoteError.offline))
        let cache = SpyCacheStore()
        cache.readResult = .success(Data("not json".utf8))
        let store = SpyArticleStore()
        let service = ArticleService(remote: remote, cache: cache, store: store)

        var capturedError: DemoRemoteError?

        do {
            _ = try await service.refresh()
        } catch let error as DemoRemoteError {
            capturedError = error
        } catch {
            #expect(Bool(false), "收到意料之外的错误：\(error)")
        }

        #expect(capturedError == .offline)
        #expect(cache.removedKeys == ["articles.json"])
    }

    @Test("没有缓存时会直接抛出远程错误")
    func refreshRethrowsRemoteErrorWhenCacheMisses() async {
        let remote = StubArticleRemoteSource(result: .failure(DemoRemoteError.offline))
        let cache = SpyCacheStore()
        cache.readResult = .success(nil)
        let store = SpyArticleStore()
        let service = ArticleService(remote: remote, cache: cache, store: store)

        var capturedError: DemoRemoteError?

        do {
            _ = try await service.refresh()
        } catch let error as DemoRemoteError {
            capturedError = error
        } catch {
            #expect(Bool(false), "收到意料之外的错误：\(error)")
        }

        #expect(capturedError == .offline)
        #expect(cache.removedKeys.isEmpty)
        #expect(store.replaceAllCalls.isEmpty)
    }
}
