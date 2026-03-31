//
//  main.swift
//  41-http-query-pagination-timeout-and-download
//
//  Created by Codex on 2026/3/31.
//

import Foundation

enum APIConfig {
    static let baseURL = URL(string: "http://127.0.0.1:3456")!
}

enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
}

enum AuthRequirement {
    case none
    case bearerToken
}

final class AuthState {
    var bearerToken: String?
}

struct Endpoint {
    var path: String
    var method: HTTPMethod
    var queryItems: [URLQueryItem] = []
    var headers: [String: String] = [:]
    var body: Data? = nil
    var auth: AuthRequirement = .none
    var timeoutInterval: TimeInterval? = nil
}

enum ResourceCategory: String, Decodable {
    case networking
    case persistence
    case architecture
}

enum ResourceSortField: String {
    case publishedAt
    case durationMinutes
    case title
}

enum SortOrder: String {
    case asc
    case desc
}

struct ResourceQuery {
    var keyword: String?
    var category: ResourceCategory?
    var page: Int
    var limit: Int
    var sort: ResourceSortField
    var order: SortOrder

    var queryItems: [URLQueryItem] {
        var items = [
            URLQueryItem(name: "page", value: String(page)),
            URLQueryItem(name: "limit", value: String(limit)),
            URLQueryItem(name: "sort", value: sort.rawValue),
            URLQueryItem(name: "order", value: order.rawValue)
        ]

        if let keyword, !keyword.isEmpty {
            items.append(URLQueryItem(name: "q", value: keyword))
        }

        if let category {
            items.append(URLQueryItem(name: "category", value: category.rawValue))
        }

        return items
    }
}

struct LoginRequestDTO: Encodable {
    let username: String
    let password: String
}

struct UserProfileDTO: Decodable {
    let id: Int
    let username: String
    let name: String
    let role: String
    let preferredTrack: String
}

struct TokenLoginResponseDTO: Decodable {
    let accessToken: String
    let tokenType: String
    let expiresIn: Int
    let user: UserProfileDTO
}

struct LearningResourceDTO: Decodable {
    let id: Int
    let title: String
    let category: ResourceCategory
    let level: String
    let durationMinutes: Int
    let publishedAt: String
    let downloadSlug: String
}

struct PageDTO<Item: Decodable>: Decodable {
    let items: [Item]
    let page: Int
    let limit: Int
    let total: Int
    let hasMore: Bool
}

struct SlowSummaryDTO: Decodable {
    let title: String
    let delayMs: Int
    let note: String
}

struct DownloadedFile {
    let temporaryFileURL: URL
    let suggestedFilename: String?
    let contentType: String?
}

enum NetworkError: Error {
    case urlConstructionFailed
    case requestBodyEncodingFailed(underlying: Error)
    case notLoggedIn
    case timeout
    case transportFailed(underlying: Error)
    case nonHTTPResponse
    case badStatusCode(code: Int, body: Data?)
    case decodingFailed(underlying: Error, body: Data)
}

extension Endpoint {
    func makeRequest(baseURL: URL, authState: AuthState?) throws -> URLRequest {
        guard var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: false) else {
            throw NetworkError.urlConstructionFailed
        }

        let normalizedPath = path.hasPrefix("/") ? path : "/" + path
        let basePath = components.path.hasSuffix("/") ? String(components.path.dropLast()) : components.path
        components.path = basePath + normalizedPath

        if !queryItems.isEmpty {
            components.queryItems = queryItems
        }

        guard let url = components.url else {
            throw NetworkError.urlConstructionFailed
        }

        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.httpBody = body

        for (key, value) in headers {
            request.setValue(value, forHTTPHeaderField: key)
        }

        if let timeoutInterval {
            request.timeoutInterval = timeoutInterval
        }

        switch auth {
        case .none:
            break
        case .bearerToken:
            guard let token = authState?.bearerToken else {
                throw NetworkError.notLoggedIn
            }
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        return request
    }

    static func tokenLogin(username: String, password: String) throws -> Endpoint {
        do {
            let body = try JSONEncoder().encode(LoginRequestDTO(username: username, password: password))
            return Endpoint(
                path: "/auth/token-login",
                method: .post,
                headers: ["Content-Type": "application/json"],
                body: body
            )
        } catch {
            throw NetworkError.requestBodyEncodingFailed(underlying: error)
        }
    }

    static func learningResources(query: ResourceQuery) -> Endpoint {
        Endpoint(
            path: "/learning-resources",
            method: .get,
            queryItems: query.queryItems,
            auth: .bearerToken
        )
    }

