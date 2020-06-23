//
//  MockSocketFactory.swift
//  SSDP-ExampleTests
//
//  Created by William Boles on 12/06/2020.
//  Copyright © 2020 William Boles. All rights reserved.
//

import Foundation
@testable import SSDP_Example

class MockSocketControllerFactory: SocketControllerFactoryProtocol {
    var createUDPSocketControllerClosure: ((String, UInt, SocketFactoryProtocol, OperationQueue) -> Void)?
    
    var udpSocketControllerToBeReturned: UDPSocketControllerProtocol?
    
    func createUDPSocketController(host: String, port: UInt, socketFactory: SocketFactoryProtocol, callbackQueue: OperationQueue) -> UDPSocketControllerProtocol? {
        createUDPSocketControllerClosure?(host, port, socketFactory, callbackQueue)
        
        return udpSocketControllerToBeReturned
    }
}
