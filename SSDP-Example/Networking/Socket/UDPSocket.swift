//
//  UDPSocket.swift
//  SSDP-Example
//
//  Created by William Boles on 12/06/2020.
//  Copyright © 2020 William Boles. All rights reserved.
//

import Foundation
import os

protocol UDPSocketDelegate: class {
    func session(_ socket: UDPSocketProtocol, didReceiveResponse response: Data)
    func session(_ socket: UDPSocketProtocol, didEncounterError error: Error)
}

enum UDPSocketState {
    case ready
    case active
    case closed
    
    var isReady: Bool {
        self == .ready
    }
    
    var isActive: Bool {
        self == .active
    }
    
    var isClosed: Bool {
        self == .closed
    }
}

protocol UDPSocketProtocol: class {
    var state: UDPSocketState { get }
    var delegate: UDPSocketDelegate? { get set }
    
    func write(message: String)
    func close()
}

enum UDPSocketError: Error, Equatable {
    case addressCreationFailure
}

class UDPSocket: UDPSocketProtocol {
    private(set) var state: UDPSocketState = .ready
    
    weak var delegate: UDPSocketDelegate?
    
    private let socket: SocketProtocol
    
    private let host: String
    private let port: UInt
    
    private var beenClosed = false
    
    private let socketLockQueue = DispatchQueue(label: "com.williamboles.udpsocket.lock.queue",  attributes: .concurrent)
    
    // MARK: - Init
    
    init(host: String, port: UInt, socket: SocketProtocol) {
        self.socket = socket
        self.host = host
        self.port = port
    }
    
    // MARK: - Write
    
    func write(message: String) {
        guard !state.isClosed else {
            os_log(.info, "Attempting to write to a closed socket")
            return
        }
        
        socketLockQueue.async {
            do {
                let shouldStartListening = self.state.isReady
                self.state = .active
                try self.socket.write(message, to: self.host, on: self.port)
                if shouldStartListening {
                    repeat {
                        var data = Data()
                        try self.socket.readDatagram(into: &data) //blocking call
                        DispatchQueue.main.async {
                            self.delegate?.session(self, didReceiveResponse: data)
                        }
                    } while self.state.isActive
                }
            } catch {
                if self.state.isActive { // ignore any errors for non-active sockets
                    DispatchQueue.main.async {
                        self.delegate?.session(self, didEncounterError: error)
                    }
                }
                self.close()
            }
        }
    }
    
    // MARK: - Close
    
    func close() {
        state = .closed
        socket.close()
    }
}

