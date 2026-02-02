//
//  MonitorRowView.swift
//  UptimeBar
//
//  Created by Grant Megrabyan on 26/01/2026.
//

import SwiftUI
import AppKit

struct MonitorRowView: View {
    let monitor: Monitor
    @State private var isHovered = false
    
    var body: some View {
        Button(action: {
            let serviceURL = URLTransformer.toServiceURL(monitor.url)
            if let url = URL(string: serviceURL) {
                NSWorkspace.shared.open(url)
            }
        }) {
            HStack(spacing: 10) {
                // Status indicator (larger, with icon)
                StatusIconView(status: monitor.status)
                    .frame(width: 12, height: 12)
                
                // Monitor name
                Text(monitor.name)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(isHovered ? .white : .primary)
                    .lineLimit(1)
                
                Spacer(minLength: 8)
                
                // Response time with progress bar
                ResponseTimeView(
                    responseTimeMs: monitor.responseTimeMs,
                    isHovered: isHovered
                )
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
            .background(isHovered ? Color.accentColor : .clear, in: .rect(cornerRadius: 6))
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovered = hovering
            }
        }
        .help(tooltipText)
    }
    
    private var tooltipText: String {
        var text = "URL: \(monitor.url)\n"
        text += "Status: \(statusText)\n"
        if let responseTime = monitor.responseTimeMs, responseTime >= 0 {
            if responseTime < 1000 {
                text += "Response Time: \(Int(responseTime)) ms"
            } else {
                let seconds = responseTime / 1000
                text += "Response Time: \(seconds.formatted(.number.precision(.fractionLength(1)))) s"
            }
        }
        return text
    }
    
    private var statusText: String {
        switch monitor.status {
        case .up:
            return "Up"
        case .down:
            return "Down"
        case .pending:
            return "Pending"
        case .maintenance:
            return "Maintenance"
        case nil:
            return "Unknown"
        }
    }
}

struct StatusIconView: View {
    let status: MonitorStatus?
    
    var body: some View {
        ZStack {
            switch status {
            case .up:
                Circle()
                    .fill(.green)
            case .down:
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(.red)
                    .font(.system(size: 12))
            case .pending, nil:
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(.orange)
                    .font(.system(size: 12))
            case .maintenance:
                Image(systemName: "gearshape.fill")
                    .foregroundStyle(.blue)
                    .font(.system(size: 12))
            }
        }
    }
}

struct ResponseTimeView: View {
    let responseTimeMs: Double?
    let isHovered: Bool
    
    var body: some View {
        HStack(spacing: 6) {
            // Progress bar
            if let responseTime = responseTimeMs, responseTime >= 0 {
                ProgressBar(value: progressValue, color: performanceColor)
                    .frame(width: 50, height: 6)
            }
            
            // Response time text
            Text(responseTimeText)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(isHovered ? .white.opacity(0.9) : performanceColor)
                .frame(minWidth: 45, alignment: .trailing)
        }
    }
    
    private var responseTimeText: String {
        guard let responseTime = responseTimeMs else {
            return "—"
        }
        
        if responseTime < 0 {
            return "—"
        } else if responseTime < 1000 {
            return "\(Int(responseTime)) ms"
        } else {
            let seconds = responseTime / 1000
            return "\(seconds.formatted(.number.precision(.fractionLength(1)))) s"
        }
    }
    
    private var performanceColor: Color {
        guard let responseTime = responseTimeMs, responseTime >= 0 else {
            return .secondary
        }
        
        if responseTime < 100 {
            return Color(red: 0.06, green: 0.73, blue: 0.51) // Green
        } else if responseTime < 300 {
            return Color(red: 0.52, green: 0.80, blue: 0.09) // Light green
        } else if responseTime < 1000 {
            return Color(red: 0.96, green: 0.62, blue: 0.04) // Orange
        } else {
            return Color(red: 0.94, green: 0.27, blue: 0.27) // Red
        }
    }
    
    private var progressValue: Double {
        guard let responseTime = responseTimeMs, responseTime >= 0 else {
            return 0
        }
        
        // Scale: 0-100ms = 0-0.2, 100-300ms = 0.2-0.5, 300-1000ms = 0.5-0.8, >1000ms = 0.8-1.0
        if responseTime < 100 {
            return 0.2 * (responseTime / 100)
        } else if responseTime < 300 {
            return 0.2 + 0.3 * ((responseTime - 100) / 200)
        } else if responseTime < 1000 {
            return 0.5 + 0.3 * ((responseTime - 300) / 700)
        } else {
            return min(0.8 + 0.2 * ((responseTime - 1000) / 1000), 1.0)
        }
    }
}

struct ProgressBar: View {
    let value: Double
    let color: Color
    
    var body: some View {
        RoundedRectangle(cornerRadius: 3)
            .fill(.secondary.opacity(0.2))
            .overlay(
                RoundedRectangle(cornerRadius: 3)
                    .fill(color)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .scaleEffect(x: value, y: 1, anchor: .leading)
            )
    }
}

#Preview {
    let monitors = MonitorManager.sampleMixedStatusMonitors
    VStack(alignment: .leading, spacing: 2) {
        ForEach(monitors, id: \.id) {
            MonitorRowView(monitor: $0)
        }
    }
    .padding(6)
    .frame(width: 320)
}
