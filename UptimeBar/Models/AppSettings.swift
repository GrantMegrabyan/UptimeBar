//
//  AppSettings.swift
//  UptimeBar
//
//  Created by Grant Megrabyan on 29/01/2026.
//

import Foundation
import SwiftUI

enum AuthenticationType: String, CaseIterable {
    case apiKey = "apiKey"
    case basicAuth = "basicAuth"
    case none = "none"

    var displayName: String {
        switch self {
        case .apiKey: return "API Key"
        case .basicAuth: return "Username & Password"
        case .none: return "None"
        }
    }
}

@MainActor
@Observable
class AppSettings {
    var uptimeKumaBaseURL: String
    var authenticationType: AuthenticationType
    var uptimeKumaAPIKey: String
    var uptimeKumaUsername: String
    var uptimeKumaPassword: String
    var refreshInterval: Int
    var showUnhealthyCountInMenuBar: Bool
    var statusPageGroupingEnabled: Bool
    var statusPageSlugs: [String]

    init() {
        if let storedBaseURL = UserDefaults.standard.string(forKey: "uptimeKumaBaseURL") {
            self.uptimeKumaBaseURL = Self.normalizeBaseURLString(storedBaseURL)
        } else {
            let legacyMetricsURL = UserDefaults.standard.string(forKey: "uptimeKumaURL") ?? ""
            self.uptimeKumaBaseURL = Self.normalizeBaseURLString(legacyMetricsURL)
        }

        // Authentication type defaults to .apiKey for new users, preserves existing for migrations
        if let storedAuthType = UserDefaults.standard.string(forKey: "authenticationType"),
           let authType = AuthenticationType(rawValue: storedAuthType) {
            self.authenticationType = authType
        } else {
            // Check if user has existing username/password credentials (migration case)
            let hasExistingUsername = !(UserDefaults.standard.string(forKey: "uptimeKumaUsername") ?? "").isEmpty
            let hasExistingPassword = !KeychainStore.getUptimeKumaPassword().isEmpty
            if hasExistingUsername || hasExistingPassword {
                self.authenticationType = .basicAuth
            } else {
                self.authenticationType = .apiKey
            }
        }

        self.uptimeKumaAPIKey = KeychainStore.getUptimeKumaAPIKey()
        self.uptimeKumaUsername = UserDefaults.standard.string(forKey: "uptimeKumaUsername") ?? ""
        // Password is stored in Keychain.
        self.uptimeKumaPassword = KeychainStore.getUptimeKumaPassword()

        // Normalize refresh interval to one of the valid preset values
        let savedInterval = UserDefaults.standard.integer(forKey: "refreshInterval") == 0 ? 120 : UserDefaults.standard.integer(forKey: "refreshInterval")
        self.refreshInterval = Self.normalizeRefreshInterval(savedInterval)

        // Default to true if not set
        if UserDefaults.standard.object(forKey: "showUnhealthyCountInMenuBar") == nil {
            self.showUnhealthyCountInMenuBar = true
        } else {
            self.showUnhealthyCountInMenuBar = UserDefaults.standard.bool(forKey: "showUnhealthyCountInMenuBar")
        }

        if UserDefaults.standard.object(forKey: "statusPageGroupingEnabled") == nil {
            self.statusPageGroupingEnabled = false
        } else {
            self.statusPageGroupingEnabled = UserDefaults.standard.bool(forKey: "statusPageGroupingEnabled")
        }

        let storedSlugs = UserDefaults.standard.stringArray(forKey: "statusPageSlugs") ?? []
        self.statusPageSlugs = Self.normalizeStatusPageSlugs(storedSlugs)
    }

    /// Valid refresh interval presets in seconds
    static let validRefreshIntervals = [30, 60, 120, 300, 600]

    /// Normalizes a refresh interval to the nearest valid preset value
    private static func normalizeRefreshInterval(_ interval: Int) -> Int {
        // Find the closest valid interval
        let closest = validRefreshIntervals.min(by: { abs($0 - interval) < abs($1 - interval) })
        return closest ?? 120  // Default to 2 minutes if something goes wrong
    }

    static let defaultStatusPageSlug = "default"

    var statusPageSlugsWithDefault: [String] {
        statusPageSlugs + [Self.defaultStatusPageSlug]
    }

    private static func normalizeStatusPageSlugs(_ slugs: [String]) -> [String] {
        var seen: Set<String> = []
        var normalized: [String] = []
        for slug in slugs {
            let trimmed = slug.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { continue }
            guard trimmed.lowercased() != defaultStatusPageSlug else { continue }
            let key = trimmed.lowercased()
            if seen.contains(key) { continue }
            seen.insert(key)
            normalized.append(trimmed)
        }
        return normalized
    }

