//
//  SettingsView.swift
//  Glancea
//
//  Created by Grant Megrabyan on 29/01/2026.
//

import SwiftUI

struct SettingsView: View {
    @Bindable var settings: AppSettings
    var onDismiss: () -> Void = {}
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                Text("Settings")
                    .font(.system(size: 16, weight: .semibold))
                
                Spacer()
                
                Button(action: {
                    onDismiss()
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                        .font(.system(size: 16))
                }
                .buttonStyle(.plain)
            }
            .padding(16)
            
            Divider()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Uptime Kuma Settings
                    SettingsSection(title: "Uptime Kuma Connection") {
                        VStack(alignment: .leading, spacing: 12) {
                            // URL
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Metrics URL")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundStyle(.secondary)
                                
                                TextField("http://localhost:3001/metrics", text: $settings.uptimeKumaURL)
                                    .textFieldStyle(.roundedBorder)
                                    .font(.system(size: 12, design: .monospaced))
                            }
                            
                            // Username
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Username")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundStyle(.secondary)
                                
                                TextField("Username", text: $settings.uptimeKumaUsername)
                                    .textFieldStyle(.roundedBorder)
                                    .font(.system(size: 12))
                            }
                            
                            // Password
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Password")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundStyle(.secondary)
                                
                                SecureField("Password", text: $settings.uptimeKumaPassword)
                                    .textFieldStyle(.roundedBorder)
                                    .font(.system(size: 12))
                            }
                        }
                    }
                    
                    // Refresh Settings
                    SettingsSection(title: "Refresh Interval") {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Slider(value: Binding(
                                    get: { Double(settings.refreshInterval) },
                                    set: { settings.refreshInterval = Int($0) }
                                ), in: 30...600, step: 30)
                                
                                Text("\(settings.refreshInterval)s")
                                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                                    .foregroundStyle(.secondary)
                                    .frame(width: 50, alignment: .trailing)
                            }
                            
                            Text("How often to automatically refresh monitor data")
                                .font(.system(size: 11))
                                .foregroundStyle(.secondary)
                        }
                    }
                    
                    // Info Section
                    SettingsSection(title: "About") {
                        VStack(alignment: .leading, spacing: 6) {
                            InfoRow(label: "Version", value: "1.0.0")
                            InfoRow(label: "Build", value: Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1")
                        }
                    }
                }
                .padding(16)
            }
            
            Divider()
            
            // Footer
            HStack {
                Spacer()
                
                Button("Done") {
                    settings.save()
                    onDismiss()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
            }
            .padding(12)
        }
        .frame(width: 320, height: 500)
        .background(Color(nsColor: .windowBackgroundColor))
        .onDisappear {
            settings.save()
        }
    }
}

struct SettingsSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.primary)
            
            content
        }
        .padding(.vertical, 4)
    }
}

struct InfoRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
            
            Spacer()
            
            Text(value)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.primary)
        }
    }
}

#Preview {
    SettingsView(settings: AppSettings.preview(), onDismiss: {})
}
