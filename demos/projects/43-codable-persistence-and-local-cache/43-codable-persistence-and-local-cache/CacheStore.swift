import Foundation

enum AppPaths {
    static func cacheFileURL(fileName: String) throws -> URL {
        let fm = FileManager.default
        let base = try fm.url(
            for: .cachesDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )

        let folder = base
            .appendingPathComponent("learn-swift", isDirectory: true)
            .appendingPathComponent("43-cache-demo", isDirectory: true)

        try fm.createDirectory(at: folder, withIntermediateDirectories: true)
        return folder.appendingPathComponent(fileName)
    }
}

func saveSnapshot<T: Encodable>(_ value: T, to fileURL: URL) throws {
    do {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(value)
        try data.write(to: fileURL, options: [.atomic])
    } catch let error as EncodingError {
        throw CacheWriteError.encodeFailed(underlying: error)
    } catch {
        throw CacheWriteError.writeFailed(underlying: error)
    }
}

func loadSnapshot<T: Decodable>(_ type: T.Type, from fileURL: URL) throws -> T? {
    do {
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            return nil
        }

        let data = try Data(contentsOf: fileURL)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(T.self, from: data)
    } catch let error as DecodingError {
        throw CacheReadError.decodeFailed(underlying: error)
    } catch {
        throw CacheReadError.readFailed(underlying: error)
    }
}

func loadCacheOrReportCorruption<T: Decodable>(_ type: T.Type, from fileURL: URL) -> CacheLoadResult<T> {
    do {
        if let value = try loadSnapshot(T.self, from: fileURL) {
            return .hit(value)
        }
        return .miss
    } catch {
        return .corrupted(underlying: error)
    }
}

func deleteFileIfExists(_ url: URL) {
    do {
        if FileManager.default.fileExists(atPath: url.path) {
            try FileManager.default.removeItem(at: url)
        }
    } catch {
        print("[warn] 删除缓存失败：\(error)")
    }
}

func getTodos(api: FakeRemoteAPI) async throws -> DataSource<[TodoSnapshot]> {
    let cacheURL = try AppPaths.cacheFileURL(fileName: "todos.json")

    switch loadCacheOrReportCorruption(CacheEnvelope<[TodoSnapshot]>.self, from: cacheURL) {
    case .hit(let envelope):
        print("缓存状态：hit")
        print("cachedAt = \(envelope.cachedAt)")
        return .cache(envelope.value)

    case .miss:
        print("缓存状态：miss")
        print("本地没有快照，准备走远程")

    case .corrupted(let error):
        print("缓存状态：corrupted")
        print("损坏原因：\(error)")
        print("执行恢复：删除坏文件，再重新请求远程")
        deleteFileIfExists(cacheURL)
    }

    let dtos = try await api.fetchTodos()
    let snapshots = dtos.map(TodoSnapshot.init(dto:))

    do {
        let envelope = CacheEnvelope(cachedAt: Date(), value: snapshots)
        try saveSnapshot(envelope, to: cacheURL)
        print("远程成功：已把最新待办快照写回缓存")
    } catch {
        print("[warn] 回写缓存失败，但不影响主流程：\(error)")
    }

    return .remote(snapshots)
}
