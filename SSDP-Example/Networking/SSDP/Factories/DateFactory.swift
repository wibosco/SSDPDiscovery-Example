//
//  DateFactory.swift
//  SSDP-Example
//
//  Created by William Boles on 15/06/2020.
//  Copyright © 2020 William Boles. All rights reserved.
//

import Foundation

protocol DateFactoryProtocol {
    func currentDate() -> Date
}

class DateFactory: DateFactoryProtocol {
    
    // MARK: - Current
    
    func currentDate() -> Date {
        return Date()
    }
}
