//
//  FooterView.swift
//  Glancea
//
//  Created by Grant Megrabyan on 31/01/2026.
//

import SwiftUI

struct FooterView: View {
    @Bindable var monitorManager: MonitorManager

    var body: some View {
        HStack {
            // Refresh button
            Button(action: {
                Task {
                    await monitorManager.refresh()
                }
            }) {
                HStack(spacing: 4) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 11))
                        .rotationEffect(.degrees(monitorManager.isRefreshing ? 360 : 0))
                        .animation(
                            monitorManager.isRefreshing
                                ? .linear(duration: 1).repeatForever(autoreverses: false)
                                : .default,
                            value: monitorManager.isRefreshing
                        )
                    Text("Refresh")
                        .font(.system(size: 11, weight: .medium))
                }
                .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
            .disabled(monitorManager.isRefreshing)

            Spacer()

            // Quit button
            Button(action: {
                NSApplication.shared.terminate(nil)
            }) {
                HStack(spacing: 4) {
                    Image(systemName: "power")
                        .font(.system(size: 11))
                    Text("Quit")
                        .font(.system(size: 11, weight: .medium))
                }
                .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
        }
    }
}

#Preview {
    @Previewable @State var manager = {
        let s = AppSettings()
        let m = MonitorManager(settings: s)
        m.monitors = [
            Monitor(id: 1, name: "Test 1", url: "http://test.com", status: .up, responseTimeMs: 45),
        ]
        return m
    }()

    FooterView(monitorManager: manager)
        .frame(width: 300)
        .padding()
}
