//
//  MonitorsList.swift
//  Glancea
//
//  Created by Grant Megrabyan on 26/01/2026.
//

import SwiftUI
import Combine
import AppKit

enum StatusFilter: String, CaseIterable {
    case all = "All"
    case up = "Up"
    case issues = "Issues"
    case down = "Down"
}

struct MonitorsListView: View {
    @Bindable var monitorManager: MonitorManager
    @Bindable var settings: AppSettings
    @State private var currentTime = Date()
    @State private var selectedFilter: StatusFilter = .all
    @State private var isIssuesSectionExpanded = true
    @State private var isHealthySectionExpanded = true
    @State private var selectedMonitorId: Int?

    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    // Track the settings window to prevent multiple instances
    @State private var settingsWindow: NSWindow?

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Enhanced Header
            VStack(alignment: .leading, spacing: 6) {
                // Status pills (now clickable filters)
                HStack(spacing: 6) {
                    FilterPill(
                        icon: "circle.fill",
                        label: "All",
                        count: monitors.count,
                        color: .primary,
                        isSelected: selectedFilter == .all,
                        action: { selectedFilter = .all }
                    )
                    FilterPill(
                        icon: "checkmark.circle.fill",
                        label: "Up",
                        count: upCount,
                        color: .green,
                        isSelected: selectedFilter == .up,
                        action: { selectedFilter = .up }
                    )
                    if warningCount > 0 || selectedFilter == .issues {
                        FilterPill(
                            icon: "exclamationmark.triangle.fill",
                            label: "Issues",
                            count: warningCount + downCount,
                            color: .orange,
                            isSelected: selectedFilter == .issues,
                            action: { selectedFilter = .issues }
                        )
                    }
                    if downCount > 0 || selectedFilter == .down {
                        FilterPill(
                            icon: "xmark.circle.fill",
                            label: "Down",
                            count: downCount,
                            color: .red,
                            isSelected: selectedFilter == .down,
                            action: { selectedFilter = .down }
                        )
                    }
                }
            }
            .padding(.horizontal, 14)
            .padding(.top, 12)
            .padding(.bottom, 8)

            Divider()
                .padding(.horizontal, 8)
                .padding(.bottom, 4)

            // Monitors list with smart grouping
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    if selectedFilter == .all {
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
                    } else {
                        // Filtered view (no grouping)
                        ForEach(filteredMonitors, id: \.id) { monitor in
                            MonitorRowView(monitor: monitor)
                        }
                    }
                }
            }
            .frame(maxHeight: 600)

            // Footer
            Divider()
                .padding(.horizontal, 8)
                .padding(.top, 4)

            HStack {
                // Settings button
                Button(action: {
                    openSettingsWindow()
                }) {
                    Image(systemName: "gearshape")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .help("Settings")

                // Last updated
                HStack(spacing: 4) {
                    Image(systemName: "clock")
                        .font(.system(size: 10))
                    Text(timeAgo(monitorManager.lastUpdated))
                        .font(.system(size: 11))
                }
                .foregroundStyle(.secondary)

                Spacer()

                // Refresh button
                Button(action: {
                    Task {
                        await monitorManager.refresh()
                    }
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 11))
                            .rotationEffect(.degrees(monitorManager.isRefreshing ? 360 : 0))
                            .animation(
                                monitorManager.isRefreshing ?
                                    .linear(duration: 1).repeatForever(autoreverses: false) :
                                    .default,
                                value: monitorManager.isRefreshing
                            )
                        Text("Refresh")
                            .font(.system(size: 11, weight: .medium))
                    }
                    .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .disabled(monitorManager.isRefreshing)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
        }
        .padding(.horizontal, 6)
        .frame(width: 320, height: 500)
        .onKeyPress(.upArrow) {
            navigateUp()
            return .handled
        }
        .onKeyPress(.downArrow) {
            navigateDown()
            return .handled
        }
        .onKeyPress(.return) {
            openSelectedMonitor()
            return .handled
        }
        .onReceive(timer) { time in
            currentTime = time
        }
    }

    private func openSettingsWindow() {
        // If window already exists, bring it to front
        if let existingWindow = settingsWindow {
            if existingWindow.isVisible {
                existingWindow.makeKeyAndOrderFront(nil)
                NSApp.activate(ignoringOtherApps: true)
                return
            }
        }

        // Create new settings window
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 400, height: 500),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = "Glancea Settings"
        window.contentView = NSHostingView(
            rootView: SettingsView(settings: settings)
                .onDisappear {
                    monitorManager.restartUpdating()
                }
        )
        window.center()
        window.makeKeyAndOrderFront(nil)
        // Keep reference to prevent deallocation
        window.isReleasedWhenClosed = false

        // Store reference
        settingsWindow = window
    }

    private func navigateUp() {
        let visibleMonitors = displayedMonitors
        guard !visibleMonitors.isEmpty else { return }

        if let currentId = selectedMonitorId,
           let currentIndex = visibleMonitors.firstIndex(where: { $0.id == currentId }),
           currentIndex > 0 {
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
           currentIndex < visibleMonitors.count - 1 {
            selectedMonitorId = visibleMonitors[currentIndex + 1].id
        } else {
            selectedMonitorId = visibleMonitors.first?.id
        }
    }

    private func openSelectedMonitor() {
        guard let selectedId = selectedMonitorId,
              let monitor = monitors.first(where: { $0.id == selectedId }),
              let url = URL(string: monitor.url) else {
            return
        }
        NSWorkspace.shared.open(url)
    }

    private var displayedMonitors: [Monitor] {
        if selectedFilter == .all {
            var result: [Monitor] = []
            if isIssuesSectionExpanded {
                result.append(contentsOf: issueMonitors)
            }
            if isHealthySectionExpanded {
                result.append(contentsOf: healthyMonitors)
            }
            return result
        } else {
            return filteredMonitors
        }
    }

    private var monitors: [Monitor] {
        monitorManager.monitors
    }

    private var upCount: Int {
        monitors.filter { $0.status == .up }.count
    }

    private var downCount: Int {
        monitors.filter { $0.status == .down }.count
    }

    private var warningCount: Int {
        monitors.filter { $0.status == .pending || $0.status == nil }.count
    }

    private var issueMonitors: [Monitor] {
        monitors.filter { $0.status != .up }.sorted { $0.id < $1.id }
    }

    private var healthyMonitors: [Monitor] {
        monitors.filter { $0.status == .up }.sorted { $0.id < $1.id }
    }

    private var filteredMonitors: [Monitor] {
        switch selectedFilter {
        case .all:
            return monitors.sorted { $0.id < $1.id }
        case .up:
            return monitors.filter { $0.status == .up }.sorted { $0.id < $1.id }
        case .issues:
            return monitors.filter { $0.status != .up }.sorted { $0.id < $1.id }
        case .down:
            return monitors.filter { $0.status == .down }.sorted { $0.id < $1.id }
        }
    }

    private func timeAgo(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: currentTime)
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

struct FilterPill: View {
    let icon: String
    let label: String
    let count: Int
    let color: Color
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 3) {
                Image(systemName: icon)
                    .font(.system(size: 9))
                Text("\(count)")
                    .font(.system(size: 11, weight: .medium))
            }
            .foregroundStyle(isSelected ? .white : color)
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(isSelected ? color : color.opacity(0.15))
            .cornerRadius(4)
        }
        .buttonStyle(.plain)
        .help(label)
    }
}

