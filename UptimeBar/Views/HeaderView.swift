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

    var body: some View {
        HStack(spacing: 6) {
            Text("\(monitors.count) monitors")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.secondary)

            if upCount > 0 {
                Text("•")
                    .foregroundStyle(.secondary)
                FilterChip(
                    icon: "checkmark.circle.fill",
                    iconColor: .green,
                    count: upCount,
                    isSelected: statusFilter == .up,
                    helpText: "Show only up monitors"
                ) {
                    toggleFilter(.up)
                }
            }

            if downCount > 0 {
                Text("•")
                    .foregroundStyle(.secondary)
                FilterChip(
                    icon: "xmark.circle.fill",
                    iconColor: .red,
                    count: downCount,
                    isSelected: statusFilter == .down,
                    helpText: "Show only down monitors"
                ) {
                    toggleFilter(.down)
                }
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

/// A reusable filter chip button with icon, count, and hover/selection states
struct FilterChip: View {
    let icon: String
    let iconColor: Color
    let count: Int
    let isSelected: Bool
    let helpText: String
    let action: () -> Void

    @State private var isHovered = false

    private var isHighlighted: Bool {
        isSelected || isHovered
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 9))
                    .foregroundStyle(iconColor)
                Text("\(count)")
                    .font(.system(size: 11))
            }
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(
                Capsule()
                    .fill(isHighlighted ? Color.accentColor.opacity(0.15) : Color.clear)
            )
            .overlay(
                Capsule()
                    .stroke(
                        isHighlighted ? Color.accentColor.opacity(0.6) : Color.secondary.opacity(0.35),
                        lineWidth: 0.5
                    )
            )
        }
        .buttonStyle(.plain)
        .foregroundStyle(isSelected ? Color.accentColor : .secondary)
        .contentShape(Capsule())
        .onHover { isHovered = $0 }
        .help(helpText)
    }
}

#Preview {
    @Previewable @State var manager = MonitorManager.preview(with: MonitorManager.sampleMixedStatusMonitors)
    @Previewable @State var filter: StatusFilter = .all
    
    HeaderView(monitorManager: manager, statusFilter: $filter, openSettingsWindow: {})
        .frame(width: 300)
        .padding()
}
