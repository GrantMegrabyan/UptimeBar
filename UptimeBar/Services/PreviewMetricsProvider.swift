//
//  PreviewMetricsProvider.swift
//  UptimeBar
//
//  Created by Grant Megrabyan on 01/02/2026.
//

import Foundation

#if DEBUG
/// Preview-only metrics provider that returns static monitor data
class PreviewMetricsProvider: MetricsProvider {
    private let monitors: [Monitor]

    init(monitors: [Monitor]) {
        self.monitors = monitors
    }

    func getMonitors() async throws -> [Monitor] {
        return monitors
    }
}

/// Preview provider that always throws a given error
class FailingMetricsProvider: MetricsProvider {
    private let error: MonitorFetchError

    init(error: MonitorFetchError) {
        self.error = error
    }

    func getMonitors() async throws -> [Monitor] {
        throw error
    }
}
#endif
