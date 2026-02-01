//
//  TestUtils.swift
//  UptimeBarTests
//
//  Created by Grant Megrabyan on 01/02/2026.
//

import Foundation
@testable import UptimeBar

struct MockProvider: MetricsProvider {
    let monitors: [Monitor]
    func getMonitors() async throws -> [Monitor] { monitors }
}
