//
//  SocketFactory.swift
//  SSDP-Example
//
//  Created by William Boles on 12/06/2020.
//  Copyright © 2020 William Boles. All rights reserved.
//

import Foundation
import Socket

enum SocketError: Error, Equatable {
    case addressCreationFailure
}

protocol SocketProtocol {
    func write(_ string: String, to host: String, on port: UInt) throws
    func readDatagram(into data: inout Data) throws
    func close()
}

extension Socket: SocketProtocol {    
    func write(_ string: String, to host: String, on port: UInt) throws {
        guard let address = Socket.createAddress(for: host, on: Int32(port)) else {
            throw(SocketError.addressCreationFailure)
        }
        try write(from: string, to: address)
    }
    
    func readDatagram(into data: inout Data) throws {
        let (_,_) = try readDatagram(into: &data)
    }
}

protocol SocketFactoryProtocol {
    func createUDPSocket(host: String, port: UInt) -> UDPSocketProtocol?
}

class SocketFactory: SocketFactoryProtocol {
    
    // MARK: - UDP
    
    func createUDPSocket(host: String, port: UInt) -> UDPSocketProtocol? {
        guard let socket = try? Socket.create(type: .datagram, proto: .udp) else {
            return nil
        }
        
        return UDPSocket(host: host, port: port, socket: socket)
    }
}
