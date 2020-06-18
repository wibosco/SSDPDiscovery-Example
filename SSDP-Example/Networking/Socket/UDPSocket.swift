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

private class SocketReader {
    
    private let socketReaderQueue = DispatchQueue(label: "com.williamboles.udpsocket.reader.queue",  attributes: .concurrent)
    private var isListening = true
    
    // MARK: - Listen
    
    func startListening(on socket: SocketProtocol, handler: @escaping ((Result<Data, Error>) -> Void)) {
        socketReaderQueue.async {
            do {
                repeat {
                    var data = Data()
                    try socket.readDatagram(into: &data) //blocking call
                    let result = Result<Data, Error>.success(data)
                    handler(result)
                } while self.isListening
            } catch {
                if self.isListening { // ignore any errors for non-active sockets
                    let result = Result<Data, Error>.failure(error)
                    handler(result)
                }
            }
        }
    }
    
    private func stopListening() {
        isListening = false
    }
}

private class SocketWriter {
    
    private let socketWriterQueue = DispatchQueue(label: "com.williamboles.udpsocket.writer.queue",  attributes: .concurrent)
    
    // MARK: - Write
    
    func write(message: String, on socket: SocketProtocol, to host: String, on port: UInt, errorHandler: @escaping ((Error) -> Void)) {
        socketWriterQueue.async {
            do {
                try socket.write(message, to: host, on: port)
            } catch {
                errorHandler(error)
            }
        }
    }
}

class UDPSocket: UDPSocketProtocol {
    private(set) var state: UDPSocketState = .ready
    
    weak var delegate: UDPSocketDelegate?
    
    private let socket: SocketProtocol
    private let writer = SocketWriter()
    private let reader = SocketReader()
    
    private let host: String
    private let port: UInt
    
    private let callbackQueue: OperationQueue
    
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
            os_log(.info, "Attempting to write to a closed socket, create a new socket instead")
            return
        }
        
        let shouldStartListening = state.isReady
        state = .active
        
        if shouldStartListening {
            reader.startListening(on: socket) { (result) in
                switch result {
                    case .success(let data):
                        self.reportResponseReceived(data)
                    case .failure(let error):
                        self.closeAndReportError(error)
                }
            }
        }
        
        writer.write(message: message, on: socket, to: host, on: port) { (error) in
            self.closeAndReportError(error)
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

