//
//  UptimeKumaMetricsParser.swift
//  Glancea
//
//  Created by Grant Megrabyan on 26/01/2026.
//

import Foundation
import OSLog

enum UptimeKumaMetricsParser {
    private static let logger = Logger(subsystem: "Glancea", category: "UptimeKumaMetricsParser")

    /// Parses Uptime Kuma `/metrics` text into a list of monitors.
    /// - Important: Uses `monitor_id` as the primary key, merges fields from
    ///   `monitor_status` and `monitor_response_time`.
    static func parseMonitors(from metricsText: String) -> [Monitor] {
        logger.info("Starting to parse metrics, text length: \(metricsText.count)")
        // Accumulate partial records keyed by monitor_id
        struct Partial {
            var id: Int
            var name: String?
            var url: String?
            var status: MonitorStatus?
            var responseTimeMs: Double?
        }

        var partialByID: [Int: Partial] = [:]

        for rawLine in metricsText.split(whereSeparator: \.isNewline) {
            let line = rawLine.trimmingCharacters(in: .whitespacesAndNewlines)
            if line.isEmpty || line.hasPrefix("#") { continue }

            guard let sample = parseSampleLine(line) else { continue }

            // We only care about these two metrics
            guard sample.metric == "monitor_status"
                || sample.metric == "monitor_response_time"
            else { continue }

            guard let idStr = sample.labels["monitor_id"],
                  let id = Int(idStr)
            else { continue }

            var partial = partialByID[id] ?? Partial(id: id)

            // These label keys exist in your sample; if missing we just skip.
            if let name = sample.labels["monitor_name"] { partial.name = name }
            if let url = sample.labels["monitor_url"] { partial.url = url }

            switch sample.metric {
            case "monitor_status":
                partial.status = MonitorStatus(stringValue: sample.value)
            case "monitor_response_time":
                // In your sample, -1 can appear (e.g. keyword monitor).
                // Keep it as-is; adjust here if you prefer nil for negatives.
                partial.responseTimeMs = Double(sample.value.trimmingCharacters(
                    in: .whitespaces
                ))
            default:
                break
            }

            partialByID[id] = partial
        }

        logger.info("Found \(partialByID.count) unique monitor IDs")
        for (id, partial) in partialByID {
            logger.info("Monitor \(id): name=\(partial.name ?? "nil"), url=\(partial.url ?? "nil"), status=\(String(describing: partial.status)), responseTime=\(String(describing: partial.responseTimeMs))")
        }

        // Build final Monitors; only include ones with at least name+url
        // (you can relax this if you want partial entries).
        let monitors: [Monitor] = partialByID.values
            .compactMap { p in
                guard let name = p.name, let url = p.url else { return nil }
                return Monitor(
                    id: p.id,
                    name: name,
                    url: url,
                    status: p.status,
                    responseTimeMs: p.responseTimeMs
                )
            }
            .sorted { $0.id < $1.id }

        logger.info("Returning \(monitors.count) monitors after filtering")
        return monitors
    }

    // MARK: - Prometheus text exposition parsing

    private struct Sample {
        let metric: String
        let labels: [String: String]
        let value: String
    }

    /// Parses: metric_name{key="value",...} 123
    /// Also supports: metric_name 123 (no labels), though we won't use it here.
    private static func parseSampleLine(_ line: String) -> Sample? {
        // Split into "left" and "value" by first whitespace after metric/labels.
        // Prometheus allows timestamps too; we ignore anything after the value.
        let parts = line.split(whereSeparator: { $0 == " " || $0 == "\t" })
        guard parts.count >= 2 else { return nil }

        let left = String(parts[0])
        let value = String(parts[1])

        if let braceIdx = left.firstIndex(of: "{") {
            let metric = String(left[..<braceIdx])

            guard let closeIdx = left.lastIndex(of: "}") else { return nil }
            let labelsRaw = String(left[left.index(after: braceIdx)..<closeIdx])
            let labels = parseLabels(labelsRaw)

            return Sample(metric: metric, labels: labels, value: value)
        } else {
            // No labels case: metric value
            return Sample(metric: left, labels: [:], value: value)
        }
    }

    /// Parses a labels section like: key="value",k2="v2"
    /// Handles basic escaping: \" and \\.
    private static func parseLabels(_ s: String) -> [String: String] {
        var result: [String: String] = [:]

        var i = s.startIndex

        func skipSpaces() {
            while i < s.endIndex, s[i].isWhitespace { i = s.index(after: i) }
        }

        while i < s.endIndex {
            skipSpaces()

            // Parse key up to '=' or ',' (defensive)
            let keyStart = i
            while i < s.endIndex, s[i] != "=", s[i] != "," {
                i = s.index(after: i)
            }
            let key = s[keyStart..<i].trimmingCharacters(in: .whitespaces)

            // If we hit a comma without '=', skip and continue
            if i < s.endIndex, s[i] == "," {
                i = s.index(after: i)
                continue
            }

            // Expect '='
            if i == s.endIndex || s[i] != "=" { break }
            i = s.index(after: i)
            skipSpaces()

            // Expect opening quote
            guard i < s.endIndex, s[i] == "\"" else { break }
            i = s.index(after: i)

            // Parse quoted value with simple escapes
            var value = ""
            while i < s.endIndex {
                let ch = s[i]
                if ch == "\\" {
                    let next = s.index(after: i)
                    if next < s.endIndex {
                        let escaped = s[next]
                        if escaped == "\"" { value.append("\"") }
                        else if escaped == "\\" { value.append("\\") }
                        else { value.append(escaped) }
                        i = s.index(after: next)
                        continue
                    } else {
                        break
                    }
                } else if ch == "\"" {
                    i = s.index(after: i)
                    break
                } else {
                    value.append(ch)
                    i = s.index(after: i)
                }
            }

            if !key.isEmpty {
                result[String(key)] = value
            }

            // Skip trailing spaces and optional comma
            skipSpaces()
            if i < s.endIndex, s[i] == "," {
                i = s.index(after: i)
            }
        }

        return result
    }
}
