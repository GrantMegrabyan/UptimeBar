//
//  AppSettings.swift
//  Glancea
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

    init() {
        self.uptimeKumaURL = UserDefaults.standard.string(forKey: "uptimeKumaURL") ?? ""
        self.uptimeKumaUsername = UserDefaults.standard.string(forKey: "uptimeKumaUsername") ?? ""
        self.uptimeKumaPassword = UserDefaults.standard.string(forKey: "uptimeKumaPassword") ?? ""
        self.refreshInterval = UserDefaults.standard.integer(forKey: "refreshInterval") == 0 ? 120 : UserDefaults.standard.integer(forKey: "refreshInterval")
    }

    var isConfigured: Bool {
        !uptimeKumaURL.isEmpty
    }

    func save() {
        UserDefaults.standard.set(uptimeKumaURL, forKey: "uptimeKumaURL")
        UserDefaults.standard.set(uptimeKumaUsername, forKey: "uptimeKumaUsername")
        UserDefaults.standard.set(uptimeKumaPassword, forKey: "uptimeKumaPassword")
        UserDefaults.standard.set(refreshInterval, forKey: "refreshInterval")
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
        refreshInterval: Int = 5
    ) -> AppSettings {
        let settings = AppSettings()
        // Override with preview-specific values
        settings.uptimeKumaURL = url
        settings.uptimeKumaUsername = username
        settings.uptimeKumaPassword = password
        settings.refreshInterval = refreshInterval
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
