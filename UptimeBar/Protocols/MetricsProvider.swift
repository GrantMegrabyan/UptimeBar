//
//  MetricsProvider.swift
//  UptimeBar
//
//  Created by Grant Megrabyan on 01/02/2026.
//

import Foundation

/// Protocol defining the contract for fetching monitor metrics
protocol MetricsProvider {
    func getMonitors() async throws -> [Monitor]
}
