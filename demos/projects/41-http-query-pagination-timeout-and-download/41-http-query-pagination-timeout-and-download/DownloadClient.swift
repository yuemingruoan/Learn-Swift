//
//  DownloadClient.swift
//  41-http-query-pagination-timeout-and-download
//
//  Created by Codex on 2026/4/4.
//

import Foundation

struct DownloadClient {
    let baseURL: URL
    let session: URLSession
    let authState: AuthState

    init(baseURL: URL, session: URLSession = .shared, authState: AuthState) {
        self.baseURL = baseURL
        self.session = session
        self.authState = authState
    }

    func previewRequest(for endpoint: Endpoint) throws -> URLRequest {
        try endpoint.makeRequest(baseURL: baseURL, authState: authState)
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
            .flatMap(parseSuggestedFilename(from:))

        return DownloadedFile(
            temporaryFileURL: temporaryFileURL,
            suggestedFilename: suggestedFilename,
            contentType: httpResponse.value(forHTTPHeaderField: "Content-Type")
        )
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
