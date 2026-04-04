//
//  AuthState.swift
//  40-authentication-headers-and-session-continuity
//
//  Created by Codex on 2026/4/4.
//

import Foundation

enum AuthRequirement: String {
    case none = "无需鉴权"
    case bearerToken = "Bearer Token"
    case cookieSession = "Cookie / Session"
}

final class AuthState {
    var bearerToken: String?
    var sessionCookie: String?

    func clear(for requirement: AuthRequirement) {
        switch requirement {
        case .none:
            break
        case .bearerToken:
            bearerToken = nil
        case .cookieSession:
            sessionCookie = nil
        }
    }
}
