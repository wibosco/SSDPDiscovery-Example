//
//  UDPSocket.swift
//  SSDP-Example
//
//  Created by William Boles on 12/06/2020.
//  Copyright © 2020 William Boles. All rights reserved.
//

import Foundation
import Socket

protocol UDPSocketDelegate: class {
    func session(_ socket: UDPSocketProtocol, didReceiveResponse response: Data)
    func session(_ socket: UDPSocketProtocol, didEncounterError error: Error)
}

protocol UDPSocketProtocol: class {
    var isOpen: Bool { get }
    var delegate: UDPSocketDelegate? { get set }
    
    func write(message: String)
    func close()
}

enum UDPSocketError: Error, Equatable {
    case addressCreationFailure
}

class UDPSocket: UDPSocketProtocol {
    private var _isOpen: Bool = false
    var isOpen: Bool {
        get {
            return serialQueue.sync {
                return _isOpen
            }
        }
        
        set {
            serialQueue.sync {
                _isOpen = newValue
            }
        }
    }
    weak var delegate: UDPSocketDelegate?
    
    private let socket: SocketProtocol
    
    private let host: String
    private let port: UInt
    
    private let socketReadWriteQueue = DispatchQueue(label: "com.williamboles.udpsocket.readwrite.queue",  attributes: .concurrent)
    private let serialQueue = DispatchQueue(label: "com.williamboles.udpsocket.serial.queue")
    private var firstWrite = true
    
    // MARK: - Init
    
    init(host: String, port: UInt, socket: SocketProtocol) {        
        self.socket = socket
        self.host = host
        self.port = port
    }
    
    // MARK: - Write
    
    func write(message: String) {
        if firstWrite {
            scheduleReadOnQueue()
        }
        
        scheduleWriteOnQueue(message: message)
        firstWrite = false
    }
    
    private func scheduleWriteOnQueue(message: String) {
        socketReadWriteQueue.async {
            self.write(message: message, to: self.host, on: self.port)
        }
    }
    
    private func write(message: String, to host: String, on port: UInt) {
        do {
            try socket.write(message, to: host, on: port)
            isOpen = true
        } catch {
            close()
            DispatchQueue.main.async {
                self.delegate?.session(self, didEncounterError: error)
            }
        }
    }
    
    // MARK: - Read
    
    private func scheduleReadOnQueue() {
        socketReadWriteQueue.async {
            self.readResponse()
        }
    }
    
    private func readResponse() {
        var data = Data()
        
        do {
            try socket.readDatagram(into: &data) //blocking call
            DispatchQueue.main.async {
                self.delegate?.session(self, didReceiveResponse: data)
            }
            
            if isOpen {
                readResponse()
            }
        } catch {
            if isOpen { // sockets when closed will throw an error - this is expected so we don't pass it back
                close()
                DispatchQueue.main.async {
                    self.delegate?.session(self, didEncounterError: error)
                }
            }
        }
    }
    
    // MARK: - Close
    
    func close() {
        isOpen = false
        socket.close()
    }
}

