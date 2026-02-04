//
//  MonitorsList.swift
//  UptimeBar
//
//  Created by Grant Megrabyan on 26/01/2026.
//

import AppKit
import SwiftUI

struct MonitorsListView: View {
    @Bindable var monitorManager: MonitorManager
    @Bindable var settings: AppSettings
    @Binding var isMenuPresented: Bool
    @State private var isIssuesSectionExpanded = true
    @State private var isHealthySectionExpanded = true
    @State private var isSettingsPresented = false
    @State private var statusFilter: StatusFilter = .all
    @FocusState private var isFocused: Bool

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
        .focusable()
        .focused($isFocused)
        .focusEffectDisabled()
        .onExitCommand {
            // Close settings if open, otherwise close the menu
            if isSettingsPresented {
                withAnimation(.easeInOut(duration: 0.3)) {
                    isSettingsPresented = false
                }
                monitorManager.restartUpdating()
            } else {
                isMenuPresented = false
            }
        }
        .onAppear {
            isFocused = true
        }
        .frame(width: 320, height: 500)
    }
    
    private var mainContentView: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header with status summary
            HeaderView(
                monitorManager: monitorManager,
                statusFilter: $statusFilter,
                openSettingsWindow: openSettingsWindow
            )
                .padding(.horizontal, 14)
                .padding(.top, 12)
                .padding(.bottom, 8)
            
            Divider()
                .padding(.horizontal, 8)
                .padding(.bottom, 4)

            // Error banner
            if let errorMessage = monitorManager.errorMessage {
                HStack(spacing: 6) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 10))
                        .foregroundStyle(.orange)
                    Text(errorMessage)
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                    Spacer()
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 6)
                .background(.orange.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .padding(.horizontal, 8)
                .padding(.bottom, 4)
            }

            // Setup required message
            if monitorManager.needsSetup {
                VStack(spacing: 8) {
                    Spacer()
                    Image(systemName: "gear.badge")
                        .font(.system(size: 28))
                        .foregroundStyle(.secondary)
                    Text("Setup Required")
                        .font(.system(size: 13, weight: .semibold))
                    Text("Configure your Uptime Kuma URL to get started.")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                    Button("Open Settings") {
                        openSettingsWindow()
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }

            // Monitors list with smart grouping
            if !monitorManager.needsSetup {
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        if settings.statusPageGroupingEnabled {
                            ForEach(statusPageSections) { section in
                                let filteredSection = filteredStatusPageSection(section)
                                if filteredSection.monitors.isEmpty && filteredSection.groups.isEmpty {
                                    EmptyView()
                                } else {
                                    if filteredSection.groups.isEmpty {
                                        StatusPageCombinedHeader(
                                            title: filteredSection.title,
                                            count: filteredSection.monitors.count
                                        )
                                        ForEach(filteredSection.monitors, id: \.id) { monitor in
                                            MonitorRowView(monitor: monitor) {
                                                isMenuPresented = false
                                            }
                                        }
                                    } else {
                                        ForEach(filteredSection.groups) { group in
                                            StatusPageCombinedHeader(
                                                title: "\(filteredSection.title) // \(group.title)",
                                                count: group.monitors.count
                                            )
                                            ForEach(group.monitors, id: \.id) { monitor in
                                                MonitorRowView(monitor: monitor) {
                                                    isMenuPresented = false
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        } else {
                            ForEach(filteredMonitors, id: \.id) { monitor in
                                MonitorRowView(monitor: monitor) {
                                    isMenuPresented = false
                                }
                            }
                        }
                    }
                }
                .frame(maxHeight: 600)
            }

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
    
    private var monitors: [Monitor] {
        monitorManager.monitors
    }

    private var issueMonitors: [Monitor] {
        monitors.filter { $0.status != .up }.sorted { $0.id < $1.id }
    }
    
    private var healthyMonitors: [Monitor] {
        monitors.filter { $0.status == .up }.sorted { $0.id < $1.id }
    }

    private var sortedMonitors: [Monitor] {
        monitors.sorted { $0.id < $1.id }
    }

    private var filteredMonitors: [Monitor] {
        let filtered: [Monitor]
        switch statusFilter {
        case .all:
            filtered = monitors
        case .up:
            filtered = monitors.filter { $0.status == .up }
        case .down:
            filtered = monitors.filter { $0.status == .down }
        }
        return filtered.sorted { $0.id < $1.id }
    }

    private var statusPageSections: [StatusPageSection] {
        monitorManager.statusPageSections
    }

    private func filteredStatusPageSection(_ section: StatusPageSection) -> StatusPageSection {
        switch statusFilter {
        case .all:
            return section
        case .up, .down:
            let filteredGroups = section.groups.compactMap { group -> StatusPageMonitorGroup? in
                let filteredMonitors = group.monitors.filter { monitor in
                    switch statusFilter {
                    case .up:
                        return monitor.status == .up
                    case .down:
                        return monitor.status == .down
                    case .all:
                        return true
                    }
                }
                guard !filteredMonitors.isEmpty else { return nil }
                return StatusPageMonitorGroup(
                    id: group.id,
                    title: group.title,
                    weight: group.weight,
                    monitors: filteredMonitors
                )
            }

            let filteredMonitors = section.monitors.filter { monitor in
                switch statusFilter {
                case .up:
                    return monitor.status == .up
                case .down:
                    return monitor.status == .down
                case .all:
                    return true
                }
            }

            return StatusPageSection(
                id: section.id,
                title: section.title,
                groups: filteredGroups,
                monitors: filteredMonitors,
                isDefault: section.isDefault
            )
        }
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

struct StatusPageCombinedHeader: View {
    let title: String
    let count: Int

    var body: some View {
        HStack(spacing: 8) {
            Text(title)
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(.secondary)
            Text("(\(count))")
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(.tertiary)
            Divider()
                .frame(height: 1)
                .background(Color.secondary.opacity(0.25))
        }
        .padding(.horizontal, 12)
        .padding(.top, 6)
        .padding(.bottom, 4)
    }
}

enum StatusFilter: String, CaseIterable {
    case all
    case up
    case down
}

#Preview("All Green") {
    @Previewable @State var settings = AppSettings.preview()
    @Previewable @State var manager = MonitorManager.preview(with: MonitorManager.sampleAllGreenMonitors)
    @Previewable @State var isMenuPresented = true

    MonitorsListView(monitorManager: manager, settings: settings, isMenuPresented: $isMenuPresented)
}

#Preview("Mixed Status") {
    @Previewable @State var settings = AppSettings.preview()
    @Previewable @State var manager = MonitorManager.preview(with: MonitorManager.sampleMixedStatusMonitors)
    @Previewable @State var isMenuPresented = true

    MonitorsListView(monitorManager: manager, settings: settings, isMenuPresented: $isMenuPresented)
}

#Preview("Critical Status") {
    @Previewable @State var settings = AppSettings.preview()
    @Previewable @State var manager = MonitorManager.preview(with: MonitorManager.sampleCriticalStatusMonitors)
    @Previewable @State var isMenuPresented = true

    MonitorsListView(monitorManager: manager, settings: settings, isMenuPresented: $isMenuPresented)
}

#Preview("Auth Error") {
    @Previewable @State var settings = AppSettings.preview()
    @Previewable @State var manager = MonitorManager.previewError(.authenticationFailed)
    @Previewable @State var isMenuPresented = true

    MonitorsListView(monitorManager: manager, settings: settings, isMenuPresented: $isMenuPresented)
}

#Preview("Network Error") {
    @Previewable @State var settings = AppSettings.preview()
    @Previewable @State var manager = MonitorManager.previewError(
        .networkError(underlying: URLError(.notConnectedToInternet))
    )
    @Previewable @State var isMenuPresented = true

    MonitorsListView(monitorManager: manager, settings: settings, isMenuPresented: $isMenuPresented)
}

#Preview("Setup Required") {
    @Previewable @State var settings = AppSettings.previewEmpty()
    @Previewable @State var manager = MonitorManager.previewNeedsSetup()
    @Previewable @State var isMenuPresented = true

    MonitorsListView(monitorManager: manager, settings: settings, isMenuPresented: $isMenuPresented)
}

#Preview("Timeout Error") {
    @Previewable @State var settings = AppSettings.preview()
    @Previewable @State var manager = MonitorManager.previewError(.timeout)
    @Previewable @State var isMenuPresented = true

    MonitorsListView(monitorManager: manager, settings: settings, isMenuPresented: $isMenuPresented)
}