    static func slowSummary(delayMs: Int, timeoutInterval: TimeInterval) -> Endpoint {
        Endpoint(
            path: "/slow-summary",
            method: .get,
            queryItems: [URLQueryItem(name: "delayMs", value: String(delayMs))],
            auth: .bearerToken,
            timeoutInterval: timeoutInterval
        )
    }

    static func downloadGuide(slug: String) -> Endpoint {
        Endpoint(
            path: "/downloads/\(slug)",
            method: .get,
            auth: .bearerToken
        )
    }
}

struct NetworkClient {
    let baseURL: URL
    let session: URLSession
    let authState: AuthState
    let decoder: JSONDecoder

    init(
        baseURL: URL,
        session: URLSession = .shared,
        authState: AuthState,
        decoder: JSONDecoder = JSONDecoder()
    ) {
        self.baseURL = baseURL
        self.session = session
        self.authState = authState
        self.decoder = decoder
    }

    func send<T: Decodable>(_ endpoint: Endpoint, as type: T.Type) async throws -> T {
        let request = try endpoint.makeRequest(baseURL: baseURL, authState: authState)
        return try await send(request, as: type)
    }

    func send<T: Decodable>(_ request: URLRequest, as type: T.Type) async throws -> T {
        let data: Data
        let response: URLResponse

        do {
            (data, response) = try await session.data(for: request)
        } catch let error as URLError where error.code == .timedOut {
            throw NetworkError.timeout
        } catch {
            throw NetworkError.transportFailed(underlying: error)
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.nonHTTPResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            throw NetworkError.badStatusCode(code: httpResponse.statusCode, body: data)
        }

        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw NetworkError.decodingFailed(underlying: error, body: data)
        }
    }

    func download(_ endpoint: Endpoint) async throws -> DownloadedFile {
        let request = try endpoint.makeRequest(baseURL: baseURL, authState: authState)

        let temporaryFileURL: URL
        let response: URLResponse

        do {
            (temporaryFileURL, response) = try await session.download(for: request)
        } catch let error as URLError where error.code == .timedOut {
            throw NetworkError.timeout
        } catch {
            throw NetworkError.transportFailed(underlying: error)
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.nonHTTPResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            let data = try? Data(contentsOf: temporaryFileURL)
            throw NetworkError.badStatusCode(code: httpResponse.statusCode, body: data)
        }

        let suggestedFilename = httpResponse.value(forHTTPHeaderField: "Content-Disposition")
            .flatMap(parseSuggestedFilename)

        return DownloadedFile(
            temporaryFileURL: temporaryFileURL,
            suggestedFilename: suggestedFilename,
            contentType: httpResponse.value(forHTTPHeaderField: "Content-Type")
        )
    }
}

struct LearningResourcesAPI {
    let client: NetworkClient
    let authState: AuthState

    func loginDemoUser() async throws -> UserProfileDTO {
        let response: TokenLoginResponseDTO = try await client.send(
            try .tokenLogin(username: "swift-demo", password: "123456"),
            as: TokenLoginResponseDTO.self
        )

        authState.bearerToken = response.accessToken
        return response.user
    }

    func listResources(query: ResourceQuery) async throws -> PageDTO<LearningResourceDTO> {
        try await client.send(.learningResources(query: query), as: PageDTO<LearningResourceDTO>.self)
    }

    func fetchSlowSummary(delayMs: Int, timeoutInterval: TimeInterval) async throws -> SlowSummaryDTO {
        try await client.send(
            .slowSummary(delayMs: delayMs, timeoutInterval: timeoutInterval),
            as: SlowSummaryDTO.self
        )
    }

    func downloadGuide(slug: String) async throws -> DownloadedFile {
        try await client.download(.downloadGuide(slug: slug))
    }
}

func parseSuggestedFilename(from contentDisposition: String) -> String? {
    for part in contentDisposition.split(separator: ";") {
        let trimmed = part.trimmingCharacters(in: .whitespaces)
        if trimmed.hasPrefix("filename=") {
            return String(trimmed.dropFirst("filename=".count)).trimmingCharacters(in: CharacterSet(charactersIn: "\""))
        }
    }

    return nil
}

func printDivider(_ title: String) {
    print("")
    print("======== \(title) ========")
}

func printUser(_ user: UserProfileDTO) {
    print("用户：\(user.name) (@\(user.username))")
    print("偏好主线：\(user.preferredTrack)")
}

func printPage(_ page: PageDTO<LearningResourceDTO>) {
    print("page=\(page.page) limit=\(page.limit) total=\(page.total) hasMore=\(page.hasMore)")
    for item in page.items {
        print("- [\(item.category.rawValue)] \(item.title) / \(item.durationMinutes) 分钟 / 下载标识 \(item.downloadSlug)")
    }
}

