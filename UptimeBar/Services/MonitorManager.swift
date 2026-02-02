//
//  MonitorManager.swift
//  UptimeBar
//
//  Created by Grant Megrabyan on 28/01/2026.
//

import Foundation
import SwiftUI

@MainActor
@Observable
class MonitorManager {
    var monitors: [Monitor] = []
    var lastUpdated: Date = .now
    var isRefreshing: Bool = false
    var errorMessage: String?
    var needsSetup: Bool = false

    private var provider: any MetricsProvider
    @ObservationIgnored private var updateTask: Task<Void, Never>?
    
    private let settings: AppSettings
    private let providerFactory: (AppSettings) -> any MetricsProvider
    
    init(settings: AppSettings, providerFactory: @escaping (AppSettings) -> any MetricsProvider) {
        self.settings = settings
        self.providerFactory = providerFactory
        self.provider = providerFactory(settings)
        startUpdating()
    }
    
    deinit {
        updateTask?.cancel()
    }
    
    func restartUpdating() {
        updateTask?.cancel()
        provider = providerFactory(settings)
        startUpdating()
    }
    
    private func startUpdating() {
        updateTask = Task {
            while !Task.isCancelled {
                await updateMonitors()
                try? await Task.sleep(for: .seconds(settings.refreshInterval))
            }
        }
    }
    
    func refresh() async {
        await updateMonitors()
    }
    
    private func updateMonitors() async {
        guard settings.isConfigured else {
            needsSetup = true
            return
        }
        needsSetup = false
        isRefreshing = true
        do {
            monitors = try await provider.getMonitors()
            errorMessage = nil
        } catch let error as MonitorFetchError {
            errorMessage = error.userMessage
        } catch {
            errorMessage = "Unexpected error: \(error.localizedDescription)"
        }
        lastUpdated = .now
        isRefreshing = false
    }
    
    var aggregateStatus: AggregateStatus {
        guard !monitors.isEmpty else { return .healthy }
        
        let notOkCount = monitors.filter { monitor in
            monitor.status != .up
        }.count
        
        let totalCount = monitors.count
        let notOkPercentage = Double(notOkCount) / Double(totalCount)
        
        if notOkCount == 0 {
            return .healthy
        } else if notOkPercentage < 0.3 {
            return .warning
        } else {
            return .critical
        }
    }
    
    enum AggregateStatus {
        case healthy
        case warning
        case critical
        
        var icon: String {
            switch self {
            case .healthy:
                return "checkmark.circle.fill"
            case .warning:
                return "exclamationmark.triangle.fill"
            case .critical:
                return "exclamationmark.circle.fill"
            }
        }
        
        var color: Color {
            switch self {
            case .healthy:
                return .green
            case .warning:
                return .orange
            case .critical:
                return .red
            }
        }
    }
}

@MainActor
extension MonitorManager {
    static func preview(with monitors: [Monitor]) -> MonitorManager {
        let settings = AppSettings.preview()
        let manager = MonitorManager(settings: settings) { _ in
            PreviewMetricsProvider(monitors: monitors)
        }
        return manager
    }

    static func previewNeedsSetup() -> MonitorManager {
        let settings = AppSettings.previewEmpty()
        let manager = MonitorManager(settings: settings) { _ in
            PreviewMetricsProvider(monitors: [])
        }
        return manager
    }

    static func previewError(_ error: MonitorFetchError) -> MonitorManager {
        let settings = AppSettings.preview()
        let manager = MonitorManager(settings: settings) { _ in
            FailingMetricsProvider(error: error)
        }
        return manager
    }
    
    static var healthyMonitors: [Monitor] {
        [
            Monitor(
                id: 1, name: "Jellyfin", url: "https://192.168.1.1/", status: .up,
                responseTimeMs: 842),
            Monitor(
                id: 2, name: "Plex", url: "https://192.168.1.1/", status: .up,
                responseTimeMs: 126),
            Monitor(
                id: 3, name: "Immich", url: "https://192.168.1.1/", status: .up,
                responseTimeMs: 1049),
            Monitor(
                id: 4, name: "Nextcloud", url: "https://192.168.1.1/", status: .up,
                responseTimeMs: 517),
            Monitor(
                id: 5, name: "Pi-hole", url: "https://192.168.1.1/", status: .up,
                responseTimeMs: 73),
            Monitor(
                id: 6, name: "Unbound", url: "https://192.168.1.1/", status: .up,
                responseTimeMs: 311),
            Monitor(
                id: 7, name: "Vaultwarden", url: "https://192.168.1.1/", status: .up,
                responseTimeMs: 690),
            Monitor(
                id: 8, name: "Nginx Proxy Manager", url: "https://192.168.1.1/", status: .up,
                responseTimeMs: 238),
            Monitor(
                id: 9, name: "Headscale", url: "https://192.168.1.1/", status: .up,
                responseTimeMs: 1327),
            Monitor(
                id: 10, name: "Home Assistant", url: "https://192.168.1.1/", status: .up,
                responseTimeMs: 401),
        ]
    }
    
    static var unhealthyMonitors: [Monitor] {
        [
            Monitor(
                id: 11, name: "Authentik", url: "https://192.168.1.1/", status: .down,
                responseTimeMs: nil),
            Monitor(
                id: 12, name: "Gitea", url: "https://192.168.1.1/", status: .down,
                responseTimeMs: nil),
            Monitor(
                id: 13, name: "Grafana", url: "https://192.168.1.1/", status: .down,
                responseTimeMs: nil),
            Monitor(
                id: 14, name: "Portainer", url: "https://192.168.1.1/", status: .down,
                responseTimeMs: nil),
            Monitor(
                id: 15, name: "MinIO", url: "https://192.168.1.1/", status: .down,
                responseTimeMs: nil),
            Monitor(
                id: 16, name: "Paperless-ngx", url: "https://192.168.1.1/", status: .down,
                responseTimeMs: nil),
            Monitor(
                id: 17, name: "Tandoor Recipes", url: "https://192.168.1.1/", status: .down,
                responseTimeMs: nil),
            Monitor(
                id: 18, name: "Syncthing", url: "https://192.168.1.1/", status: .down,
                responseTimeMs: nil),
            Monitor(
                id: 19, name: "Bookstack", url: "https://192.168.1.1/", status: .down,
                responseTimeMs: nil),
            Monitor(
                id: 20, name: "Actual Budget", url: "https://192.168.1.1/", status: .down,
                responseTimeMs: nil),
        ]
    }
    
    static var sampleAllGreenMonitors: [Monitor] {
        Self.healthyMonitors
    }
    
    static var sampleMixedStatusMonitors: [Monitor] {
        Array(Self.healthyMonitors.prefix(5) + Self.unhealthyMonitors.prefix(5))
    }
    
    static var sampleCriticalStatusMonitors: [Monitor] {
        self.unhealthyMonitors
    }
}
