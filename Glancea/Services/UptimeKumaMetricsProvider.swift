//
//  UptimeKumaMetricProvider.swift
//  Glancea
//
//  Created by Grant Megrabyan on 26/01/2026.
//

import Foundation
import OSLog

class UptimeKumaMetricsProvider {
    let logger = Logger(subsystem: "Glancea", category: "UptimeKumaMetricsProvider")

    private let settings: AppSettings

    init(settings: AppSettings) {
        self.settings = settings
    }

    func getMonitors() async -> [Monitor] {
        guard let url = URL(string: settings.uptimeKumaURL) else {
            logger.error("Invalid URL: \(self.settings.uptimeKumaURL)")
            return []
        }

        var request = URLRequest(url: url)

        // Add HTTP Basic Authentication
        if !settings.uptimeKumaUsername.isEmpty && !settings.uptimeKumaPassword.isEmpty {
            let credentials = "\(settings.uptimeKumaUsername):\(settings.uptimeKumaPassword)"
            if let credentialsData = credentials.data(using: .utf8) {
                let base64Credentials = credentialsData.base64EncodedString()
                request.setValue("Basic \(base64Credentials)", forHTTPHeaderField: "Authorization")
            }
        }

        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            logger.info("Received \(data.count) bytes from metrics endpoint")
            let metricsText = String(data: data, encoding: .utf8) ?? ""
            logger.info("Metrics text: \(metricsText.prefix(500))")
            let monitors = UptimeKumaMetricsParser.parseMonitors(from: metricsText)
            logger.info("Parsed \(monitors.count) monitors")
            return monitors
        } catch {
            logger.error("Failed to fetch uptime metrics: \(error.localizedDescription)")
            return []
        }
    }
}
