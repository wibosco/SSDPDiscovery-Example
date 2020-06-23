//
//  UDPSocket.swift
//  SSDP-Example
//
//  Created by William Boles on 18/06/2020.
//  Copyright © 2020 William Boles. All rights reserved.
//

import Foundation
import Socket

enum UDPSocketError: Error {
    case addressCreationFailure
    case writeError(underlayingError: Error)
    case readError(underlayingError: Error)
}

protocol UDPSocketProtocol {
    func write(_ string: String, to host: String, on port: UInt) throws
    func readDatagram(into data: inout Data) throws
    func close()
}

extension UDPSocketProtocol {
    static func createUDPSocket() throws -> UDPSocketProtocol {
        return try Socket.create(type: .datagram, proto: .udp)
    }
}

extension Socket: UDPSocketProtocol {
    func write(_ string: String, to host: String, on port: UInt) throws {
        guard let signature = self.signature, signature.socketType == .datagram, signature.proto == .udp else {
            fatalError("Only UDP sockets can use this method")
        }
        
        guard let address = Socket.createAddress(for: host, on: Int32(port)) else {
            throw(UDPSocketError.addressCreationFailure)
        }
        do {
            try write(from: string, to: address)
        } catch {
            throw(UDPSocketError.writeError(underlayingError: error))
        }
    }
    
    func readDatagram(into data: inout Data) throws {
        guard let signature = self.signature, signature.socketType == .datagram, signature.proto == .udp else {
            fatalError("Only UDP sockets can use this method")
        }
        
        do {
            let (_,_) = try readDatagram(into: &data)
        } catch {
            throw(UDPSocketError.readError(underlayingError: error))
        }
    }
}

//extension Socket {
//    static func createUDPSocket() throws -> UDPSocketProtocol {
//        return try Socket.create(type: .datagram, proto: .udp)
//    }
//}
