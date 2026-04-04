import Foundation

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
}

extension Endpoint {
    func makeRequest(baseURL: URL) throws -> URLRequest {
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

        for (key, value) in headers {
            request.setValue(value, forHTTPHeaderField: key)
        }

        request.httpBody = body
        return request
    }

    static func todoDetail(id: Int) -> Endpoint {
        Endpoint(path: "/todos/\(id)", method: .get)
    }

    static func todoList(limit: Int) -> Endpoint {
        Endpoint(
            path: "/todos",
            method: .get,
            queryItems: [URLQueryItem(name: "limit", value: String(limit))]
        )
    }

    static func createStudyRecord(_ input: CreateStudyRecordRequestDTO) throws -> Endpoint {
        do {
            let body = try JSONEncoder().encode(input)
            return Endpoint(
                path: "/study-records",
                method: .post,
                headers: ["Content-Type": "application/json"],
                body: body
            )
        } catch {
            throw NetworkError.requestBodyEncodingFailed(underlying: error)
        }
    }

    static func badTodoJSON() -> Endpoint {
        Endpoint(path: "/diagnostics/bad-todo-json", method: .get)
    }

    static func serverError() -> Endpoint {
        Endpoint(path: "/diagnostics/server-error", method: .get)
    }
}
