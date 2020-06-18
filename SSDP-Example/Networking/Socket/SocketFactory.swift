//
//  SocketFactory.swift
//  SSDP-Example
//
//  Created by William Boles on 12/06/2020.
//  Copyright © 2020 William Boles. All rights reserved.
//

import Foundation
import BlueSocket

enum SocketError: Error, Equatable {
    case addressCreationFailure
}

protocol Socket {
    func write(_ string: String, to host: String, on port: UInt) throws
    func readDatagram(into data: inout Data) throws
    func close()
}

extension BlueSocket.Socket: Socket {
    func write(_ string: String, to host: String, on port: UInt) throws {
        guard let address = BlueSocket.Socket.createAddress(for: host, on: Int32(port)) else {
            throw(SocketError.addressCreationFailure)
        }
        try write(from: string, to: address)
    }
    
    func readDatagram(into data: inout Data) throws {
        let (_,_) = try readDatagram(into: &data)
    }
}

extension Socket {
    static func createUDPSocket() -> Socket? {
        guard let socket = try? BlueSocket.Socket.create(type: .datagram, proto: .udp) else {
            return nil
        }
        
        return socket
    }
}

protocol SocketFactoryProtocol {
    func createUDPSocket(host: String, port: UInt) -> UDPSocketProtocol?
}

class SocketFactory: SocketFactoryProtocol {
    
    // MARK: - UDP
    
    func createUDPSocket(host: String, port: UInt) -> UDPSocketProtocol? {
        guard let socket = try? BlueSocket.Socket.createUDPSocket() else {
            return nil
        }
        
        return UDPSocket(host: host, port: port, socket: socket)
    }
}
