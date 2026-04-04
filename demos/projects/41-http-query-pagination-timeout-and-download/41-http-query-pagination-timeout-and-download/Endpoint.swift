//
//  Endpoint.swift
//  41-http-query-pagination-timeout-and-download
//
//  Created by Codex on 2026/4/4.
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

struct Endpoint {
    var path: String
    var method: HTTPMethod
    var queryItems: [URLQueryItem] = []
    var headers: [String: String] = [:]
    var body: Data? = nil
    var auth: AuthRequirement = .none
    var timeoutInterval: TimeInterval? = nil

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
}

extension Endpoint {
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
