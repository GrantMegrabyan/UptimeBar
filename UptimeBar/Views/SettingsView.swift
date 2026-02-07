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
    @State private var selectedSection: SettingsPane = .connection
    
    enum TestConnectionResult {
        case success(Int)
        case failure(String)
    }
    
    enum SettingsPane: String, CaseIterable, Identifiable {
        case connection
        case display
        case statusPages
        
        var id: String { rawValue }
        
        var title: String {
            switch self {
            case .connection:
                return "Connection"
            case .display:
                return "Display"
            case .statusPages:
                return "Status Pages"
            }
        }
        
        var iconName: String {
            switch self {
            case .connection:
                return "network"
            case .display:
                return "menubar.rectangle"
            case .statusPages:
                return "square.grid.2x2"
            }
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
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
            
            HStack(spacing: 0) {
                sidebar
                
                Divider()
                
                detailPane
            }
            
            Divider()
            
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
    
    private var sidebar: some View {
        VStack(alignment: .center, spacing: 6) {
            ForEach(SettingsPane.allCases) { pane in
                Button {
                    selectedSection = pane
                } label: {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(selectedSection == pane ? Color.accentColor.opacity(0.16) : Color.clear)
                        
                        Image(systemName: pane.iconName)
                            .font(.system(size: 18, weight: .semibold))
                            .symbolRenderingMode(.hierarchical)
                    }
                    .frame(width: 44, height: 44)
                }
                .buttonStyle(.plain)
                .foregroundStyle(selectedSection == pane ? .primary : .secondary)
                .help(pane.title)
                .accessibilityLabel(pane.title)
            }
            
            Spacer()
        }
        .padding(8)
        .frame(width: 56, alignment: .top)
    }
    
    private var detailPane: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    switch selectedSection {
                    case .connection:
                        connectionSettingsContent
                    case .display:
                        displaySettingsContent
                    case .statusPages:
                        statusPageSettingsContent
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(10)
            }
            
            Text("UptimeBar v1.0.0 (\(Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"))")
                .font(.system(size: 10))
                .foregroundStyle(.tertiary)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.vertical, 8)
        }
    }
    
    private var connectionSettingsContent: some View {
        SettingsSection(title: "Connection") {
            settingsCard {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Base URL")
                        .font(.system(size: 11, weight: .medium))
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
            }
            
            settingsCard {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Authentication method")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.secondary)
                    
                    Picker("Authentication", selection: $settings.authenticationType) {
                        ForEach(AuthenticationType.allCases, id: \.self) { authType in
                            Text(authType.displayName).tag(authType)
                        }
                    }
                    .pickerStyle(.menu)
                    .labelsHidden()
                    .onChange(of: settings.authenticationType) {
                        testResult = nil
                    }
                }
                
                switch settings.authenticationType {
                case .apiKey:
                    VStack(alignment: .leading, spacing: 4) {
                        Text("API Key")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(.secondary)
                        
                        SecureField("API Key", text: $settings.uptimeKumaAPIKey)
                            .textFieldStyle(.roundedBorder)
                            .font(.system(size: 12, design: .monospaced))
                    }
                    
                case .basicAuth:
                    VStack(alignment: .leading, spacing: 8) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Username")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundStyle(.secondary)
                            
                            TextField("Username", text: $settings.uptimeKumaUsername)
                                .textFieldStyle(.roundedBorder)
                                .font(.system(size: 12))
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Password")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundStyle(.secondary)
                            
                            SecureField("Password", text: $settings.uptimeKumaPassword)
                                .textFieldStyle(.roundedBorder)
                                .font(.system(size: 12))
                        }
                    }
                    
                case .none:
                    EmptyView()
                }
            }
            
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
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                        Text("Connected (\(count) monitors)")
                            .foregroundStyle(.green)
                            .lineLimit(1)
                    }
                    .font(.system(size: 11))
                case .failure(let message):
                    HStack(spacing: 4) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.red)
                        Text(message)
                            .foregroundStyle(.red)
                            .lineLimit(2)
                    }
                    .font(.system(size: 11))
                }
            }
        }
    }
    
    private var displaySettingsContent: some View {
        SettingsSection(title: "Display") {
            settingsCard {
                settingsInlineRow(title: "Show issue count", subtitle: "Badge in menu bar") {
                    Toggle("", isOn: $settings.showUnhealthyCountInMenuBar)
                        .labelsHidden()
                        .toggleStyle(.switch)
                }
            }
            
            settingsCard {
                settingsInlineRow(title: "Refresh interval", subtitle: "Auto-refresh frequency") {
                    Picker("Refresh Interval", selection: $settings.refreshInterval) {
                        Text("30 seconds").tag(30)
                        Text("1 minute").tag(60)
                        Text("2 minutes").tag(120)
                        Text("5 minutes").tag(300)
                        Text("10 minutes").tag(600)
                    }
                    .pickerStyle(.menu)
                    .labelsHidden()
                    .frame(width: 128, alignment: .trailing)
                }
            }
        }
    }
    
    private var statusPageSettingsContent: some View {
        VStack(alignment: .leading, spacing: 14) {
            SettingsSection(title: "Status Pages") {
                settingsCard {
                    settingsInlineRow(title: "Status page grouping", subtitle: "Group by Kuma pages") {
                        Toggle("", isOn: $settings.statusPageGroupingEnabled)
                            .labelsHidden()
                            .toggleStyle(.switch)
                    }
                }
            }
            
            if settings.statusPageGroupingEnabled {
                settingsCard {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Add slug")
                            .font(.system(size: 11, weight: .medium))
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
                        Text("Use the status page URL slug.")
                            .font(.system(size: 10))
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }
                
                settingsCard {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Configured slugs")
                            .font(.system(size: 11, weight: .medium))
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
                            Text("Catches unassigned monitors.")
                                .font(.system(size: 10))
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                            Spacer()
                        }
                        .padding(.vertical, 2)
                    }
                }
            } else {
                settingsCard {
                    Text("Enable grouping to manage custom slugs.")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
    
    @ViewBuilder
    private func settingsInlineRow<Control: View>(
        title: String,
        subtitle: String? = nil,
        @ViewBuilder control: () -> Control
    ) -> some View {
        HStack(alignment: .center, spacing: 8) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 12, weight: .medium))
                    .lineLimit(1)
                if let subtitle {
                    Text(subtitle)
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
            Spacer(minLength: 6)
            control()
        }
    }
    
    @ViewBuilder
    private func settingsCard<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            content()
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color(nsColor: .controlBackgroundColor).opacity(0.36))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(Color.primary.opacity(0.08), lineWidth: 1)
        )
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