#Preview("All Systems Operational") {
    @Previewable @State var settings = AppSettings()
    @Previewable @State var manager = {
        let s = AppSettings()
        let m = MonitorManager(settings: s)
        m.monitors = [
            Monitor(id: 1, name: "Pi-hole Primary", url: "https://192.168.1.1/", status: .up, responseTimeMs: 45),
            Monitor(id: 2, name: "Pi-hole Secondary", url: "https://192.168.1.1/", status: .up, responseTimeMs: 52),
            Monitor(id: 3, name: "Jellyfin", url: "https://192.168.1.1/", status: .up, responseTimeMs: 89),
            Monitor(id: 4, name: "Media Host", url: "https://192.168.1.1/", status: .up, responseTimeMs: 234),
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
            Monitor(id: 1, name: "Pi-hole Primary", url: "https://192.168.1.1/", status: .up, responseTimeMs: 45),
            Monitor(id: 2, name: "Pi-hole Secondary", url: "https://192.168.1.1/", status: .up, responseTimeMs: 52),
            Monitor(id: 3, name: "Jellyfin", url: "https://192.168.1.1/", status: .up, responseTimeMs: 89),
            Monitor(id: 4, name: "Sonarr", url: "https://192.168.1.1/", status: .down, responseTimeMs: 0),
            Monitor(id: 5, name: "Radarr", url: "https://192.168.1.1/", status: .pending, responseTimeMs: 523),
            Monitor(id: 6, name: "Media Host", url: "https://192.168.1.1/", status: .up, responseTimeMs: 1234),
            Monitor(id: 7, name: "Proxmox", url: "https://192.168.1.1/", status: nil, responseTimeMs: nil),
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
            Monitor(id: 1, name: "Pi-hole Primary", url: "https://192.168.1.1/", status: .down, responseTimeMs: 0),
            Monitor(id: 2, name: "Pi-hole Secondary", url: "https://192.168.1.1/", status: .down, responseTimeMs: 0),
            Monitor(id: 3, name: "Jellyfin", url: "https://192.168.1.1/", status: .down, responseTimeMs: 0),
            Monitor(id: 4, name: "Sonarr", url: "https://192.168.1.1/", status: .up, responseTimeMs: 123),
            Monitor(id: 5, name: "Radarr", url: "https://192.168.1.1/", status: .up, responseTimeMs: 156),
        ]
        return m
    }()

    MonitorsListView(monitorManager: manager, settings: settings)
}