    var isConfigured: Bool {
        !normalizedBaseURL.isEmpty
    }

    var urlValidationError: String? {
        let trimmed = normalizedBaseURL
        if trimmed.isEmpty { return nil }
        guard let url = URL(string: trimmed) else {
            return "Invalid URL format"
        }
        guard let scheme = url.scheme, ["http", "https"].contains(scheme.lowercased()) else {
            return "URL must start with http:// or https://"
        }
        guard url.host != nil else {
            return "URL must include a hostname"
        }
        if url.path == "/metrics" || url.path.hasSuffix("/metrics") {
            return "Base URL should not include /metrics"
        }
        return nil
    }

    var isURLValid: Bool {
        let trimmed = normalizedBaseURL
        return trimmed.isEmpty || urlValidationError == nil
    }

    var normalizedBaseURL: String {
        Self.normalizeBaseURLString(uptimeKumaBaseURL)
    }

    var metricsURLString: String? {
        let base = normalizedBaseURL
        guard !base.isEmpty else { return nil }
        return "\(base)/metrics"
    }

    var statusPageBaseURLString: String? {
        let base = normalizedBaseURL
        guard !base.isEmpty else { return nil }
        return "\(base)/api/status-page"
    }

    var metricsURL: URL? {
        guard let urlString = metricsURLString else { return nil }
        return URL(string: urlString)
    }

    var statusPageBaseURL: URL? {
        guard let urlString = statusPageBaseURLString else { return nil }
        return URL(string: urlString)
    }

    private static func normalizeBaseURLString(_ input: String) -> String {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return "" }

        var base = trimmed
        if base.hasSuffix("/") {
            base = String(base.dropLast())
        }

        return base
    }

    func save() {
        let base = normalizedBaseURL
        UserDefaults.standard.set(base, forKey: "uptimeKumaBaseURL")
        if let metricsURLString {
            UserDefaults.standard.set(metricsURLString, forKey: "uptimeKumaURL")
        }
        UserDefaults.standard.set(authenticationType.rawValue, forKey: "authenticationType")
        KeychainStore.setUptimeKumaAPIKey(uptimeKumaAPIKey)
        UserDefaults.standard.set(uptimeKumaUsername, forKey: "uptimeKumaUsername")
        KeychainStore.setUptimeKumaPassword(uptimeKumaPassword)
        UserDefaults.standard.set(refreshInterval, forKey: "refreshInterval")
        UserDefaults.standard.set(showUnhealthyCountInMenuBar, forKey: "showUnhealthyCountInMenuBar")
        UserDefaults.standard.set(statusPageGroupingEnabled, forKey: "statusPageGroupingEnabled")
        UserDefaults.standard.set(statusPageSlugs, forKey: "statusPageSlugs")
    }
}

@MainActor
extension AppSettings {
    /// Preview-only factory method with mock data that doesn't persist to UserDefaults
    static func preview(
        url: String = "http://192.168.1.1:3001",
        authenticationType: AuthenticationType = .basicAuth,
        apiKey: String = "",
        username: String = "preview-user",
        password: String = "preview-pass",
        refreshInterval: Int = 5,
        showUnhealthyCountInMenuBar: Bool = true,
        statusPageGroupingEnabled: Bool = false,
        statusPageSlugs: [String] = []
    ) -> AppSettings {
        let settings = AppSettings()
        // Override with preview-specific values
        settings.uptimeKumaBaseURL = url
        settings.authenticationType = authenticationType
        settings.uptimeKumaAPIKey = apiKey
        settings.uptimeKumaUsername = username
        settings.uptimeKumaPassword = password
        settings.refreshInterval = refreshInterval
        settings.showUnhealthyCountInMenuBar = showUnhealthyCountInMenuBar
        settings.statusPageGroupingEnabled = statusPageGroupingEnabled
        settings.statusPageSlugs = statusPageSlugs
        return settings
    }
    
    static func previewEmpty() -> AppSettings {
        let settings = AppSettings()
        // Override with preview-specific values
        settings.uptimeKumaBaseURL = ""
        settings.authenticationType = .apiKey
        settings.uptimeKumaAPIKey = ""
        settings.uptimeKumaUsername = ""
        settings.uptimeKumaPassword = ""
        settings.refreshInterval = 0
        settings.statusPageGroupingEnabled = false
        settings.statusPageSlugs = []
        return settings
    }
}
