//
//  MonitorsList.swift
//  Glancea
//
//  Created by Grant Megrabyan on 26/01/2026.
//

import AppKit
import SwiftUI

struct MonitorsListView: View {
    @Bindable var monitorManager: MonitorManager
    @Bindable var settings: AppSettings
    @State private var isIssuesSectionExpanded = true
    @State private var isHealthySectionExpanded = true
    @State private var selectedMonitorId: Int?
    @State private var isSettingsPresented = false

    var body: some View {
        ZStack {
            // Main content
            mainContentView
                .opacity(isSettingsPresented ? 0.3 : 1.0)
                .disabled(isSettingsPresented)

            // Settings view slides down from top
            if isSettingsPresented {
                SettingsView(
                    settings: settings,
                    onDismiss: {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            isSettingsPresented = false
                        }
                        monitorManager.restartUpdating()
                    }
                )
                .transition(.move(edge: .top).combined(with: .opacity))
                .zIndex(1)
            }
        }
        .frame(width: 320, height: 500)
        .onKeyPress(.upArrow) {
            guard !isSettingsPresented else { return .ignored }
            navigateUp()
            return .handled
        }
        .onKeyPress(.downArrow) {
            guard !isSettingsPresented else { return .ignored }
            navigateDown()
            return .handled
        }
        .onKeyPress(.return) {
            guard !isSettingsPresented else { return .ignored }
            openSelectedMonitor()
            return .handled
        }
        .onKeyPress(.escape) {
            if isSettingsPresented {
                withAnimation(.easeInOut(duration: 0.3)) {
                    isSettingsPresented = false
                }
                monitorManager.restartUpdating()
                return .handled
            }
            return .ignored
        }
    }

    private var mainContentView: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header with status summary
            HeaderView(monitorManager: monitorManager, openSettingsWindow: openSettingsWindow)
                .padding(.horizontal, 14)
                .padding(.top, 12)
                .padding(.bottom, 8)

            Divider()
                .padding(.horizontal, 8)
                .padding(.bottom, 4)

            // Monitors list with smart grouping
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    // Issues section
                    if !issueMonitors.isEmpty {
                        CollapsibleGroupHeader(
                            title: "ISSUES",
                            count: issueMonitors.count,
                            isExpanded: $isIssuesSectionExpanded
                        )
                        if isIssuesSectionExpanded {
                            ForEach(issueMonitors, id: \.id) { monitor in
                                MonitorRowView(monitor: monitor)
                            }
                        }
                    }

                    // All good section
                    if !healthyMonitors.isEmpty {
                        CollapsibleGroupHeader(
                            title: "ALL GOOD",
                            count: healthyMonitors.count,
                            isExpanded: $isHealthySectionExpanded
                        )
                        .padding(.top, issueMonitors.isEmpty ? 0 : 8)
                        if isHealthySectionExpanded {
                            ForEach(healthyMonitors, id: \.id) { monitor in
                                MonitorRowView(monitor: monitor)
                            }
                        }
                    }
                }
            }
            .frame(maxHeight: 600)

            // Footer
            Divider()
                .padding(.horizontal, 8)
                .padding(.top, 4)

            FooterView(monitorManager: monitorManager)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
        }
        .padding(.horizontal, 6)
    }

    private func openSettingsWindow() {
        withAnimation(.easeInOut(duration: 0.3)) {
            isSettingsPresented = true
        }
    }

    private func navigateUp() {
        let visibleMonitors = displayedMonitors
        guard !visibleMonitors.isEmpty else { return }

        if let currentId = selectedMonitorId,
            let currentIndex = visibleMonitors.firstIndex(where: { $0.id == currentId }),
            currentIndex > 0
        {
            selectedMonitorId = visibleMonitors[currentIndex - 1].id
        } else {
            selectedMonitorId = visibleMonitors.first?.id
        }
    }

    private func navigateDown() {
        let visibleMonitors = displayedMonitors
        guard !visibleMonitors.isEmpty else { return }

        if let currentId = selectedMonitorId,
            let currentIndex = visibleMonitors.firstIndex(where: { $0.id == currentId }),
            currentIndex < visibleMonitors.count - 1
        {
            selectedMonitorId = visibleMonitors[currentIndex + 1].id
        } else {
            selectedMonitorId = visibleMonitors.first?.id
        }
    }

    private func openSelectedMonitor() {
        guard let selectedId = selectedMonitorId,
            let monitor = monitors.first(where: { $0.id == selectedId }),
            let url = URL(string: monitor.url)
        else {
            return
        }
        NSWorkspace.shared.open(url)
    }

    private var displayedMonitors: [Monitor] {
        var result: [Monitor] = []
        if isIssuesSectionExpanded {
            result.append(contentsOf: issueMonitors)
        }
        if isHealthySectionExpanded {
            result.append(contentsOf: healthyMonitors)
        }
        return result
    }

    private var monitors: [Monitor] {
        monitorManager.monitors
    }

    private var issueMonitors: [Monitor] {
        monitors.filter { $0.status != .up }.sorted { $0.id < $1.id }
    }

    private var healthyMonitors: [Monitor] {
        monitors.filter { $0.status == .up }.sorted { $0.id < $1.id }
    }
}

