//
//  GlanceaApp.swift
//  Glancea
//
//  Created by Grant Megrabyan on 26/01/2026.
//

import SwiftUI

@main
struct GlanceaApp: App {
    @State private var settings = AppSettings()
    @State private var monitorManager: MonitorManager

    init() {
        let settings = AppSettings()
        _settings = State(initialValue: settings)
        _monitorManager = State(initialValue: MonitorManager(settings: settings))
    }

    var body: some Scene {
        MenuBarExtra {
            MonitorsListView(monitorManager: monitorManager, settings: settings)
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
    }

    private var badgeText: String? {
        let totalCount = monitorManager.monitors.count
        guard totalCount > 0 else { return nil }

        let issueCount = monitorManager.monitors.filter { $0.status != .up }.count
        guard issueCount > 0 else { return nil }

        return "\(issueCount)/\(totalCount)"
    }
}
