# UptimeBar Agent Notes

## Purpose
MacOS menu bar app that polls an Uptime Kuma `/metrics` endpoint, parses monitor status/response time, and renders a compact status list with settings.

## Architecture (Data Flow)
1. `UptimeBarApp.swift` creates `AppSettings` and `MonitorManager`.
2. `MonitorManager` owns refresh loop and aggregates health state.
3. `UptimeKumaMetricsProvider` fetches `/metrics` with optional Basic Auth and calls `UptimeKumaMetricsParser`.
4. Parsed `Monitor` models drive SwiftUI views in `Views/`.

## Key Files
- `UptimeBar/UptimeBarApp.swift`: App entry and menu bar label/badge.
- `UptimeBar/Models/AppSettings.swift`: UserDefaults-backed settings and URL validation.
- `UptimeBar/Services/MonitorManager.swift`: Refresh loop, aggregate status, and error handling.
- `UptimeBar/Services/UptimeKumaMetricsProvider.swift`: Network fetch with retry and error mapping.
- `UptimeBar/Services/UptimeKumaMetricsParser.swift`: Prometheus text parsing for `monitor_status` and `monitor_response_time`.
- `UptimeBar/Views/MonitorsListView.swift`: Main menu UI with collapsible sections.
- `UptimeBar/Views/SettingsView.swift`: Configuration UI + test connection.
- `UptimeBar/Utilities/URLTransformer.swift`: Converts health check URLs to service URLs for browser open.

## Behavior Notes
- Refresh interval is stored as seconds in UserDefaults and normalized to presets (30, 60, 120, 300, 600).
- `MonitorManager` runs a continuous `Task` loop and respects `settings.refreshInterval`.
- Error surface uses `MonitorFetchError.userMessage` for UI; retry only on network/timeout/server errors.
- Parser merges metrics by `monitor_id`, drops entries missing name or URL, and sorts by `id`.

## Development Tips
- Run/debug from Xcode; tests live in `UptimeBarTests/` and `UptimeBarUITests/`.
- SwiftUI previews use `MonitorManager.preview(...)` and `AppSettings.preview(...)`.
