//
//  SettingsView.swift
//  UptimeBar
//
//  Created by Grant Megrabyan on 29/01/2026.
//

import SwiftUI

struct SettingsView: View {
    @Bindable var settings: AppSettings
    var onDismiss: () -> Void = {}
    @State private var testResult: TestConnectionResult?
    @State private var isTesting = false

    // Local editable copy of settings
    @State private var localURL: String = ""
    @State private var localUsername: String = ""
    @State private var localPassword: String = ""
    @State private var localRefreshInterval: Int = 120
    @State private var localShowUnhealthyCount: Bool = true

    enum TestConnectionResult {
        case success(Int)
        case failure(String)
    }
    
    // Computed property for URL validation using local state
    private var urlValidationError: String? {
        AppSettings.validateURL(localURL)
    }

    private var isURLValid: Bool {
        urlValidationError == nil
    }

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
                                
                                TextField("http://localhost:3001/metrics", text: $localURL)
                                    .textFieldStyle(.roundedBorder)
                                    .font(.system(size: 12, design: .monospaced))
                                    .onChange(of: localURL) {
                                        testResult = nil
                                    }

                                if let error = urlValidationError {
                                    Text(error)
                                        .font(.system(size: 10))
                                        .foregroundStyle(.red)
                                }
                            }
                            
                            // Username and Password (side-by-side)
                            HStack(spacing: 12) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Username")
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundStyle(.secondary)

                                    TextField("Username", text: $localUsername)
                                        .textFieldStyle(.roundedBorder)
                                        .font(.system(size: 12))
                                }

                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Password")
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundStyle(.secondary)

                                    SecureField("Password", text: $localPassword)
                                        .textFieldStyle(.roundedBorder)
                                        .font(.system(size: 12))
                                }
                            }

                            // Test Connection
                            HStack(spacing: 8) {
                                Button {
                                    testConnection()
                                } label: {
                                    HStack(spacing: 4) {
                                        if isTesting {
                                            ProgressView()
                                                .controlSize(.mini)
                                        }
                                        Text("Test Connection")
                                    }
                                }
                                .controlSize(.small)
                                .disabled(!isURLValid || localURL.isEmpty || isTesting)

                                if let result = testResult {
                                    switch result {
                                    case .success(let count):
                                        HStack(spacing: 3) {
                                            Image(systemName: "checkmark.circle.fill")
                                                .foregroundStyle(.green)
                                            Text("Connected — \(count) monitors")
                                                .foregroundStyle(.green)
                                        }
                                        .font(.system(size: 11))
                                    case .failure(let message):
                                        HStack(spacing: 3) {
                                            Image(systemName: "xmark.circle.fill")
                                                .foregroundStyle(.red)
                                            Text(message)
                                                .foregroundStyle(.red)
                                        }
                                        .font(.system(size: 11))
                                    }
                                }
                            }
                        }
                    }
                    
                    // General Settings
                    SettingsSection(title: "General") {
                        VStack(alignment: .leading, spacing: 12) {
                            // Show unhealthy count toggle
                            Toggle(isOn: $localShowUnhealthyCount) {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Show unhealthy monitor count")
                                        .font(.system(size: 12))
                                    Text("Display the number of unhealthy monitors in the menu bar")
                                        .font(.system(size: 11))
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .toggleStyle(.switch)

                            // Refresh interval picker
                            VStack(alignment: .leading, spacing: 8) {
                                Picker("Refresh Interval", selection: $localRefreshInterval) {
                                    Text("30 seconds").tag(30)
                                    Text("1 minute").tag(60)
                                    Text("2 minutes").tag(120)
                                    Text("5 minutes").tag(300)
                                    Text("10 minutes").tag(600)
                                }
                                .pickerStyle(.menu)
                                .labelsHidden()

                                Text("How often to automatically refresh monitor data")
                                    .font(.system(size: 11))
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    
                }
                .padding(16)

                // Compact version info footer
                Text("UptimeBar v1.0.0 (\(Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"))")
                    .font(.system(size: 10))
                    .foregroundStyle(.tertiary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.bottom, 8)
            }
            
            Divider()

            // Footer
            HStack {
                Spacer()

                Button("Cancel") {
                    onDismiss()
                }
                .controlSize(.small)

                Button("Save") {
                    saveChanges()
                    onDismiss()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
                .disabled(!isURLValid)
            }
            .padding(12)
        }
        .frame(width: 320, height: 500)
        .background(Color(nsColor: .windowBackgroundColor))
        .onAppear {
            loadLocalState()
        }
    }

    private func loadLocalState() {
        localURL = settings.uptimeKumaURL
        localUsername = settings.uptimeKumaUsername
        localPassword = settings.uptimeKumaPassword
        localRefreshInterval = settings.refreshInterval
        localShowUnhealthyCount = settings.showUnhealthyCountInMenuBar
    }

    private func saveChanges() {
        settings.uptimeKumaURL = localURL
        settings.uptimeKumaUsername = localUsername
        settings.uptimeKumaPassword = localPassword
        settings.refreshInterval = localRefreshInterval
        settings.showUnhealthyCountInMenuBar = localShowUnhealthyCount
        settings.save()
    }

    private func testConnection() {
        isTesting = true
        testResult = nil
        Task {
            // Create a temporary settings object with current local values for testing
            let tempSettings = AppSettings()
            tempSettings.uptimeKumaURL = localURL
            tempSettings.uptimeKumaUsername = localUsername
            tempSettings.uptimeKumaPassword = localPassword

            let provider = UptimeKumaMetricsProvider(settings: tempSettings)
            do {
                let monitors = try await provider.getMonitors()
                testResult = .success(monitors.count)
            } catch let error as MonitorFetchError {
                testResult = .failure(error.userMessage)
            } catch {
                testResult = .failure(error.localizedDescription)
            }
            isTesting = false
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


#Preview {
    SettingsView(settings: AppSettings.preview(), onDismiss: {})
}
