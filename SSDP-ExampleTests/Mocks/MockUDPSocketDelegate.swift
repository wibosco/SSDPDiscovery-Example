//
//  MockUDPSocketDelegate.swift
//  SSDP-ExampleTests
//
//  Created by William Boles on 12/06/2020.
//  Copyright © 2020 William Boles. All rights reserved.
//

import Foundation
@testable import SSDP_Example

class MockUDPSocketDelegate: UDPSocketDelegate {
    var didReceiveResponseClosure: ((UDPSocketProtocol, Data) -> Void)?
    var didEncounterErroreClosure: ((UDPSocketProtocol, Error) -> Void)?

    func session(_ socket: UDPSocketProtocol, didReceiveResponse response: Data) {
        didReceiveResponseClosure?(socket, response)
    }
    
    func session(_ socket: UDPSocketProtocol, didEncounterError error: Error) {
        didEncounterErroreClosure?(socket, error)
    }
}