struct CollapsibleGroupHeader: View {
    let title: String
    let count: Int
    @Binding var isExpanded: Bool

    var body: some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.2)) {
                isExpanded.toggle()
            }
        }) {
            HStack(spacing: 4) {
                Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                    .font(.system(size: 8, weight: .semibold))
                    .foregroundStyle(.secondary)

                Text("\(title) (\(count))")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(.secondary)

                Spacer()
            }
            .padding(.horizontal, 14)
            .padding(.top, 4)
            .padding(.bottom, 2)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

#Preview("All Systems Operational") {
    @Previewable @State var settings = AppSettings()
    @Previewable @State var manager = {
        let s = AppSettings()
        let m = MonitorManager(settings: s)
        m.monitors = [
            Monitor(
                id: 1, name: "Pi-hole Primary", url: "https://192.168.1.1/", status: .up,
                responseTimeMs: 45),
            Monitor(
                id: 2, name: "Pi-hole Secondary", url: "https://192.168.1.1/", status: .up,
                responseTimeMs: 52),
            Monitor(
                id: 3, name: "Jellyfin", url: "https://192.168.1.1/", status: .up,
                responseTimeMs: 89),
            Monitor(
                id: 4, name: "Media Host", url: "https://192.168.1.1/", status: .up,
                responseTimeMs: 234),
        ]
        return m
    }()

    MonitorsListView(monitorManager: manager, settings: settings)
}

#Preview("Mixed Status") {
    @Previewable @State var settings = AppSettings()
    @Previewable @State var manager = {
        let s = AppSettings()
        let m = MonitorManager(settings: s)
        m.monitors = [
            Monitor(
                id: 1, name: "Pi-hole Primary", url: "https://192.168.1.1/", status: .up,
                responseTimeMs: 45),
            Monitor(
                id: 2, name: "Pi-hole Secondary", url: "https://192.168.1.1/", status: .up,
                responseTimeMs: 52),
            Monitor(
                id: 3, name: "Jellyfin", url: "https://192.168.1.1/", status: .up,
                responseTimeMs: 89),
            Monitor(
                id: 4, name: "Sonarr", url: "https://192.168.1.1/", status: .down, responseTimeMs: 0
            ),
            Monitor(
                id: 5, name: "Radarr", url: "https://192.168.1.1/", status: .pending,
                responseTimeMs: 523),
            Monitor(
                id: 6, name: "Media Host", url: "https://192.168.1.1/", status: .up,
                responseTimeMs: 1234),
            Monitor(
                id: 7, name: "Proxmox", url: "https://192.168.1.1/", status: nil,
                responseTimeMs: nil),
        ]
        return m
    }()

    MonitorsListView(monitorManager: manager, settings: settings)
}

#Preview("Critical Status") {
    @Previewable @State var settings = AppSettings()
    @Previewable @State var manager = {
        let s = AppSettings()
        let m = MonitorManager(settings: s)
        m.monitors = [
            Monitor(
                id: 1, name: "Pi-hole Primary", url: "https://192.168.1.1/", status: .down,
                responseTimeMs: 0),
            Monitor(
                id: 2, name: "Pi-hole Secondary", url: "https://192.168.1.1/", status: .down,
                responseTimeMs: 0),
            Monitor(
                id: 3, name: "Jellyfin", url: "https://192.168.1.1/", status: .down,
                responseTimeMs: 0),
            Monitor(
                id: 4, name: "Sonarr", url: "https://192.168.1.1/", status: .up, responseTimeMs: 123
            ),
            Monitor(
                id: 5, name: "Radarr", url: "https://192.168.1.1/", status: .up, responseTimeMs: 156
            ),
        ]
        return m
    }()

    MonitorsListView(monitorManager: manager, settings: settings)
}
