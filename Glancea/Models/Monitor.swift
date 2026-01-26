//
//  Monitor.swift
//  Glancea
//
//  Created by Grant Megrabyan on 26/01/2026.
//

import Foundation

public struct Monitor: Codable, Sendable, Hashable {
    public let id: Int
    public var name: String
    public let url: String
    public let status: MonitorStatus?
    public let responseTimeMs: Double?
}
