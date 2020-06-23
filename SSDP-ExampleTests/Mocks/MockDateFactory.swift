//
//  MockDateFactory.swift
//  SSDP-ExampleTests
//
//  Created by William Boles on 15/06/2020.
//  Copyright © 2020 William Boles. All rights reserved.
//

import Foundation
@testable import SSDP_Example

class MockDateFactory: DateFactoryProtocol {
    var currentDateClosure: (() -> Void)?
    
    var currentDateToBeReturned: Date = Date.distantPast
    
    func currentDate() -> Date {
        return currentDateToBeReturned
    }
}
