//
//  AppSettings.swift
//  UptimeBar
//
//  Created by Grant Megrabyan on 29/01/2026.
//

import Foundation
import SwiftUI

@MainActor
@Observable
class AppSettings {
    var uptimeKumaURL: String
    var uptimeKumaUsername: String
    var uptimeKumaPassword: String
    var refreshInterval: Int
    var showUnhealthyCountInMenuBar: Bool

    init() {
        self.uptimeKumaURL = UserDefaults.standard.string(forKey: "uptimeKumaURL") ?? ""
        self.uptimeKumaUsername = UserDefaults.standard.string(forKey: "uptimeKumaUsername") ?? ""
        self.uptimeKumaPassword = UserDefaults.standard.string(forKey: "uptimeKumaPassword") ?? ""

        // Normalize refresh interval to one of the valid preset values
        let savedInterval = UserDefaults.standard.integer(forKey: "refreshInterval") == 0 ? 120 : UserDefaults.standard.integer(forKey: "refreshInterval")
        self.refreshInterval = Self.normalizeRefreshInterval(savedInterval)

        // Default to true if not set
        if UserDefaults.standard.object(forKey: "showUnhealthyCountInMenuBar") == nil {
            self.showUnhealthyCountInMenuBar = true
        } else {
            self.showUnhealthyCountInMenuBar = UserDefaults.standard.bool(forKey: "showUnhealthyCountInMenuBar")
        }
    }

    /// Valid refresh interval presets in seconds
    static let validRefreshIntervals = [30, 60, 120, 300, 600]

    /// Normalizes a refresh interval to the nearest valid preset value
    private static func normalizeRefreshInterval(_ interval: Int) -> Int {
        // Find the closest valid interval
        let closest = validRefreshIntervals.min(by: { abs($0 - interval) < abs($1 - interval) })
        return closest ?? 120  // Default to 2 minutes if something goes wrong
    }

    var isConfigured: Bool {
        !uptimeKumaURL.isEmpty
    }

    /// Validates a URL string and returns an error message if invalid
    /// - Parameter urlString: The URL string to validate
    /// - Returns: An error message if invalid, or nil if valid or empty
    static func validateURL(_ urlString: String) -> String? {
        let trimmed = urlString.trimmingCharacters(in: .whitespacesAndNewlines)
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
        return nil
    }

    var urlValidationError: String? {
        Self.validateURL(uptimeKumaURL)
    }

    var isURLValid: Bool {
        urlValidationError == nil
    }

    func save() {
        UserDefaults.standard.set(uptimeKumaURL, forKey: "uptimeKumaURL")
        UserDefaults.standard.set(uptimeKumaUsername, forKey: "uptimeKumaUsername")
        UserDefaults.standard.set(uptimeKumaPassword, forKey: "uptimeKumaPassword")
        UserDefaults.standard.set(refreshInterval, forKey: "refreshInterval")
        UserDefaults.standard.set(showUnhealthyCountInMenuBar, forKey: "showUnhealthyCountInMenuBar")
    }
}

#if DEBUG
@MainActor
extension AppSettings {
    /// Preview-only factory method with mock data that doesn't persist to UserDefaults
    static func preview(
        url: String = "http://192.168.1.1:3001/metrics",
        username: String = "preview-user",
        password: String = "preview-pass",
        refreshInterval: Int = 5,
        showUnhealthyCountInMenuBar: Bool = true
    ) -> AppSettings {
        let settings = AppSettings()
        // Override with preview-specific values
        settings.uptimeKumaURL = url
        settings.uptimeKumaUsername = username
        settings.uptimeKumaPassword = password
        settings.refreshInterval = refreshInterval
        settings.showUnhealthyCountInMenuBar = showUnhealthyCountInMenuBar
        return settings
    }
    
    static func previewEmpty() -> AppSettings {
        let settings = AppSettings()
        // Override with preview-specific values
        settings.uptimeKumaURL = ""
        settings.uptimeKumaUsername = ""
        settings.uptimeKumaPassword = ""
        settings.refreshInterval = 0
        return settings
    }
}
#endif
