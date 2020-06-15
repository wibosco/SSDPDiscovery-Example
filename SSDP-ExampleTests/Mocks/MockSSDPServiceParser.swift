//
//  MockSSDPServiceParser.swift
//  SSDP-ExampleTests
//
//  Created by William Boles on 14/06/2020.
//  Copyright © 2020 William Boles. All rights reserved.
//

import Foundation
@testable import SSDP_Example

class MockSSDPServiceParser: SSDPServiceParserProtocol {
    var parseClosure: ((Data) -> Void)?
    
    var serviceToBeReturned: SSDPService?
    
    func parse(_ data: Data) -> SSDPService? {
        parseClosure?(data)
        
        return serviceToBeReturned
    }
}
