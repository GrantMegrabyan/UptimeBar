//
//  StatusPageSection.swift
//  UptimeBar
//
//  Created by Grant Megrabyan on 03/02/2026.
//

import Foundation

struct StatusPageSection: Identifiable, Hashable, Sendable {
    let id: String
    let title: String
    let groups: [StatusPageMonitorGroup]
    let monitors: [Monitor]
    let isDefault: Bool
}

struct StatusPageMonitorGroup: Identifiable, Hashable, Sendable {
    let id: Int
    let title: String
    let weight: Int
    let monitors: [Monitor]
}
