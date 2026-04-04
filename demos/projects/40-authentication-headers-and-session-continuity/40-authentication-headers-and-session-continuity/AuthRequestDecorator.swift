//
//  AuthRequestDecorator.swift
//  40-authentication-headers-and-session-continuity
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

struct Endpoint {
    var path: String
    var method: HTTPMethod
    var queryItems: [URLQueryItem] = []
    var headers: [String: String] = [:]
    var body: Data? = nil
    var auth: AuthRequirement = .none
}

struct AuthRequestDecorator {
    let baseURL: URL
    let authState: AuthState

    func makeRequest(for endpoint: Endpoint) throws -> URLRequest {
        guard var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: false) else {
            throw NetworkError.urlConstructionFailed
        }

        let normalizedPath = endpoint.path.hasPrefix("/") ? endpoint.path : "/" + endpoint.path
        let basePath = components.path.hasSuffix("/") ? String(components.path.dropLast()) : components.path
        components.path = basePath + normalizedPath

        if !endpoint.queryItems.isEmpty {
            components.queryItems = endpoint.queryItems
        }

        guard let url = components.url else {
            throw NetworkError.urlConstructionFailed
        }

        var request = URLRequest(url: url)
        request.httpMethod = endpoint.method.rawValue
        request.httpBody = endpoint.body

        for (key, value) in endpoint.headers {
            request.setValue(value, forHTTPHeaderField: key)
        }

        switch endpoint.auth {
        case .none:
            break
        case .bearerToken:
            guard let token = authState.bearerToken else {
                throw NetworkError.notLoggedIn(requirement: .bearerToken)
            }
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        case .cookieSession:
            guard let sessionCookie = authState.sessionCookie else {
                throw NetworkError.notLoggedIn(requirement: .cookieSession)
            }
            request.setValue(sessionCookie, forHTTPHeaderField: "Cookie")
        }

        return request
    }
}

extension Endpoint {
    static func todoList(limit: Int) -> Endpoint {
        Endpoint(
            path: "/todos",
            method: .get,
            queryItems: [URLQueryItem(name: "limit", value: String(limit))]
        )
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

    static func tokenMe() -> Endpoint {
        Endpoint(path: "/auth/token-me", method: .get, auth: .bearerToken)
    }

    static func adminReport() -> Endpoint {
        Endpoint(path: "/auth/admin-report", method: .get, auth: .bearerToken)
    }

    static func sessionLogin(username: String, password: String) throws -> Endpoint {
        do {
            let body = try JSONEncoder().encode(LoginRequestDTO(username: username, password: password))
            return Endpoint(
                path: "/auth/session-login",
                method: .post,
                headers: ["Content-Type": "application/json"],
                body: body
            )
        } catch {
            throw NetworkError.requestBodyEncodingFailed(underlying: error)
        }
    }

    static func sessionMe() -> Endpoint {
        Endpoint(path: "/auth/session-me", method: .get, auth: .cookieSession)
    }
}
