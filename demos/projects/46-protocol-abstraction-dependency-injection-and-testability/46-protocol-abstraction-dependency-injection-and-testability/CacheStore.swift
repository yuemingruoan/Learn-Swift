//
//  CacheStore.swift
//  46-protocol-abstraction-dependency-injection-and-testability
//
//  Created by Codex on 2026/4/4.
//

import Foundation

protocol CacheStore {
    func read(key: String) throws -> Data?
    func write(key: String, data: Data) throws
    func remove(key: String) throws
}
