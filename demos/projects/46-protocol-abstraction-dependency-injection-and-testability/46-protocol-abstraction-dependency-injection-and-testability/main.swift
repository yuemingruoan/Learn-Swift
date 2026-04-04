//
//  main.swift
//  46-protocol-abstraction-dependency-injection-and-testability
//
//  Created by Codex on 2026/4/4.
//

import Foundation

func printDivider(_ title: String) {
    print("\n======== \(title) ========")
}

func printArticles(_ articles: [String], source: String) {
    print("来源：\(source)")
    for article in articles {
        print("- \(article)")
    }
}

func runDemo() async {
    do {
        printDivider("真实现路径：业务不直接依赖 URLSession / FileManager / 数据库")
        let liveService = ArticleService(
            remote: LiveArticleRemoteSource(),
            cache: InMemoryCacheStore(),
            store: InMemoryArticleStore()
        )
        let liveArticles = try await liveService.refresh()
        printArticles(liveArticles, source: "live remote")

        printDivider("fake 路径：不访问真实网络也能验证主流程")
        let fakeService = ArticleService(
            remote: FakeArticleRemoteSource(mode: .success([
                "stub 文章 A：协议由使用方定义",
                "stub 文章 B：依赖注入让替换变容易"
            ])),
            cache: InMemoryCacheStore(),
            store: InMemoryArticleStore()
        )
        let fakeArticles = try await fakeService.refresh()
        printArticles(fakeArticles, source: "fake remote")

        printDivider("缓存命中：远程失败时仍然能回退")
        let cacheStore = InMemoryCacheStore()
        try cacheStore.write(
            key: "articles.json",
            data: try JSONEncoder().encode([
                "cache 文章 A：命中时不需要访问远程",
                "cache 文章 B：调用方仍然拿到稳定结果"
            ])
        )
        let cacheBackedService = ArticleService(
            remote: FakeArticleRemoteSource(mode: .failure),
            cache: cacheStore,
            store: InMemoryArticleStore()
        )
        let cachedArticles = try await cacheBackedService.refresh()
        printArticles(cachedArticles, source: "cache fallback")

        printDivider("缓存损坏：清理坏缓存，再把远程错误抛回调用方")
        let corruptedCache = InMemoryCacheStore()
        corruptedCache.seedCorruptedValue("not-json", for: "articles.json")
        let corruptedService = ArticleService(
            remote: FakeArticleRemoteSource(mode: .failure),
            cache: corruptedCache,
            store: InMemoryArticleStore()
        )

        do {
            let _: [String] = try await corruptedService.refresh()
            print("不应该走到这里。")
        } catch {
            print("捕获到预期错误：\(error)")
            let cacheAfterCleanup = try corruptedCache.read(key: "articles.json")
            print("坏缓存是否已被清理：\(cacheAfterCleanup == nil ? "是" : "否")")
        }
    } catch {
        print("Demo 运行失败：\(error)")
    }
}

let semaphore = DispatchSemaphore(value: 0)
Task {
    await runDemo()
    semaphore.signal()
}
semaphore.wait()
