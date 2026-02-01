//
//  PreviewMetricsProvider.swift
//  Glancea
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

    func getMonitors() async -> [Monitor] {
        return monitors
    }
}
#endif
