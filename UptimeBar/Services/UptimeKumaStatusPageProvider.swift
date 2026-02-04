//
//  UptimeKumaStatusPageProvider.swift
//  UptimeBar
//
//  Created by Grant Megrabyan on 03/02/2026.
//

import Foundation
import OSLog

struct StatusPageSummary: Sendable {
    let slug: String
    let groups: [StatusPageGroupSummary]
}

struct StatusPageGroupSummary: Sendable {
    let id: Int
    let name: String
    let weight: Int
    let monitorIDs: [Int]
}

class UptimeKumaStatusPageProvider {
    private let logger = Logger(subsystem: "UptimeBar", category: "UptimeKumaStatusPageProvider")
    private let baseURL: URL
    private let session: URLSession

    init(baseURL: URL) {
        self.baseURL = baseURL
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 10
        self.session = URLSession(configuration: config)
    }

    func fetchStatusPages(slugs: [String]) async -> [StatusPageSummary] {
        guard !slugs.isEmpty else { return [] }

        return await withTaskGroup(of: StatusPageSummary?.self) { group in
            for slug in slugs {
                let trimmed = slug.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !trimmed.isEmpty else { continue }
                group.addTask { [weak self] in
                    guard let self else { return nil }
                    do {
                        return try await self.fetchStatusPage(slug: trimmed)
                    } catch {
                        self.logger.error("Status page fetch failed for slug \(trimmed, privacy: .public): \(error.localizedDescription)")
                        return nil
                    }
                }
            }

            var results: [StatusPageSummary] = []
            for await summary in group {
                if let summary {
                    results.append(summary)
                }
            }
            return results
        }
    }

    private func fetchStatusPage(slug: String) async throws -> StatusPageSummary {
        guard let url = buildStatusPageURL(for: slug) else {
            logger.error("Invalid status page URL for slug: \(slug, privacy: .public)")
            throw MonitorFetchError.invalidURL
        }

        var request = URLRequest(url: url)

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch let urlError as URLError where urlError.code == .timedOut {
            logger.error("Status page request timed out")
            throw MonitorFetchError.timeout
        } catch {
            logger.error("Status page network error: \(error.localizedDescription)")
            throw MonitorFetchError.networkError(underlying: error)
        }

        if let httpResponse = response as? HTTPURLResponse {
            switch httpResponse.statusCode {
            case 200..<300:
                break
            case 401, 403:
                logger.error("Status page authentication failed: \(httpResponse.statusCode)")
                throw MonitorFetchError.authenticationFailed
            default:
                logger.error("Status page server error: \(httpResponse.statusCode)")
                throw MonitorFetchError.serverError(statusCode: httpResponse.statusCode)
            }
        }

        let statusPage = try JSONDecoder().decode(StatusPageResponse.self, from: data)
        let groups = statusPage.publicGroupList.map { group in
            StatusPageGroupSummary(
                id: group.id,
                name: group.name,
                weight: group.weight,
                monitorIDs: group.monitorList.map { $0.id }
            )
        }

        return StatusPageSummary(slug: statusPage.config.slug, groups: groups)
    }

    private func buildStatusPageURL(for slug: String) -> URL? {
        baseURL.appendingPathComponent(slug)
    }
}

private struct StatusPageResponse: Decodable {
    let config: StatusPageConfig
    let publicGroupList: [StatusPageGroup]
}

private struct StatusPageConfig: Decodable {
    let slug: String
}

private struct StatusPageGroup: Decodable {
    let monitorList: [StatusPageMonitor]
    let id: Int
    let name: String
    let weight: Int
}

private struct StatusPageMonitor: Decodable {
    let id: Int
}
