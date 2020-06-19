//
//  UDPSocket.swift
//  SSDP-Example
//
//  Created by William Boles on 18/06/2020.
//  Copyright © 2020 William Boles. All rights reserved.
//

import Foundation
import Socket

enum UDPSocketError: Error, Equatable {
    case addressCreationFailure
}

protocol UDPSocketProtocol {
    func write(_ string: String, to host: String, on port: UInt) throws
    func readDatagram(into data: inout Data) throws
    func close()
}

extension Socket: UDPSocketProtocol {
    func write(_ string: String, to host: String, on port: UInt) throws {
        guard let address = Socket.createAddress(for: host, on: Int32(port)) else {
            throw(UDPSocketError.addressCreationFailure)
        }
        try write(from: string, to: address)
    }
    
    func readDatagram(into data: inout Data) throws {
        let (_,_) = try readDatagram(into: &data)
    }
}

extension Socket {
    static func createUDPSocket() throws -> UDPSocketProtocol {
        return try Socket.create(type: .datagram, proto: .udp)
    }
}
