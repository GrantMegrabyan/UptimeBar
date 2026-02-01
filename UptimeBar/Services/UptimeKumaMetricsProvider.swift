//
//  UptimeKumaMetricProvider.swift
//  UptimeBar
//
//  Created by Grant Megrabyan on 26/01/2026.
//

import Foundation
import OSLog

class UptimeKumaMetricsProvider: MetricsProvider {
    let logger = Logger(subsystem: "UptimeBar", category: "UptimeKumaMetricsProvider")

    private let settings: AppSettings
    private let session: URLSession

    init(settings: AppSettings) {
        self.settings = settings
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 10
        self.session = URLSession(configuration: config)
    }

    func getMonitors() async throws -> [Monitor] {
        guard let url = URL(string: settings.uptimeKumaURL) else {
            logger.error("Invalid URL: \(self.settings.uptimeKumaURL)")
            throw MonitorFetchError.invalidURL
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

        return try await fetchWithRetry(request: request)
    }

    private func fetchWithRetry(request: URLRequest) async throws -> [Monitor] {
        do {
            return try await performFetch(request: request)
        } catch let error as MonitorFetchError where error.isRetryable {
            logger.info("Retrying after transient failure")
            try? await Task.sleep(for: .seconds(2))
            return try await performFetch(request: request)
        }
    }

    private func performFetch(request: URLRequest) async throws -> [Monitor] {
        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch let urlError as URLError where urlError.code == .timedOut {
            logger.error("Request timed out")
            throw MonitorFetchError.timeout
        } catch {
            logger.error("Network error: \(error.localizedDescription)")
            throw MonitorFetchError.networkError(underlying: error)
        }

        if let httpResponse = response as? HTTPURLResponse {
            switch httpResponse.statusCode {
            case 200..<300:
                break
            case 401, 403:
                logger.error("Authentication failed: \(httpResponse.statusCode)")
                throw MonitorFetchError.authenticationFailed
            default:
                logger.error("Server error: \(httpResponse.statusCode)")
                throw MonitorFetchError.serverError(statusCode: httpResponse.statusCode)
            }
        }

        guard let metricsText = String(data: data, encoding: .utf8) else {
            throw MonitorFetchError.invalidResponse
        }

        let monitors = UptimeKumaMetricsParser.parseMonitors(from: metricsText)
        logger.debug("Parsed \(monitors.count) monitors")
        return monitors
    }
}
