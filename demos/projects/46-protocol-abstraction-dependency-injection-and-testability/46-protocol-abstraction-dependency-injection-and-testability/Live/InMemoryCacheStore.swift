//
//  InMemoryCacheStore.swift
//  46-protocol-abstraction-dependency-injection-and-testability
//
//  Created by Codex on 2026/4/4.
//

import Foundation

final class InMemoryCacheStore: CacheStore {
    private var storage: [String: Data] = [:]

    func read(key: String) throws -> Data? {
        storage[key]
    }

    func write(key: String, data: Data) throws {
        storage[key] = data
    }

    func remove(key: String) throws {
        storage.removeValue(forKey: key)
    }

    func seedCorruptedValue(_ text: String, for key: String) {
        storage[key] = Data(text.utf8)
    }
}
