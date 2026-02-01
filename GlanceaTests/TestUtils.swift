//
//  TestUtils.swift
//  GlanceaTests
//
//  Created by Grant Megrabyan on 01/02/2026.
//

import Foundation
@testable import Glancea

struct MockProvider: MetricsProvider {
    let monitors: [Monitor]
    func getMonitors() async -> [Monitor] { monitors }
}
