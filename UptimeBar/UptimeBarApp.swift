//
//  UptimeBarApp.swift
//  UptimeBar
//
//  Created by Grant Megrabyan on 26/01/2026.
//

import SwiftUI
import MenuBarExtraAccess

@main
struct UptimeBarApp: App {
    @State private var settings = AppSettings()
    @State private var monitorManager: MonitorManager
    @State private var isMenuPresented = false

    init() {
        let settings = AppSettings()
        _settings = State(initialValue: settings)
        _monitorManager = State(initialValue: MonitorManager(settings: settings) { settings in
            UptimeKumaMetricsProvider(settings: settings)
        })
    }

    var body: some Scene {
        MenuBarExtra {
            MonitorsListView(
                monitorManager: monitorManager,
                settings: settings,
                isMenuPresented: $isMenuPresented
            )
        } label: {
            HStack(spacing: 4) {
                Image(systemName: monitorManager.aggregateStatus.icon)
                    .foregroundStyle(monitorManager.aggregateStatus.color)

                if let badgeText = badgeText {
                    Text(badgeText)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(monitorManager.aggregateStatus.color)
                }
            }
        }
        .menuBarExtraStyle(.window)
        .menuBarExtraAccess(isPresented: $isMenuPresented)
    }

    private var badgeText: String? {
        guard settings.showUnhealthyCountInMenuBar else { return nil }

        let totalCount = monitorManager.monitors.count
        guard totalCount > 0 else { return nil }

        let issueCount = monitorManager.monitors.filter { $0.status != .up }.count
        guard issueCount > 0 else { return nil }

        return "\(issueCount)/\(totalCount)"
    }
}
