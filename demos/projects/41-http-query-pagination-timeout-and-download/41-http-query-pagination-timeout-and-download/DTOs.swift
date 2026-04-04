//
//  DTOs.swift
//  41-http-query-pagination-timeout-and-download
//
//  Created by Codex on 2026/4/4.
//

import Foundation

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
