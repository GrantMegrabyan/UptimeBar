//
//  MonitorStatus.swift
//  Glancea
//
//  Created by Grant Megrabyan on 26/01/2026.
//

import Foundation

public enum MonitorStatus: Int, Codable, Sendable {
    case down = 0 
    case up = 1
    case pending = 3
    case maintenance = 4
    
    init?(stringValue: String) {
        guard let intVal = Int(stringValue.trimmingCharacters(in: .whitespaces)),
              let status = MonitorStatus(rawValue: intVal)
        else { return nil }
        self = status
    }
}
