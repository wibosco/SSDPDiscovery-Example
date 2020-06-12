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
    var writeClosure: ((String) -> Void)?
    var closeClosure: (() -> Void)?
    
    var isOpen: Bool = false
    weak var delegate: UDPSocketDelegate? = nil
    
    func write(message: String) {
        isOpen = true
        
        writeClosure?(message)
    }
    
    func close() {
        isOpen = false
        
        closeClosure?()
    }
}
