//
//  NetworkClient.swift
//  41-http-query-pagination-timeout-and-download
//
//  Created by Codex on 2026/4/4.
//

import Foundation

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

    func previewRequest(for endpoint: Endpoint) throws -> URLRequest {
        try endpoint.makeRequest(baseURL: baseURL, authState: authState)
    }

    func send<T: Decodable>(_ endpoint: Endpoint, as type: T.Type) async throws -> T {
        let request = try endpoint.makeRequest(baseURL: baseURL, authState: authState)
        let (data, _) = try await loadData(for: request)

        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw NetworkError.decodingFailed(underlying: error, body: data)
        }
    }

    private func loadData(for request: URLRequest) async throws -> (Data, HTTPURLResponse) {
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

        return (data, httpResponse)
    }
}

struct LearningResourcesAPI {
    let client: NetworkClient
    let downloadClient: DownloadClient
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
        try await downloadClient.download(.downloadGuide(slug: slug))
    }
}
