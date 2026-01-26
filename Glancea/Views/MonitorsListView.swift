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
        VStack {
            Text(timeAgo(lastUpdated))
                .font(.caption)
                .lineLimit(1)
                .alignmentGuide(.trailing, computeValue: { _ in 1 })

            Divider()

            ForEach(monitors, id: \.id) { monitor in
                MonitorRowView(monitor: monitor)
            }
        }
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
