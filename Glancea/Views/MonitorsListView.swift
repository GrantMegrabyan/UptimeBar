//
//  MonitorsList.swift
//  Glancea
//
//  Created by Grant Megrabyan on 26/01/2026.
//

import SwiftUI

struct MonitorsListView: View {
    @State var monitors = [] as [Monitor]
    @State var lastUpdated: Date = .now

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            // Header
            Text("Monitors")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.secondary)
                .padding(.horizontal, 14)
                .padding(.top, 8)
                .padding(.bottom, 4)

            // Monitors list
            ForEach(monitors, id: \.id) { monitor in
                MonitorRowView(monitor: monitor)
            }
        }
        .padding(.horizontal, 6)
        .padding(.bottom, 8)
        .frame(width: 240)
        .task {
            while !Task.isCancelled {
                await updateMonitors()
                lastUpdated = .now
                try? await Task.sleep(for: .seconds(5))
            }
        }
    }

    func updateMonitors() async {
        self.monitors = await UptimeKumaMetricsProvider().getMonitors()
    }

    func timeAgo(_ date: Date) -> String {
        let f = RelativeDateTimeFormatter()
        f.unitsStyle = .abbreviated  // "1 min ago" (often), "2 hr ago", etc.
        return f.localizedString(for: date, relativeTo: .now)
    }
}
