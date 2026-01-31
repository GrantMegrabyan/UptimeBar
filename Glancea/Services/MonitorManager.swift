//
//  MonitorManager.swift
//  Glancea
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

    private var provider: UptimeKumaMetricsProvider
    @ObservationIgnored private var updateTask: Task<Void, Never>?
    private let settings: AppSettings

    init(settings: AppSettings) {
        self.settings = settings
        self.provider = UptimeKumaMetricsProvider(settings: settings)
        startUpdating()
    }

    deinit {
        updateTask?.cancel()
    }

    func restartUpdating() {
        updateTask?.cancel()
        provider = UptimeKumaMetricsProvider(settings: settings)
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
        isRefreshing = true
        monitors = await provider.getMonitors()
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