func bodyPreview(from data: Data?) -> String {
    guard
        let data,
        !data.isEmpty,
        let text = String(data: data, encoding: .utf8)
    else {
        return "<empty>"
    }

    return text.replacingOccurrences(of: "\n", with: " ")
}

func printError(_ error: Error) {
    switch error {
    case NetworkError.notLoggedIn:
        print("错误：当前请求需要登录态。")
    case NetworkError.timeout:
        print("错误：请求超时。")
    case NetworkError.urlConstructionFailed:
        print("错误：URL 构造失败。")
    case let NetworkError.requestBodyEncodingFailed(underlying):
        print("错误：请求体编码失败 -> \(underlying)")
    case let NetworkError.transportFailed(underlying):
        print("错误：发送阶段失败 -> \(underlying)")
    case NetworkError.nonHTTPResponse:
        print("错误：响应不是 HTTPURLResponse。")
    case let NetworkError.badStatusCode(code, body):
        print("错误：状态码异常 -> \(code)")
        print("响应体预览：\(bodyPreview(from: body))")
    case let NetworkError.decodingFailed(underlying, body):
        print("错误：响应体解码失败 -> \(underlying)")
        print("原始响应体：\(bodyPreview(from: body))")
    default:
        print("错误：\(error)")
    }
}

func previewDownloadedFile(_ downloadedFile: DownloadedFile) {
    print("临时文件：\(downloadedFile.temporaryFileURL.path)")
    print("Content-Type：\(downloadedFile.contentType ?? "<none>")")
    print("建议文件名：\(downloadedFile.suggestedFilename ?? "<none>")")

    if
        let text = try? String(contentsOf: downloadedFile.temporaryFileURL, encoding: .utf8)
    {
        let previewLines = text.split(separator: "\n").prefix(4).joined(separator: "\n")
        print("文件预览：")
        print(previewLines)
    }
}

func runDemo() async {
    let authState = AuthState()
    let client = NetworkClient(baseURL: APIConfig.baseURL, authState: authState)
    let api = LearningResourcesAPI(client: client, authState: authState)

    printDivider("先登录，沿用第 40 章的 Bearer Token 建模")
    do {
        let user = try await api.loginDemoUser()
        printUser(user)
    } catch {
        printError(error)
        return
    }

    printDivider("优雅模型：把筛选、分页、排序收进 ResourceQuery")
    let firstQuery = ResourceQuery(
        keyword: nil,
        category: .networking,
        page: 1,
        limit: 3,
        sort: .publishedAt,
        order: .desc
    )

    do {
        let page = try await api.listResources(query: firstQuery)
        printPage(page)
    } catch {
        printError(error)
    }

    printDivider("只改 page，就复用同一套 Endpoint / NetworkClient")
    do {
        let secondPage = try await api.listResources(
            query: ResourceQuery(
                keyword: nil,
                category: .networking,
                page: 2,
                limit: 3,
                sort: .publishedAt,
                order: .desc
            )
        )
        printPage(secondPage)
    } catch {
        printError(error)
    }

    printDivider("搜索词是可选的，只在需要时才进入 queryItems")
    do {
        let keywordPage = try await api.listResources(
            query: ResourceQuery(
                keyword: "接口",
                category: .networking,
                page: 1,
                limit: 5,
                sort: .publishedAt,
                order: .asc
            )
        )
        printPage(keywordPage)
    } catch {
        printError(error)
    }

    printDivider("只改分类和排序，模型仍然稳定")
    do {
        let architecturePage = try await api.listResources(
            query: ResourceQuery(
                keyword: nil,
                category: .architecture,
                page: 1,
                limit: 5,
                sort: .title,
                order: .asc
            )
        )
        printPage(architecturePage)
    } catch {
        printError(error)
    }

    printDivider("timeout 属于网络错误，而不是 HTTP 状态码")
    do {
        let _: SlowSummaryDTO = try await api.fetchSlowSummary(delayMs: 2000, timeoutInterval: 1.0)
    } catch {
        printError(error)
    }

    printDivider("下载：响应不再是 JSON，而是临时文件 URL")
    do {
        let downloadedFile = try await api.downloadGuide(slug: "endpoint-modeling-checklist")
        previewDownloadedFile(downloadedFile)
    } catch {
        printError(error)
    }

    printDivider("这一章的收益")
    print("ResourceQuery、PageDTO、DownloadedFile 让“查询、分页、超时、下载”各自落在明确模型上。")
    print("读者能直接看到：建模之后，新增能力不是把 if-else 塞满，而是扩展稳定结构。")
}

let demoSemaphore = DispatchSemaphore(value: 0)

Task {
    await runDemo()
    demoSemaphore.signal()
}

demoSemaphore.wait()
