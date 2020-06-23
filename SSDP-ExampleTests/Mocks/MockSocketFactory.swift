//
//  MockSocketFactory.swift
//  SSDP-ExampleTests
//
//  Created by William Boles on 18/06/2020.
//  Copyright © 2020 William Boles. All rights reserved.
//

import Foundation
@testable import SSDP_Example

class MockSocketFactory: SocketFactoryProtocol {
    var createUDPSocketClosure: (() -> Void)?
    
    var udpSocketToBeReturned: UDPSocketProtocol?
    
    func createUDPSocket() -> UDPSocketProtocol? {
        createUDPSocketClosure?()
        
        return udpSocketToBeReturned
    }
}
