//
//  SSDPSearchResponse.swift
//  SSDP-Example
//
//  Created by William Boles on 17/02/2019.
//  Copyright © 2019 William Boles. All rights reserved.
//

import Foundation

struct SSDPService: Equatable {
    let cacheControl: Date
    let location: URL
    let server: String
    let searchTarget: String
    let uniqueServiceName: String
    let otherHeaders: [String: String]
    
    // MARK: - Equatable
    
    static func == (lhs: SSDPService, rhs: SSDPService) -> Bool {
        return lhs.location == rhs.location &&
            lhs.server == rhs.server &&
            lhs.searchTarget == rhs.searchTarget &&
            lhs.uniqueServiceName == rhs.uniqueServiceName
    }
}
