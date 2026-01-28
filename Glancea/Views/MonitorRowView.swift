//
//  MonitorRowView.swift
//  Glancea
//
//  Created by Grant Megrabyan on 26/01/2026.
//

import SwiftUI

struct MonitorRowView: View {
    let monitor: Monitor
    @State private var isHovered = false

    var body: some View {
        Button(action: {
            print("Clicked: \(monitor.name)")
        }) {
            HStack(spacing: 8) {
                // Status indicator
                Circle()
                    .fill(statusColor)
                    .frame(width: 8, height: 8)

                // Monitor name
                Text(monitor.name)
                    .foregroundStyle(isHovered ? .white : .primary)

                Spacer()

                // Response time
                Text(responseTimeText)
                    .foregroundStyle(isHovered ? .white.opacity(0.8) : .secondary)
            }
            .font(.system(size: 13))
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 4)
                    .fill(isHovered ? Color.accentColor : .clear)
            )
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            isHovered = hovering
        }
    }

    private var statusColor: Color {
        switch monitor.status {
        case .up:
            return .green
        case .down:
            return .red
        case .pending:
            return .orange
        case .maintenance:
            return .blue
        // Looks like the "metrics" api returns 'status=nil'
        // when it is unclear if the service is 'up' or 'down'.
        // We can treat this as 'pending'
        case nil:
            return .orange
        }
    }

    private var responseTimeText: String {
        guard let responseTime = monitor.responseTimeMs else {
            return "—"
        }

        if responseTime < 0 {
            return "—"
        } else if responseTime < 1000 {
            return "\(Int(responseTime)) ms"
        } else {
            return String(format: "%.1f s", responseTime / 1000)
        }
    }
}

#Preview {
    VStack(alignment: .leading, spacing: 2) {
        MonitorRowView(monitor: Monitor(
            id: 1,
            name: "Jellyfin",
            url: "http://test.com",
            status: .up,
            responseTimeMs: 45
        ))
        MonitorRowView(monitor: Monitor(
            id: 2,
            name: "Sonarr",
            url: "http://test.com",
            status: .down,
            responseTimeMs: 1200
        ))
        MonitorRowView(monitor: Monitor(
            id: 3,
            name: "Radarr",
            url: "http://test.com",
            status: .pending,
            responseTimeMs: nil
        ))
    }
    .padding(6)
    .frame(width: 240)
}
