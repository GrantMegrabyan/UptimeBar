//
//  MonitorStatusTests.swift
//  UptimeBar
//
//  Created by Grant Megrabyan on 01/02/2026.
//


import Testing
@testable import UptimeBar

struct MonitorStatusTests {

    @Test func initFromValidStrings() {
        #expect(MonitorStatus(stringValue: "0") == .down)
        #expect(MonitorStatus(stringValue: "1") == .up)
        #expect(MonitorStatus(stringValue: "3") == .pending)
        #expect(MonitorStatus(stringValue: "4") == .maintenance)
    }

    @Test func initFromInvalidStrings() {
        #expect(MonitorStatus(stringValue: "2") == nil)
        #expect(MonitorStatus(stringValue: "-1") == nil)
        #expect(MonitorStatus(stringValue: "abc") == nil)
        #expect(MonitorStatus(stringValue: "") == nil)
    }

    @Test func initTrimsWhitespace() {
        #expect(MonitorStatus(stringValue: " 1 ") == .up)
        #expect(MonitorStatus(stringValue: "\t0\t") == .down)
    }
}