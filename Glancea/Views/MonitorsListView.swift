//
//  MonitorsList.swift
//  Glancea
//
//  Created by Grant Megrabyan on 26/01/2026.
//

import SwiftUI
import Combine

struct MonitorsListView: View {
    @Bindable var monitorManager: MonitorManager
    @State private var currentTime = Date()

    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Enhanced Header
            VStack(alignment: .leading, spacing: 6) {
                // Status pills
                HStack(spacing: 6) {
                    StatusPill(icon: "checkmark.circle.fill", count: upCount, color: .green)
                    if warningCount > 0 {
                        StatusPill(icon: "exclamationmark.triangle.fill", count: warningCount, color: .orange)
                    }
                    if downCount > 0 {
                        StatusPill(icon: "xmark.circle.fill", count: downCount, color: .red)
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
                    // Issues section
                    if !issueMonitors.isEmpty {
                        GroupHeader(title: "ISSUES", count: issueMonitors.count)
                        ForEach(issueMonitors, id: \.id) { monitor in
                            MonitorRowView(monitor: monitor)
                        }
                    }

                    // All good section
                    if !healthyMonitors.isEmpty {
                        GroupHeader(title: "ALL GOOD", count: healthyMonitors.count)
                            .padding(.top, issueMonitors.isEmpty ? 0 : 8)
                        ForEach(healthyMonitors, id: \.id) { monitor in
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
        .frame(width: 320)
        .onReceive(timer) { time in
            currentTime = time
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

    private func timeAgo(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: currentTime)
    }
}

struct GroupHeader: View {
    let title: String
    let count: Int

    var body: some View {
        Text("\(title) (\(count))")
            .font(.system(size: 10, weight: .semibold))
            .foregroundStyle(.secondary)
            .padding(.horizontal, 14)
            .padding(.top, 4)
            .padding(.bottom, 2)
    }
}

struct StatusPill: View {
    let icon: String
    let count: Int
    let color: Color

    var body: some View {
        HStack(spacing: 3) {
            Image(systemName: icon)
                .font(.system(size: 9))
            Text("\(count)")
                .font(.system(size: 11, weight: .medium))
        }
        .foregroundStyle(color)
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .background(color.opacity(0.15))
        .cornerRadius(4)
    }
}

#Preview("All Systems Operational") {
    @Previewable @State var manager = {
        let m = MonitorManager()
        m.monitors = [
            Monitor(id: 1, name: "Pi-hole Primary", url: "https://192.168.1.1/", status: .up, responseTimeMs: 45),
            Monitor(id: 2, name: "Pi-hole Secondary", url: "https://192.168.1.1/", status: .up, responseTimeMs: 52),
            Monitor(id: 3, name: "Jellyfin", url: "https://192.168.1.1/", status: .up, responseTimeMs: 89),
            Monitor(id: 4, name: "Media Host", url: "https://192.168.1.1/", status: .up, responseTimeMs: 234),
        ]
        return m
    }()

    MonitorsListView(monitorManager: manager)
}

#Preview("Mixed Status") {
    @Previewable @State var manager = {
        let m = MonitorManager()
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

    MonitorsListView(monitorManager: manager)
}

#Preview("Critical Status") {
    @Previewable @State var manager = {
        let m = MonitorManager()
        m.monitors = [
            Monitor(id: 1, name: "Pi-hole Primary", url: "https://192.168.1.1/", status: .down, responseTimeMs: 0),
            Monitor(id: 2, name: "Pi-hole Secondary", url: "https://192.168.1.1/", status: .down, responseTimeMs: 0),
            Monitor(id: 3, name: "Jellyfin", url: "https://192.168.1.1/", status: .down, responseTimeMs: 0),
            Monitor(id: 4, name: "Sonarr", url: "https://192.168.1.1/", status: .up, responseTimeMs: 123),
            Monitor(id: 5, name: "Radarr", url: "https://192.168.1.1/", status: .up, responseTimeMs: 156),
        ]
        return m
    }()

    MonitorsListView(monitorManager: manager)
}
