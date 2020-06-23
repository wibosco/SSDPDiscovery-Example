//
//  SocketFactory.swift
//  SSDP-Example
//
//  Created by William Boles on 12/06/2020.
//  Copyright © 2020 William Boles. All rights reserved.
//

import Foundation
import Socket

protocol SocketFactoryProtocol {
    func createUDPSocket() -> UDPSocketProtocol?
}

class SocketFactory: SocketFactoryProtocol {
    
    // MARK: - UDP
    
    func createUDPSocket() -> UDPSocketProtocol? {
        guard let socket = try? Socket.createUDPSocket() else {
            return nil
        }
        
        return socket
    }
}
