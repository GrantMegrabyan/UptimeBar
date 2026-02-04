//
//  HeaderView.swift
//  UptimeBar
//
//  Created by Grant Megrabyan on 31/01/2026.
//

import SwiftUI

struct HeaderView: View {
    @Bindable var monitorManager: MonitorManager
    @Binding var statusFilter: StatusFilter
    let openSettingsWindow: () -> Void
    @State private var isUpHovered = false
    @State private var isDownHovered = false
    
    var body: some View {
        HStack(spacing: 6) {
            Text("\(monitors.count) monitors")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.secondary)
            
            if upCount > 0 {
                Text("•")
                    .foregroundStyle(.secondary)
                Button {
                    toggleFilter(.up)
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 9))
                            .foregroundStyle(.green)
                        Text("\(upCount)")
                            .font(.system(size: 11))
                    }
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(
                        Capsule()
                            .fill(
                                (statusFilter == .up || isUpHovered)
                                    ? Color.accentColor.opacity(0.15)
                                    : Color.clear
                            )
                    )
                    .overlay(
                        Capsule()
                            .stroke(
                                (statusFilter == .up || isUpHovered)
                                    ? Color.accentColor.opacity(0.6)
                                    : Color.secondary.opacity(0.35),
                                lineWidth: 0.5
                            )
                    )
                }
                .buttonStyle(.plain)
                .foregroundStyle(statusFilter == .up ? Color.accentColor : .secondary)
                .contentShape(Capsule())
                .onHover { isUpHovered = $0 }
                .help("Show only up monitors")
            }
            
            if downCount > 0 {
                Text("•")
                    .foregroundStyle(.secondary)
                Button {
                    toggleFilter(.down)
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 9))
                            .foregroundStyle(.red)
                        Text("\(downCount)")
                            .font(.system(size: 11))
                    }
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(
                        Capsule()
                            .fill(
                                (statusFilter == .down || isDownHovered)
                                    ? Color.accentColor.opacity(0.15)
                                    : Color.clear
                            )
                    )
                    .overlay(
                        Capsule()
                            .stroke(
                                (statusFilter == .down || isDownHovered)
                                    ? Color.accentColor.opacity(0.6)
                                    : Color.secondary.opacity(0.35),
                                lineWidth: 0.5
                            )
                    )
                }
                .buttonStyle(.plain)
                .foregroundStyle(statusFilter == .down ? Color.accentColor : .secondary)
                .contentShape(Capsule())
                .onHover { isDownHovered = $0 }
                .help("Show only down monitors")
            }
            
            Spacer()
            
            // Settings button
            Button("Settings", systemImage: "gearshape") {
                openSettingsWindow()
            }
            .labelStyle(.iconOnly)
            .font(.system(size: 11))
            .foregroundStyle(.secondary)
            .buttonStyle(.plain)
            .help("Settings")
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

    private func toggleFilter(_ filter: StatusFilter) {
        if statusFilter == filter {
            statusFilter = .all
        } else {
            statusFilter = filter
        }
    }
}

#Preview {
    @Previewable @State var manager = MonitorManager.preview(with: MonitorManager.sampleMixedStatusMonitors)
    @Previewable @State var filter: StatusFilter = .all
    
    HeaderView(monitorManager: manager, statusFilter: $filter, openSettingsWindow: {})
        .frame(width: 300)
        .padding()
}
