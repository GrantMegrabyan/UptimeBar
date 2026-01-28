//
//  GlanceaApp.swift
//  Glancea
//
//  Created by Grant Megrabyan on 26/01/2026.
//

import SwiftUI

@main
struct GlanceaApp: App {
    @State private var monitorManager = MonitorManager()

    var body: some Scene {
        MenuBarExtra {
            MonitorsListView(monitors: $monitorManager.monitors)
        } label: {
            Label("Glancea", systemImage: monitorManager.aggregateStatus.icon)
                .foregroundStyle(monitorManager.aggregateStatus.color)
        }
        .menuBarExtraStyle(.window)
    }
}
