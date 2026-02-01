//
//  HeaderView.swift
//  UptimeBar
//
//  Created by Grant Megrabyan on 31/01/2026.
//

import SwiftUI

struct HeaderView: View {
    @Bindable var monitorManager: MonitorManager
    let openSettingsWindow: () -> Void
    
    var body: some View {
        HStack(spacing: 6) {
            Text("\(monitors.count) monitors")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.secondary)
            
            if upCount > 0 {
                Text("•")
                    .foregroundStyle(.secondary)
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 9))
                    .foregroundStyle(.green)
                Text("\(upCount)")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }
            
            if downCount > 0 {
                Text("•")
                    .foregroundStyle(.secondary)
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 9))
                    .foregroundStyle(.red)
                Text("\(downCount)")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
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
}

#Preview {
    @Previewable @State var manager = MonitorManager.preview(with: MonitorManager.sampleMixedStatusMonitors)
    
    HeaderView(monitorManager: manager, openSettingsWindow: {})
        .frame(width: 300)
        .padding()
}
