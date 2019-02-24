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
    let host: String = "239.255.255.250"
    let port: UInt = 1900
    let maximumWaitResponseTime: TimeInterval
    let searchTimeout: TimeInterval
    let possibleSearchBroadcasts: UInt
}
