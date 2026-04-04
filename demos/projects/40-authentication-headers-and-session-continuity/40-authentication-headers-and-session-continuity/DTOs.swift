//
//  DTOs.swift
//  40-authentication-headers-and-session-continuity
//
//  Created by Codex on 2026/4/4.
//

import Foundation

struct TodoDTO: Decodable {
    let userId: Int
    let id: Int
    let title: String
    let completed: Bool
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

struct SessionLoginResponseDTO: Decodable {
    let message: String
    let user: UserProfileDTO
}
