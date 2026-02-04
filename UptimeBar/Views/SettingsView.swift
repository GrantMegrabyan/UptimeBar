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
    @State private var newStatusPageSlug = ""

    enum TestConnectionResult {
        case success(Int)
        case failure(String)
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
                                Text("Base URL")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundStyle(.secondary)
                                
                                TextField("http://localhost:3001", text: $settings.uptimeKumaBaseURL)
                                    .textFieldStyle(.roundedBorder)
                                    .font(.system(size: 12, design: .monospaced))
                                    .onChange(of: settings.uptimeKumaBaseURL) {
                                        testResult = nil
                                    }

                                if let error = settings.urlValidationError {
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
                                    
                                    TextField("Username", text: $settings.uptimeKumaUsername)
                                        .textFieldStyle(.roundedBorder)
                                        .font(.system(size: 12))
                                }

                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Password")
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundStyle(.secondary)

                                    SecureField("Password", text: $settings.uptimeKumaPassword)
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
                                .disabled(!settings.isURLValid || settings.normalizedBaseURL.isEmpty || isTesting)

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
                            Toggle(isOn: $settings.showUnhealthyCountInMenuBar) {
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
                                Picker("Refresh Interval", selection: $settings.refreshInterval) {
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

                            Toggle(isOn: $settings.statusPageGroupingEnabled) {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Enable status page grouping")
                                        .font(.system(size: 12))
                                    Text("Group monitors using Uptime Kuma status pages")
                                        .font(.system(size: 11))
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .toggleStyle(.switch)
                        }
                    }

                    if settings.statusPageGroupingEnabled {
                        SettingsSection(title: "Status Pages") {
                            VStack(alignment: .leading, spacing: 12) {
                                VStack(alignment: .leading, spacing: 6) {
                                    Text("Add status page slug")
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundStyle(.secondary)

                                    HStack(spacing: 8) {
                                        TextField("media", text: $newStatusPageSlug)
                                            .textFieldStyle(.roundedBorder)
                                            .font(.system(size: 12, design: .monospaced))
                                            .onSubmit {
                                                addStatusPageSlug()
                                            }

                                        Button("Add") {
                                            addStatusPageSlug()
                                        }
                                        .controlSize(.small)
                                        .disabled(!canAddStatusPageSlug)
                                    }
                                    Text("Use the slug from your Uptime Kuma status page URL.")
                                        .font(.system(size: 11))
                                        .foregroundStyle(.secondary)
                                }

                                VStack(alignment: .leading, spacing: 6) {
                                    Text("Configured slugs")
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundStyle(.secondary)

                                    if settings.statusPageSlugs.isEmpty {
                                        Text("No custom slugs yet.")
                                            .font(.system(size: 11))
                                            .foregroundStyle(.secondary)
                                    }

                                    ForEach(Array(settings.statusPageSlugs.enumerated()), id: \.element) { index, slug in
                                        HStack(spacing: 8) {
                                            Text(slug)
                                                .font(.system(size: 12, design: .monospaced))
                                            Spacer()
                                            Button {
                                                moveStatusPageSlug(from: index, offset: -1)
                                            } label: {
                                                Image(systemName: "arrow.up")
                                            }
                                            .buttonStyle(.borderless)
                                            .disabled(index == 0)

                                            Button {
                                                moveStatusPageSlug(from: index, offset: 1)
                                            } label: {
                                                Image(systemName: "arrow.down")
                                            }
                                            .buttonStyle(.borderless)
                                            .disabled(index == settings.statusPageSlugs.count - 1)

                                            Button {
                                                removeStatusPageSlug(at: index)
                                            } label: {
                                                Image(systemName: "trash")
                                            }
                                            .buttonStyle(.borderless)
                                        }
                                        .padding(.vertical, 2)
                                    }

                                    HStack(spacing: 8) {
                                        Text(AppSettings.defaultStatusPageSlug)
                                            .font(.system(size: 12, design: .monospaced))
                                        Text("Includes monitors not listed above.")
                                            .font(.system(size: 11))
                                            .foregroundStyle(.secondary)
                                        Spacer()
                                    }
                                    .padding(.vertical, 2)
                                }
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
                
                Button("Done") {
                    settings.save()
                    onDismiss()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
                .disabled(!settings.isURLValid)
            }
            .padding(12)
        }
        .frame(width: 320, height: 500)
        .background(Color(nsColor: .windowBackgroundColor))
        .onDisappear {
            settings.save()
        }
    }

    private func testConnection() {
        isTesting = true
        testResult = nil
        Task {
            let provider = UptimeKumaMetricsProvider(settings: settings)
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

    private var normalizedStatusPageSlug: String {
        newStatusPageSlug.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var canAddStatusPageSlug: Bool {
        let slug = normalizedStatusPageSlug
        guard !slug.isEmpty else { return false }
        guard slug.lowercased() != AppSettings.defaultStatusPageSlug else { return false }
        return !settings.statusPageSlugs.contains { $0.caseInsensitiveCompare(slug) == .orderedSame }
    }

    private func addStatusPageSlug() {
        let slug = normalizedStatusPageSlug
        guard !slug.isEmpty else { return }
        guard slug.lowercased() != AppSettings.defaultStatusPageSlug else { return }
        guard !settings.statusPageSlugs.contains(where: { $0.caseInsensitiveCompare(slug) == .orderedSame }) else { return }
        settings.statusPageSlugs.append(slug)
        newStatusPageSlug = ""
    }

    private func removeStatusPageSlug(at index: Int) {
        guard settings.statusPageSlugs.indices.contains(index) else { return }
        settings.statusPageSlugs.remove(at: index)
    }

    private func moveStatusPageSlug(from index: Int, offset: Int) {
        let newIndex = index + offset
        guard settings.statusPageSlugs.indices.contains(index),
              settings.statusPageSlugs.indices.contains(newIndex)
        else { return }
        let slug = settings.statusPageSlugs.remove(at: index)
        settings.statusPageSlugs.insert(slug, at: newIndex)
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
