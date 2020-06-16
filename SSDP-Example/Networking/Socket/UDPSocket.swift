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
    
    private let callbackQueue: OperationQueue
    private let socketLockQueue = DispatchQueue(label: "com.williamboles.udpsocket.lock.queue",  attributes: .concurrent)
    
    // MARK: - Init
    
    init(host: String, port: UInt, socket: SocketProtocol, callbackQueue: OperationQueue = .main) {
        self.host = host
        self.port = port
        self.socket = socket
        self.callbackQueue = callbackQueue
    }
    
    // MARK: - Write
    
    func write(message: String) {
        guard !state.isClosed else {
            os_log(.info, "Attempting to write to a closed socket")
            return
        }
        
        let shouldStartListening = state.isReady
        state = .active
        
        if shouldStartListening {
            startListening(on: socketLockQueue)
        }
        
        write(message: message, on: socketLockQueue)
    }
    
    private func write(message: String, on queue: DispatchQueue) {
        queue.async {
            do {
                try self.socket.write(message, to: self.host, on: self.port)
            } catch {
                self.closeAndReportError(error)
            }
        }
    }
    
    // MARK: - Listen
    
    private func startListening(on queue: DispatchQueue) {
        queue.async {
            do {
                repeat {
                    var data = Data()
                    try self.socket.readDatagram(into: &data) //blocking call
                    self.reportResponseReceived(data)
                } while self.state.isActive
            } catch {
                if self.state.isActive { // ignore any errors for non-active sockets
                    self.closeAndReportError(error)
                }
            }
        }
    }
    
    private func reportResponseReceived(_ data: Data) {
        callbackQueue.addOperation {
           self.delegate?.session(self, didReceiveResponse: data)
        }
    }
    
    // MARK: - Close
    
    private func closeAndReportError(_ error: Error) {
        close()
        callbackQueue.addOperation {
            self.delegate?.session(self, didEncounterError: error)
        }
    }
    
    func close() {
        state = .closed
        socket.close()
    }
}

