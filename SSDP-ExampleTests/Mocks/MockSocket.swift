//
//  MockSocket.swift
//  SSDP-ExampleTests
//
//  Created by William Boles on 12/06/2020.
//  Copyright © 2020 William Boles. All rights reserved.
//

import Foundation
@testable import SSDP_Example

class MockSocket: SocketProtocol {
    var isActive: Bool = false
    
    var writeClosure: ((String, String, UInt) -> Void)?
    var readDatagramClosure: ((Data) -> Void)?
    var closureClosure: (() -> Void)?
    
    var throwWriteException = false
    var throwReadException = false
    
    var releaseReadQueue = false
    
    private let blockingQueue = DispatchQueue(label: "blockingQueue")
    
    func write(_ string: String, to host: String, on port: UInt) throws {
        writeClosure?(string, host, port)
        
        if throwWriteException {
            throw TestError.test
        }
    }
    
    func readDatagram(into data: inout Data) throws {
        readDatagramClosure?(data)
        
        if throwReadException {
            throw TestError.test
        }
        
        blockingQueue.sync { [weak self] in
            while !(self?.releaseReadQueue ?? true) {
                sleep(1)
            }
            self?.releaseReadQueue = false
        }
    }
    
    func close() {
        closureClosure?()
    }
}
