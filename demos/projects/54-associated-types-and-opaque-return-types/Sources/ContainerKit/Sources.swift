import Foundation

public struct User: Equatable, Sendable {
    public let id: Int
    public let name: String

    public init(id: Int, name: String) {
        self.id = id
        self.name = name
    }
}

public protocol PaginatedSource<Element> {
    associatedtype Element
    var pageSize: Int { get }
    func fetch(page: Int) async throws -> [Element]
}

public struct UserRemoteSource: PaginatedSource {
    public let pageSize: Int

    public init(pageSize: Int = 20) {
        self.pageSize = pageSize
    }

    public func fetch(page: Int) async throws -> [User] {
        (0..<pageSize).map { i in
            User(id: page * pageSize + i, name: "User \(page)-\(i)")
        }
    }
}

public func makeUserSource() -> some PaginatedSource<User> {
    UserRemoteSource()
}
