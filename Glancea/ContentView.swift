//
//  ContentView.swift
//  Glancea
//
//  Created by Grant Megrabyan on 26/01/2026.
//

import SwiftUI

struct ContentView: View {
    @State var monitors = [] as [Monitor]

    let columns = [
        GridItem(.adaptive(minimum: 200, maximum: 250), spacing: 16)
    ]

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(monitors, id: \.id) { monitor in
                    MonitorCard(monitor: monitor)
                }
            }
            .padding()
        }
        .background(Color(nsColor: .windowBackgroundColor))
        .task {
            while !Task.isCancelled {
                await updateMonitors()
                try? await Task.sleep(for: .seconds(5))
            }
        }
    }
    
    func updateMonitors() async {
        self.monitors = await UptimeKumaMetricsProvider().getMonitors()
    }
}

struct MonitorCard: View {
    let monitor: Monitor

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                StatusIcon(status: monitor.status)
                    .frame(width: 12, height: 12)

                Text(monitor.name)
                    .font(.system(size: 14, weight: .semibold))
                    .lineLimit(1)

                Spacer()
            }

            HStack {
                Text(responseTimeText)
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)

                Spacer()
            }
        }
        .padding(12)
        .background(Color(nsColor: .controlBackgroundColor))
        .cornerRadius(8)
        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
    }

    private var responseTimeText: String {
        guard let responseTime = monitor.responseTimeMs else {
            return "N/A"
        }

        if responseTime < 0 {
            return "N/A"
        } else if responseTime < 1000 {
            return "\(Int(responseTime))ms"
        } else {
            return String(format: "%.1fs", responseTime / 1000)
        }
    }
}

struct StatusIcon: View {
    let status: MonitorStatus?

    var body: some View {
        Circle()
            .fill(statusColor)
    }

    private var statusColor: Color {
        switch status {
        case .up:
            return .green
        case .down:
            return .red
        case .pending:
            return .orange
        case .maintenance:
            return .blue
        case nil:
            return .gray
        }
    }
}

#Preview {
    ContentView(monitors: [
        Monitor(id: 1, name: "Test Server", url: "http://test.com", status: .up, responseTimeMs: 13),
        Monitor(id: 2, name: "API Gateway", url: "http://api.com", status: .down, responseTimeMs: 0),
        Monitor(id: 3, name: "Database", url: "http://db.com", status: .pending, responseTimeMs: 245),
        Monitor(id: 4, name: "Web Service", url: "http://web.com", status: .maintenance, responseTimeMs: nil)
    ])
}
