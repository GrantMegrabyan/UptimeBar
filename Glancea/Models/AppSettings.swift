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
    var uptimeKumaURL: String {
        didSet {
            UserDefaults.standard.set(uptimeKumaURL, forKey: "uptimeKumaURL")
        }
    }

    var uptimeKumaUsername: String {
        didSet {
            UserDefaults.standard.set(uptimeKumaUsername, forKey: "uptimeKumaUsername")
        }
    }

    var uptimeKumaPassword: String {
        didSet {
            UserDefaults.standard.set(uptimeKumaPassword, forKey: "uptimeKumaPassword")
        }
    }

    var refreshInterval: Int {
        didSet {
            UserDefaults.standard.set(refreshInterval, forKey: "refreshInterval")
        }
    }

    init() {
        self.uptimeKumaURL = UserDefaults.standard.string(forKey: "uptimeKumaURL") ?? "http://192.168.1.181:3001/metrics"
        self.uptimeKumaUsername = UserDefaults.standard.string(forKey: "uptimeKumaUsername") ?? "grant"
        self.uptimeKumaPassword = UserDefaults.standard.string(forKey: "uptimeKumaPassword") ?? ""
        self.refreshInterval = UserDefaults.standard.integer(forKey: "refreshInterval") == 0 ? 120 : UserDefaults.standard.integer(forKey: "refreshInterval")
    }
}
