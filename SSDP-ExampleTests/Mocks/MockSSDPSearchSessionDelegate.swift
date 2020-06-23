//
//  MockSSDPSearchSessionDelegate.swift
//  SSDP-ExampleTests
//
//  Created by William Boles on 12/06/2020.
//  Copyright © 2020 William Boles. All rights reserved.
//

import Foundation
@testable import SSDP_Example

class MockSSDPSearchSessionDelegate: SSDPSearchSessionDelegate {
    var didFindServiceClosure: ((SSDPSearchSession, SSDPService) -> Void)?
    var didEncounterErrorClosure:((SSDPSearchSession, SSDPSearchSessionError) -> Void)?
    var didStopSearchClosure: ((SSDPSearchSession, [SSDPService]) -> Void)?
    
    func searchSession(_ searchSession: SSDPSearchSession, didFindService service: SSDPService) {
        didFindServiceClosure?(searchSession, service)
    }
    
    func searchSession(_ searchSession: SSDPSearchSession, didEncounterError error: SSDPSearchSessionError) {
        didEncounterErrorClosure?(searchSession, error)
    }
    
    func searchSessionDidStopSearch(_ searchSession: SSDPSearchSession, foundServices: [SSDPService]) {
        didStopSearchClosure?(searchSession, foundServices)
    }
}
