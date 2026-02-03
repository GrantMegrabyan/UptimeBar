//
//  KeychainStore.swift
//  UptimeBar
//
//  Created by Grant Megrabyan on 03/02/2026.
//

import Foundation
import KeychainAccess

enum KeychainStore {
    private static let service = Bundle.main.bundleIdentifier ?? "UptimeBar"
    private static let keychain = Keychain(service: service)

    private static let uptimeKumaPasswordKey = "uptimeKumaPassword"

    static func getUptimeKumaPassword() -> String {
        keychain[uptimeKumaPasswordKey] ?? ""
    }

    static func setUptimeKumaPassword(_ value: String) {
        if value.isEmpty {
            keychain[uptimeKumaPasswordKey] = nil
        } else {
            keychain[uptimeKumaPasswordKey] = value
        }
    }
}
