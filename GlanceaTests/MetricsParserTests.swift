//
//  MetricsParserTests.swift
//  GlanceaTests
//
//  Created by Grant Megrabyan on 01/02/2026.
//

import Testing
@testable import Glancea

struct MetricsParserTests {
    
    // MARK: Valid Input
    
    @Test func parsesMultipleMonitors() {
        let input = """
        # HELP monitor_status Monitor Status (1 = up, 0 = down)
        # TYPE monitor_status gauge
        monitor_status{monitor_id="1",monitor_name="Jellyfin",monitor_url="https://jelly.example.com/"} 1
        monitor_status{monitor_id="2",monitor_name="Plex",monitor_url="https://plex.example.com/"} 0
        # HELP monitor_response_time Monitor Response Time (ms)
        # TYPE monitor_response_time gauge
        monitor_response_time{monitor_id="1",monitor_name="Jellyfin",monitor_url="https://jelly.example.com/"} 842
        monitor_response_time{monitor_id="2",monitor_name="Plex",monitor_url="https://plex.example.com/"} 126
        """
        let monitors = UptimeKumaMetricsParser.parseMonitors(from: input)
        
        #expect(monitors.count == 2)
        #expect(monitors[0].id == 1)
        #expect(monitors[0].name == "Jellyfin")
        #expect(monitors[0].url == "https://jelly.example.com/")
        #expect(monitors[0].status == .up)
        #expect(monitors[0].responseTimeMs == 842)
        
        #expect(monitors[1].id == 2)
        #expect(monitors[1].name == "Plex")
        #expect(monitors[1].status == .down)
        #expect(monitors[1].responseTimeMs == 126)
    }
    
    @Test func mergesStatusAndResponseTimeByID() {
        let input = """
        monitor_status{monitor_id="3",monitor_name="Svc",monitor_url="http://svc"} 1
        monitor_response_time{monitor_id="3",monitor_name="Svc",monitor_url="http://svc"} 250
        """
        let monitors = UptimeKumaMetricsParser.parseMonitors(from: input)
        
        #expect(monitors.count == 1)
        #expect(monitors[0].status == .up)
        #expect(monitors[0].responseTimeMs == 250)
    }
    
    // MARK: Partial Data
    
    @Test func statusOnlyWithoutResponseTime() {
        let input = """
        monitor_status{monitor_id="1",monitor_name="Svc",monitor_url="http://svc"} 1
        """
        let monitors = UptimeKumaMetricsParser.parseMonitors(from: input)
        
        #expect(monitors.count == 1)
        #expect(monitors[0].status == .up)
        #expect(monitors[0].responseTimeMs == nil)
    }
    
    @Test func responseTimeOnlyWithoutStatus() {
        let input = """
        monitor_response_time{monitor_id="1",monitor_name="Svc",monitor_url="http://svc"} 500
        """
        let monitors = UptimeKumaMetricsParser.parseMonitors(from: input)
        
        #expect(monitors.count == 1)
        #expect(monitors[0].status == nil)
        #expect(monitors[0].responseTimeMs == 500)
    }
    
    @Test func missingNameExcludesMonitor() {
        let input = """
        monitor_status{monitor_id="1",monitor_url="http://svc"} 1
        """
        let monitors = UptimeKumaMetricsParser.parseMonitors(from: input)
        
        #expect(monitors.isEmpty)
    }
    
    @Test func missingURLExcludesMonitor() {
        let input = """
        monitor_status{monitor_id="1",monitor_name="Svc"} 1
        """
        let monitors = UptimeKumaMetricsParser.parseMonitors(from: input)
        
        #expect(monitors.isEmpty)
    }
    
    // MARK: Edge Cases
    
    @Test func emptyInput() {
        let monitors = UptimeKumaMetricsParser.parseMonitors(from: "")
        #expect(monitors.isEmpty)
    }
    
