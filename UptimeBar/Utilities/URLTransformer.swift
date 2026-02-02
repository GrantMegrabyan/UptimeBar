//
//  URLTransformer.swift
//  UptimeBar
//
//  Created by Grant Megrabyan on 02/02/2026.
//

import Foundation

struct URLTransformer {
    /// Transforms a health check URL into a service URL suitable for opening in a browser
    static func toServiceURL(_ healthCheckURL: String) -> String {
        guard let url = URL(string: healthCheckURL) else {
            return healthCheckURL
        }

        let path = url.path

        // Common health check path patterns to remove
        let healthCheckPatterns = [
            "/ping",
            "/health",
            "/healthcheck",
            "/healthz",
            "/api/health",
            "/api/healthcheck",
            "/api/ping",
            "/_health",
            "/status"
        ]

        // Check if the path matches any health check pattern
        for pattern in healthCheckPatterns {
            if path.lowercased() == pattern.lowercased() {
                // Remove the health check path and return base URL with trailing slash
                return url.scheme! + "://" + url.host! + (url.port.map { ":\($0)" } ?? "") + "/"
            }
        }

        // If path contains /api/ followed by health-related terms, strip from /api/ onwards
        if path.lowercased().contains("/api/") {
            let healthTerms = ["health", "ping", "status", "check"]
            let pathLower = path.lowercased()

            for term in healthTerms {
                if pathLower.contains("/api/") && pathLower.contains(term) {
                    // Return base URL with trailing slash
                    return url.scheme! + "://" + url.host! + (url.port.map { ":\($0)" } ?? "") + "/"
                }
            }
        }

        // If no health check pattern detected, return original URL
        return healthCheckURL
    }
}
