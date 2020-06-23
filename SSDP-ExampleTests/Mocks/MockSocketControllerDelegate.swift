//
//  MockUDPSocketDelegate.swift
//  SSDP-ExampleTests
//
//  Created by William Boles on 12/06/2020.
//  Copyright © 2020 William Boles. All rights reserved.
//

import Foundation
@testable import SSDP_Example

class MockUDPSocketControllerDelegate: UDPSocketControllerDelegate {
    var didReceiveResponseClosure: ((UDPSocketControllerProtocol, Data) -> Void)?
    var didEncounterErrorClosure: ((UDPSocketControllerProtocol, Error) -> Void)?

    func controller(_ controller: UDPSocketControllerProtocol, didReceiveResponse response: Data) {
        didReceiveResponseClosure?(controller, response)
    }
    
    func controller(_ controller: UDPSocketControllerProtocol, didEncounterError error: Error) {
        didEncounterErrorClosure?(controller, error)
    }
}
