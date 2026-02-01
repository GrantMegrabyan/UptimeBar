//
//  AggregateStatusTests.swift
//  UptimeBar
//
//  Created by Grant Megrabyan on 01/02/2026.
//


import Testing
@testable import UptimeBar

@MainActor
struct AggregateStatusTests {

    @Test func emptyMonitorsIsHealthy() {
        let manager = MonitorManager(settings: AppSettings()) { _ in
            MockProvider(monitors: [])
        }
        #expect(manager.aggregateStatus == .healthy)
    }

    @Test func allUpIsHealthy() {
        let manager = makeManager(upCount: 10, downCount: 0)
        #expect(manager.aggregateStatus == .healthy)
    }

    @Test func underThirtyPercentIsWarning() {
        // 2 down out of 10 = 20% → warning
        let manager = makeManager(upCount: 8, downCount: 2)
        #expect(manager.aggregateStatus == .warning)
    }

    @Test func exactlyThirtyPercentIsCritical() {
        // 3 down out of 10 = 30% → critical
        let manager = makeManager(upCount: 7, downCount: 3)
        #expect(manager.aggregateStatus == .critical)
    }

    @Test func overThirtyPercentIsCritical() {
        // 5 down out of 10 = 50% → critical
        let manager = makeManager(upCount: 5, downCount: 5)
        #expect(manager.aggregateStatus == .critical)
    }

    @Test func allDownIsCritical() {
        let manager = makeManager(upCount: 0, downCount: 5)
        #expect(manager.aggregateStatus == .critical)
    }

    @Test func singleDownMonitorIsWarning() {
        // 1 down out of 4 = 25% → warning
        let manager = makeManager(upCount: 3, downCount: 1)
        #expect(manager.aggregateStatus == .warning)
    }

    @Test func pendingCountsAsNotOk() {
        let monitors = [
            Monitor(id: 1, name: "A", url: "http://a", status: .up, responseTimeMs: 100),
            Monitor(id: 2, name: "B", url: "http://b", status: .pending, responseTimeMs: nil),
        ]
        let manager = MonitorManager(settings: AppSettings()) { _ in
            MockProvider(monitors: monitors)
        }
        manager.monitors = monitors
        // 1 of 2 not-ok = 50% → critical
        #expect(manager.aggregateStatus == .critical)
    }

    @Test func maintenanceCountsAsNotOk() {
        let monitors = [
            Monitor(id: 1, name: "A", url: "http://a", status: .up, responseTimeMs: 100),
            Monitor(id: 2, name: "B", url: "http://b", status: .maintenance, responseTimeMs: nil),
            Monitor(id: 3, name: "C", url: "http://c", status: .up, responseTimeMs: 100),
            Monitor(id: 4, name: "D", url: "http://d", status: .up, responseTimeMs: 100),
            Monitor(id: 5, name: "E", url: "http://e", status: .up, responseTimeMs: 100),
        ]
        let manager = MonitorManager(settings: AppSettings()) { _ in
            MockProvider(monitors: monitors)
        }
        manager.monitors = monitors
        // 1 of 5 = 20% → warning
        #expect(manager.aggregateStatus == .warning)
    }

    // MARK: Helpers

    private func makeManager(upCount: Int, downCount: Int) -> MonitorManager {
        var monitors: [Monitor] = []
        for i in 0..<upCount {
            monitors.append(Monitor(id: i, name: "Up\(i)", url: "http://up\(i)", status: .up, responseTimeMs: 100))
        }
        for i in 0..<downCount {
            monitors.append(Monitor(id: upCount + i, name: "Down\(i)", url: "http://down\(i)", status: .down, responseTimeMs: nil))
        }
        let manager = MonitorManager(settings: AppSettings()) { _ in
            MockProvider(monitors: monitors)
        }
        manager.monitors = monitors
        return manager
    }
}
