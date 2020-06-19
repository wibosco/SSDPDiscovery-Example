//
//  UDPSocket.swift
//  SSDP-Example
//
//  Created by William Boles on 12/06/2020.
//  Copyright © 2020 William Boles. All rights reserved.
//

import Foundation
import os

protocol UDPSocketControllerDelegate: class {
    func controller(_ controller: UDPSocketControllerProtocol, didReceiveResponse response: Data)
    func controller(_ controller: UDPSocketControllerProtocol, didEncounterError error: Error)
}

enum UDPSocketControllerState {
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

protocol UDPSocketControllerProtocol: class {
    var state: UDPSocketControllerState { get }
    var delegate: UDPSocketControllerDelegate? { get set }
    
    func write(message: String)
    func close()
}

class UDPSocketController: UDPSocketControllerProtocol {
    private(set) var state: UDPSocketControllerState = .ready
    
    weak var delegate: UDPSocketControllerDelegate?
    
    private let socket: UDPSocketProtocol
    
    private let host: String
    private let port: UInt
    
    private let callbackQueue: OperationQueue
    private let socketListeningQueue = DispatchQueue(label: "com.williamboles.udpsocket.listening.queue",  attributes: .concurrent)
    private let socketWriterQueue = DispatchQueue(label: "com.williamboles.udpsocket.writer.queue",  attributes: .concurrent)
    
    // MARK: - Init
    
    init?(host: String, port: UInt, socketFactory: SocketFactoryProtocol, callbackQueue: OperationQueue) {
        guard let socket = socketFactory.createUDPSocket(host: host, port: port) else {
             return nil
         }
        
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
            startListening(on: socketListeningQueue)
        }
        
        write(message: message, on: socketWriterQueue)
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
           self.delegate?.controller(self, didReceiveResponse: data)
        }
    }
    
    // MARK: - Close
    
    private func closeAndReportError(_ error: Error) {
        close()
        callbackQueue.addOperation {
            self.delegate?.controller(self, didEncounterError: error)
        }
    }
    
    func close() {
        state = .closed
        socket.close()
    }
}
