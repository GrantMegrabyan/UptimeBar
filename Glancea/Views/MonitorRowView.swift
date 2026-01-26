//
//  MonitorRowView.swift
//  Glancea
//
//  Created by Grant Megrabyan on 26/01/2026.
//

import SwiftUI

struct MonitorRowView: View {
    let monitor: Monitor

    var body: some View {
        HStack {
            Circle()
                .fill(statusColor)
                .frame(width: 10, height: 10)
                .overlay(
                    Circle()
                        .strokeBorder(statusColor.opacity(0.3), lineWidth: 2)
                )

            Text(monitor.name)
                .font(.subheadline)
            
            Text("test")
        }

    }

    private var statusColor: Color {
        if let status = monitor.status {
            switch status {
            case .up:
                return .green
            case .down:
                return .red
            case .pending:
                return .yellow
            case .maintenance:
                return .blue
            }
        } else {
            return .gray
        }
    }
}

#Preview {
    let monitor = Monitor(
        id: 1,
        name: "test",
        url: "http://test.com",
        status: .up,
        responseTimeMs: 2.4
    )
    MonitorRowView(monitor: monitor)
}
