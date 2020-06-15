//
//  SSDPSearchSessionConfigurationTests.swift
//  SSDP-ExampleTests
//
//  Created by William Boles on 15/06/2020.
//  Copyright © 2020 William Boles. All rights reserved.
//

import XCTest
@testable import SSDP_Example

class SSDPSearchSessionConfigurationTests: XCTestCase {
    
    // MARK: - Lifecycle
    
    override func setUp() {
    }

    override func tearDown() {
    }
    
    // MARK: - Tests

    func testCreateMulticastConfiguration() {
        let searchTarget = "test_search_target"
        let maximumWaitResponseTime = TimeInterval(3)
        let maximumBroadcastsBeforeClosing = UInt(3)
        
        let config = SSDPSearchSessionConfiguration.createMulticastConfiguration(forSearchTarget: searchTarget, maximumWaitResponseTime: maximumWaitResponseTime, maximumBroadcastsBeforeClosing: maximumBroadcastsBeforeClosing)
        
        XCTAssertEqual(config.searchTarget, searchTarget)
        XCTAssertEqual(config.host, "239.255.255.250")
        XCTAssertEqual(config.port, 1900)
        XCTAssertEqual(config.maximumWaitResponseTime, maximumWaitResponseTime)
        XCTAssertEqual(config.maximumBroadcastsBeforeClosing, maximumBroadcastsBeforeClosing)
    }
}
