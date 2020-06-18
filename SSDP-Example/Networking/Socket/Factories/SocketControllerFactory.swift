//
//  SocketControllerFactory.swift
//  SSDP-Example
//
//  Created by William Boles on 18/06/2020.
//  Copyright © 2020 William Boles. All rights reserved.
//

import Foundation

protocol SocketControllerFactoryProtocol {
    func createUDPSocketController(host: String, port: UInt, callbackQueue: OperationQueue) -> UDPSocketControllerProtocol?
}

class SocketControllerFactory: SocketControllerFactoryProtocol {
    
    // MARK: - UDP
    
    func createUDPSocketController(host: String, port: UInt, callbackQueue: OperationQueue) -> UDPSocketControllerProtocol? {
        UDPSocketController(host: host, port: port, callbackQueue: callbackQueue)
    }
}
