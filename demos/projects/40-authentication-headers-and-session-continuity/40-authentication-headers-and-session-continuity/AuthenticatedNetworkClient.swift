//
//  AuthenticatedNetworkClient.swift
//  40-authentication-headers-and-session-continuity
//
//  Created by Codex on 2026/4/4.
//

import Foundation

enum NetworkError: Error {
    case urlConstructionFailed
    case requestBodyEncodingFailed(underlying: Error)
    case transportFailed(underlying: Error)
    case nonHTTPResponse
    case badStatusCode(code: Int, body: Data?)
    case decodingFailed(underlying: Error, body: Data)
    case notLoggedIn(requirement: AuthRequirement)
    case unauthorized(requirement: AuthRequirement, body: Data?)
    case forbidden(requirement: AuthRequirement, body: Data?)
}

struct AuthenticatedNetworkClient {
    private let session: URLSession
    private let decoder: JSONDecoder
    private let requestDecorator: AuthRequestDecorator
    private let authState: AuthState

    init(
        baseURL: URL,
        session: URLSession = .shared,
        authState: AuthState,
        decoder: JSONDecoder = JSONDecoder()
    ) {
        self.session = session
        self.decoder = decoder
        self.requestDecorator = AuthRequestDecorator(baseURL: baseURL, authState: authState)
        self.authState = authState
    }

    func previewRequest(for endpoint: Endpoint) throws -> URLRequest {
        try requestDecorator.makeRequest(for: endpoint)
    }

    func send<T: Decodable>(_ endpoint: Endpoint, as type: T.Type) async throws -> T {
        let request = try requestDecorator.makeRequest(for: endpoint)
        let (data, _) = try await loadData(for: request, requirement: endpoint.auth)

        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw NetworkError.decodingFailed(underlying: error, body: data)
        }
    }

    func sendWithResponse<T: Decodable>(_ endpoint: Endpoint, as type: T.Type) async throws -> (T, HTTPURLResponse) {
        let request = try requestDecorator.makeRequest(for: endpoint)
        let (data, httpResponse) = try await loadData(for: request, requirement: endpoint.auth)

        do {
            return (try decoder.decode(T.self, from: data), httpResponse)
        } catch {
            throw NetworkError.decodingFailed(underlying: error, body: data)
        }
    }

    private func loadData(for request: URLRequest, requirement: AuthRequirement) async throws -> (Data, HTTPURLResponse) {
        let data: Data
        let response: URLResponse

        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw NetworkError.transportFailed(underlying: error)
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.nonHTTPResponse
        }

        switch httpResponse.statusCode {
        case 200...299:
            return (data, httpResponse)
        case 401:
            authState.clear(for: requirement)
            throw NetworkError.unauthorized(requirement: requirement, body: data)
        case 403:
            throw NetworkError.forbidden(requirement: requirement, body: data)
        default:
            throw NetworkError.badStatusCode(code: httpResponse.statusCode, body: data)
        }
    }
}