    @Test func commentsAndBlankLinesOnly() {
        let input = """
        # HELP some metric
        # TYPE some metric gauge
        
        # another comment
        """
        let monitors = UptimeKumaMetricsParser.parseMonitors(from: input)
        #expect(monitors.isEmpty)
    }
    
    @Test func negativeResponseTime() {
        let input = """
        monitor_response_time{monitor_id="1",monitor_name="Keyword",monitor_url="http://kw"} -1
        monitor_status{monitor_id="1",monitor_name="Keyword",monitor_url="http://kw"} 1
        """
        let monitors = UptimeKumaMetricsParser.parseMonitors(from: input)
        
        #expect(monitors.count == 1)
        #expect(monitors[0].responseTimeMs == -1)
    }
    
    @Test func unknownStatusCode() {
        let input = """
        monitor_status{monitor_id="1",monitor_name="Svc",monitor_url="http://svc"} 99
        """
        let monitors = UptimeKumaMetricsParser.parseMonitors(from: input)
        
        #expect(monitors.count == 1)
        #expect(monitors[0].status == nil)
    }
    
    @Test func allStatusCodes() {
        let input = """
        monitor_status{monitor_id="1",monitor_name="A",monitor_url="http://a"} 0
        monitor_status{monitor_id="2",monitor_name="B",monitor_url="http://b"} 1
        monitor_status{monitor_id="3",monitor_name="C",monitor_url="http://c"} 3
        monitor_status{monitor_id="4",monitor_name="D",monitor_url="http://d"} 4
        """
        let monitors = UptimeKumaMetricsParser.parseMonitors(from: input)
        
        #expect(monitors[0].status == .down)
        #expect(monitors[1].status == .up)
        #expect(monitors[2].status == .pending)
        #expect(monitors[3].status == .maintenance)
    }
    
    @Test func unrelatedMetricsAreIgnored() {
        let input = """
        process_cpu_seconds_total 0.12
        monitor_status{monitor_id="1",monitor_name="Svc",monitor_url="http://svc"} 1
        nodejs_heap_size_total_bytes 12345678
        """
        let monitors = UptimeKumaMetricsParser.parseMonitors(from: input)
        
        #expect(monitors.count == 1)
        #expect(monitors[0].name == "Svc")
    }
    
    @Test func malformedLinesAreSkipped() {
        let input = """
        this is not valid prometheus
        monitor_status{monitor_id="1",monitor_name="Svc",monitor_url="http://svc"} 1
        {broken_line
        also broken}
        """
        let monitors = UptimeKumaMetricsParser.parseMonitors(from: input)
        
        #expect(monitors.count == 1)
    }
    
    @Test func nonNumericMonitorIDIsSkipped() {
        let input = """
        monitor_status{monitor_id="abc",monitor_name="Svc",monitor_url="http://svc"} 1
        """
        let monitors = UptimeKumaMetricsParser.parseMonitors(from: input)
        #expect(monitors.isEmpty)
    }
    
    // MARK: Label Escaping
    
    @Test func escapedQuotesInLabels() {
        let input = """
        monitor_status{monitor_id="1",monitor_name="My \\"Fancy\\" Service",monitor_url="http://svc"} 1
        """
        let monitors = UptimeKumaMetricsParser.parseMonitors(from: input)
        
        #expect(monitors.count == 1)
        #expect(monitors[0].name == "My \"Fancy\" Service")
    }
    
    @Test func escapedBackslashInLabels() {
        let input = """
        monitor_status{monitor_id="1",monitor_name="path\\\\test",monitor_url="http://svc"} 1
        """
        let monitors = UptimeKumaMetricsParser.parseMonitors(from: input)
        
        #expect(monitors.count == 1)
        #expect(monitors[0].name == "path\\test")
    }
    
    @Test func valueWithTimestamp() {
        let input = """
        monitor_status{monitor_id="1",monitor_name="Svc",monitor_url="http://svc"} 1 1706000000000
        """
        let monitors = UptimeKumaMetricsParser.parseMonitors(from: input)
        
        #expect(monitors.count == 1)
        #expect(monitors[0].status == .up)
    }
    
}
