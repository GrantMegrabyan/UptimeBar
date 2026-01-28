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
    }
}
