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
    var writeClosure: ((String, String, UInt) -> Void)?
    var readDatagramClosure: ((Data) -> Void)?
    var closureClosure: (() -> Void)?
    
    func write(_ string: String, to host: String, on port: UInt) throws {
        writeClosure?(string, host, port)
    }
    
    func readDatagram(into data: inout Data) throws {
        readDatagramClosure?(data)
    }
    
    func close() {
        closureClosure?()
    }
}
