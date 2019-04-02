//
//  SSDPSearchSessionConfiguration.swift
//  SSDP-Example
//
//  Created by William Boles on 17/02/2019.
//  Copyright © 2019 William Boles. All rights reserved.
//

import Foundation

struct SSDPSearchSessionConfiguration {
    let searchTarget: String
    let host: String
    let port: UInt
    let maximumWaitResponseTime: TimeInterval
    let maximumBroadcastsBeforeClosing: UInt
    
    // MARK: - Init
    
    init(searchTarget: String, host: String, port: UInt, maximumWaitResponseTime: TimeInterval, maximumBroadcastsBeforeClosing: UInt) {
        assert(maximumWaitResponseTime >= 1 && maximumWaitResponseTime <= 5, "maximumWaitResponseTime should be between 1 and 5 (inclusive)")
        assert(maximumBroadcastsBeforeClosing >= 1, "maximumBroadcastsBeforeClosing should be greater than or equal to 1")
        
        self.searchTarget = searchTarget
        self.host = host
        self.port = port
        self.maximumWaitResponseTime = maximumWaitResponseTime
        self.maximumBroadcastsBeforeClosing = maximumBroadcastsBeforeClosing
    }
}

extension SSDPSearchSessionConfiguration {
    
    static func createMulticastConfiguration(forSearchTarget searchTarget: String, maximumWaitResponseTime: TimeInterval = 3, maximumBroadcastsBeforeClosing: UInt = 3) -> SSDPSearchSessionConfiguration {
        let configuration = SSDPSearchSessionConfiguration(searchTarget: searchTarget, host: "239.255.255.250", port: 1900, maximumWaitResponseTime: maximumWaitResponseTime, maximumBroadcastsBeforeClosing: maximumBroadcastsBeforeClosing)
        
        return configuration
    }
}
