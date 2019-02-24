//
//  Result.swift
//  SSDP-Example
//
//  Created by William Boles on 17/02/2019.
//  Copyright © 2019 William Boles. All rights reserved.
//

import Foundation

enum Result<Value, Error: Swift.Error> {
    case success(Value)
    case failure(Error)
}
