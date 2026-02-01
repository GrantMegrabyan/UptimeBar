//
//  MonitorFetchError.swift
//  Glancea
//
//  Created by Grant Megrabyan on 01/02/2026.
//

import Foundation

enum MonitorFetchError: Error {
    case invalidURL
    case authenticationFailed
    case serverError(statusCode: Int)
    case networkError(underlying: Error)
    case timeout
    case invalidResponse

    var isRetryable: Bool {
        switch self {
        case .networkError, .timeout, .serverError:
            return true
        case .invalidURL, .authenticationFailed, .invalidResponse:
            return false
        }
    }

    var userMessage: String {
        switch self {
        case .invalidURL:
            return "Invalid server URL — check Settings"
        case .authenticationFailed:
            return "Authentication failed — check your credentials"
        case .serverError(let statusCode):
            return "Server error (\(statusCode)) — the server may be down"
        case .networkError:
            return "Network error — check your connection"
        case .timeout:
            return "Request timed out — server may be unreachable"
        case .invalidResponse:
            return "Invalid response from server"
        }
    }
}
