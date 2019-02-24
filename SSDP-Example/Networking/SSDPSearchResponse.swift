//
//  SSDPSearchResponse.swift
//  SSDP-Example
//
//  Created by William Boles on 17/02/2019.
//  Copyright © 2019 William Boles. All rights reserved.
//

import Foundation
import os

private enum SSDPSearchResponseKey: String {
    case cacheControl = "CACHE-CONTROL"
    case date = "DATE"
    case location = "LOCATION"
    case server = "SERVER"
    case searchTarget = "ST"
    case usn = "USN"
}

struct SSDPSearchResponse: Equatable {
    let cacheControl: Date
    let date: Date?
    let location: URL
    let server: String
    let searchTarget: String
    let usn: String
    let otherHeaders: [String: String]
    
    private static let dateFormatter = DateFormatter()
    
    // MARK: - Init
    
    init?(data: Data) {
        guard let responseString = String(data: data, encoding: .utf8) else {
            return nil
        }
        
        var responseDict = SSDPSearchResponse.parseResponseIntoDictionary(responseString)

        guard let cacheControl = SSDPSearchResponse.parseCacheControl(responseDict[SSDPSearchResponseKey.cacheControl.rawValue]),
            let location = SSDPSearchResponse.parseLocation(responseDict[SSDPSearchResponseKey.location.rawValue]),
            let server = responseDict[SSDPSearchResponseKey.server.rawValue],
            let searchTarget = responseDict[SSDPSearchResponseKey.searchTarget.rawValue],
            let usn = responseDict[SSDPSearchResponseKey.usn.rawValue] else {
                return nil
        }
        
        self.cacheControl = cacheControl
        responseDict.removeValue(forKey: SSDPSearchResponseKey.cacheControl.rawValue)
        
        self.location = location
        responseDict.removeValue(forKey: SSDPSearchResponseKey.location.rawValue)
        
        self.server = server
        responseDict.removeValue(forKey: SSDPSearchResponseKey.server.rawValue)
        
        self.searchTarget = searchTarget
        responseDict.removeValue(forKey: SSDPSearchResponseKey.searchTarget.rawValue)
        
        self.usn = usn
        responseDict.removeValue(forKey: SSDPSearchResponseKey.usn.rawValue)
        
        self.date = SSDPSearchResponse.parseDate(responseDict[SSDPSearchResponseKey.date.rawValue])
        responseDict.removeValue(forKey: SSDPSearchResponseKey.date.rawValue)
        
        self.otherHeaders = responseDict
    }
    
    // MARK: - Parse
    
    private static func parseResponseIntoDictionary(_ response: String) -> [String: String] {
        var elements = [String: String]()
        for element in response.split(separator: "\r\n") {
            let keyValuePair = element.split(separator: ":", maxSplits: 1)
            guard keyValuePair.count == 2 else {
                continue
            }
            
            let key = String(keyValuePair[0]).uppercased().trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
            let value = String(keyValuePair[1]).trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
            
            elements[key] = value
        }
        
        return elements
    }
    
    private static func parseCacheControl(_ value: String?) -> Date? {
        guard let cacheControlRange = value?.range(of: "[0-9]+$", options: .regularExpression),
            let cacheControlString = value?[cacheControlRange],
            let cacheControlTimeInterval = TimeInterval(cacheControlString) else {
                return nil
        }
        
        return Date(timeIntervalSinceNow: cacheControlTimeInterval)
    }
    
    private static func parseDate(_ value: String?) -> Date? {
        guard let dateString = value,
            let date = dateFormatter.date(from: dateString) else {
                return nil
        }
        
        return date
    }
    
    private static func parseLocation(_ value: String?) -> URL? {
        guard let urlString = value,
            let url = URL(string: urlString) else {
                return nil
        }
        
        return url
    }
    
    // MARK: - Equatable
    
    static func == (lhs: SSDPSearchResponse, rhs: SSDPSearchResponse) -> Bool {
        return lhs.location == rhs.location &&
            lhs.server == rhs.server &&
            lhs.searchTarget == rhs.searchTarget &&
            lhs.usn == rhs.usn &&
            lhs.otherHeaders == rhs.otherHeaders
    }
}
