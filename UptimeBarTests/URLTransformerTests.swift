//
//  URLTransformerTests.swift
//  UptimeBarTests
//
//  Created by Grant Megrabyan on 02/02/2026.
//

import XCTest
@testable import UptimeBar

final class URLTransformerTests: XCTestCase {
    func testTransformsHealthCheckURLs() {
        // Test /ping removal
        XCTAssertEqual(
            URLTransformer.toServiceURL("http://radarr/ping"),
            "http://radarr/"
        )

        // Test /api/healthcheck removal
        XCTAssertEqual(
            URLTransformer.toServiceURL("http://192.168.1.183/api/healthcheck"),
            "http://192.168.1.183/"
        )

        // Test /health removal
        XCTAssertEqual(
            URLTransformer.toServiceURL("http://service.local/health"),
            "http://service.local/"
        )

        // Test /healthz removal (Kubernetes style)
        XCTAssertEqual(
            URLTransformer.toServiceURL("http://k8s-service/healthz"),
            "http://k8s-service/"
        )

        // Test /api/ping removal
        XCTAssertEqual(
            URLTransformer.toServiceURL("http://api.example.com/api/ping"),
            "http://api.example.com/"
        )
    }

    func testPreservesNonHealthCheckURLs() {
        // Test admin path preservation
        XCTAssertEqual(
            URLTransformer.toServiceURL("http://192.168.1.2/admin"),
            "http://192.168.1.2/admin"
        )

        // Test root URL preservation
        XCTAssertEqual(
            URLTransformer.toServiceURL("http://example.com/"),
            "http://example.com/"
        )

        // Test custom path preservation
        XCTAssertEqual(
            URLTransformer.toServiceURL("http://service.local/dashboard"),
            "http://service.local/dashboard"
        )

        // Test API path that's not health-related
        XCTAssertEqual(
            URLTransformer.toServiceURL("http://api.service.com/api/v1"),
            "http://api.service.com/api/v1"
        )
    }

    func testHandlesPortNumbers() {
        // Test with port and health check
        XCTAssertEqual(
            URLTransformer.toServiceURL("http://localhost:3000/ping"),
            "http://localhost:3000/"
        )

        // Test with port and no health check
        XCTAssertEqual(
            URLTransformer.toServiceURL("http://localhost:8080/admin"),
            "http://localhost:8080/admin"
        )
    }

    func testHandlesHTTPS() {
        XCTAssertEqual(
            URLTransformer.toServiceURL("https://secure.service.com/health"),
            "https://secure.service.com/"
        )
    }

    func testHandlesCaseInsensitivity() {
        XCTAssertEqual(
            URLTransformer.toServiceURL("http://service.local/PING"),
            "http://service.local/"
        )

        XCTAssertEqual(
            URLTransformer.toServiceURL("http://service.local/API/HEALTH"),
            "http://service.local/"
        )
    }

    func testHandlesInvalidURLs() {
        // Invalid URLs should return unchanged
        let invalidURL = "not-a-valid-url"
        XCTAssertEqual(
            URLTransformer.toServiceURL(invalidURL),
            invalidURL
        )
    }

    func testHandlesStatusPath() {
        XCTAssertEqual(
            URLTransformer.toServiceURL("http://service.local/status"),
            "http://service.local/"
        )
    }
}
