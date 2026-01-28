//
//  MonitorsList.swift
//  Glancea
//
//  Created by Grant Megrabyan on 26/01/2026.
//

import SwiftUI

struct MonitorsListView: View {
    @Binding var monitors: [Monitor]

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

            // Monitors list
            ForEach(monitors, id: \.id) { monitor in
                MonitorRowView(monitor: monitor)
            }
        }
        .padding(.horizontal, 6)
        .padding(.bottom, 8)
        .frame(width: 320)
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
    @Previewable @State var monitors = [
        Monitor(id: 1, name: "Pi-hole Primary", url: "https://192.168.1.1/", status: .up, responseTimeMs: 45),
        Monitor(id: 2, name: "Pi-hole Secondary", url: "https://192.168.1.1/", status: .up, responseTimeMs: 52),
        Monitor(id: 3, name: "Jellyfin", url: "https://192.168.1.1/", status: .up, responseTimeMs: 89),
        Monitor(id: 4, name: "Media Host", url: "https://192.168.1.1/", status: .up, responseTimeMs: 234),
    ]

    MonitorsListView(monitors: $monitors)
}

#Preview("Mixed Status") {
    @Previewable @State var monitors = [
        Monitor(id: 1, name: "Pi-hole Primary", url: "https://192.168.1.1/", status: .up, responseTimeMs: 45),
        Monitor(id: 2, name: "Pi-hole Secondary", url: "https://192.168.1.1/", status: .up, responseTimeMs: 52),
        Monitor(id: 3, name: "Jellyfin", url: "https://192.168.1.1/", status: .up, responseTimeMs: 89),
        Monitor(id: 4, name: "Media Host", url: "https://192.168.1.1/", status: .up, responseTimeMs: 1234),
        Monitor(id: 5, name: "Proxmox", url: "https://192.168.1.1/", status: nil, responseTimeMs: nil),
    ]

    MonitorsListView(monitors: $monitors)
}

#Preview("Critical Status") {
    @Previewable @State var monitors = [
        Monitor(id: 1, name: "Pi-hole Primary", url: "https://192.168.1.1/", status: .down, responseTimeMs: 0),
        Monitor(id: 2, name: "Pi-hole Secondary", url: "https://192.168.1.1/", status: .down, responseTimeMs: 0),
        Monitor(id: 3, name: "Jellyfin", url: "https://192.168.1.1/", status: .down, responseTimeMs: 0),
    ]

    MonitorsListView(monitors: $monitors)
}
