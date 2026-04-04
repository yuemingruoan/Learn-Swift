import Foundation

struct CacheEnvelope<Value: Codable>: Codable {
    let cachedAt: Date
    let value: Value
}

enum CacheWriteError: Error {
    case encodeFailed(underlying: Error)
    case writeFailed(underlying: Error)
}

enum CacheReadError: Error {
    case readFailed(underlying: Error)
    case decodeFailed(underlying: Error)
}

enum CacheLoadResult<Value> {
    case hit(Value)
    case miss
    case corrupted(underlying: Error)
}

enum DataSource<Value> {
    case cache(Value)
    case remote(Value)
}
