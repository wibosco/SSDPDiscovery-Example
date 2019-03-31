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
    
    init(searchTarget: String = "ssdp:all", host: String = "239.255.255.250", port: UInt = 1900, maximumWaitResponseTime: TimeInterval = 3, maximumBroadcastsBeforeClosing: UInt = 3) {
        assert(maximumWaitResponseTime >= 1 && maximumWaitResponseTime <= 5, "maximumWaitResponseTime should be between 1 and 5")
        assert(maximumBroadcastsBeforeClosing >= 1, "maximumBroadcastsBeforeClosing should be greater than 1")
        
        self.searchTarget = searchTarget
        self.host = host
        self.port = port
        self.maximumWaitResponseTime = maximumWaitResponseTime
        self.maximumBroadcastsBeforeClosing = maximumBroadcastsBeforeClosing
    }
}
