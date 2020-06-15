//
//  MockUDPSocket.swift
//  SSDP-ExampleTests
//
//  Created by William Boles on 12/06/2020.
//  Copyright © 2020 William Boles. All rights reserved.
//

import Foundation
@testable import SSDP_Example

class MockUDPSocket: UDPSocketProtocol {
    var state: UDPSocketState = .ready
    
    var writeClosure: ((String) -> Void)?
    var closeClosure: (() -> Void)?
    
    weak var delegate: UDPSocketDelegate? = nil
    
    func write(message: String) {
        state = .active
        
        writeClosure?(message)
    }
    
    func close() {
        state = .closed
        
        closeClosure?()
    }
}
