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

#Preview("All Green") {
    @Previewable @State var settings = AppSettings.preview()
    @Previewable @State var manager = MonitorManager.preview(with: MonitorManager.sampleAllGreenMonitors)

    MonitorsListView(monitorManager: manager, settings: settings)
}

#Preview("Mixed Status") {
    @Previewable @State var settings = AppSettings.preview()
    @Previewable @State var manager = MonitorManager.preview(with: MonitorManager.sampleMixedStatusMonitors)

    MonitorsListView(monitorManager: manager, settings: settings)
}

#Preview("Critical Status") {
    @Previewable @State var settings = AppSettings.preview()
    @Previewable @State var manager = MonitorManager.preview(with: MonitorManager.sampleCriticalStatusMonitors)

    MonitorsListView(monitorManager: manager, settings: settings)
}
