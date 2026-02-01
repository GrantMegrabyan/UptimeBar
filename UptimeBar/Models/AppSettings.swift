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
        self.refreshInterval = UserDefaults.standard.integer(forKey: "refreshInterval") == 0 ? 120 : UserDefaults.standard.integer(forKey: "refreshInterval")

        // Default to true if not set
        if UserDefaults.standard.object(forKey: "showUnhealthyCountInMenuBar") == nil {
            self.showUnhealthyCountInMenuBar = true
        } else {
            self.showUnhealthyCountInMenuBar = UserDefaults.standard.bool(forKey: "showUnhealthyCountInMenuBar")
        }
    }

    var isConfigured: Bool {
        !uptimeKumaURL.isEmpty
    }

    var urlValidationError: String? {
        let trimmed = uptimeKumaURL.trimmingCharacters(in: .whitespacesAndNewlines)
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

    var isURLValid: Bool {
        let trimmed = uptimeKumaURL.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty || urlValidationError == nil
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
