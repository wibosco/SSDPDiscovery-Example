//
//  SSDPServiceParserTests.swift
//  SSDP-ExampleTests
//
//  Created by William Boles on 14/06/2020.
//  Copyright © 2020 William Boles. All rights reserved.
//

import XCTest
@testable import SSDP_Example

class SSDPServiceParserTests: XCTestCase {
    
    var sut: SSDPServiceParser!
    
    var dateFactory: MockDateFactory!
    
    let cacheControlTimeInterval = TimeInterval(3600)
    lazy var cacheControl = {
        "max-age=\(Int(cacheControlTimeInterval))"
    }()
    let searchTarget = "ssdp:all"
    let uniqueServiceName = "uuid:0175c106-5400-10f8-802d-b0a7374360b7::urn:dial-multiscreen-org:service:dial:1"
    let server = "Roku UPnP/1.0 MiniUPnPd/1.4"
    let location = "http://192.168.1.104:8060/dial/dd.xml"
    
    // MARK: - Lifecycle
    
    override func setUp() {
        dateFactory = MockDateFactory()
        
        sut = SSDPServiceParser(dateFactory: dateFactory)
    }

    override func tearDown() {
        dateFactory = nil
        
        sut = nil
    }
    
    // MARK: - Tests
    
    // MARK: Parse

    func testParse_validResponse_emptyOtherHeaders() {
        let serviceString = "HTTP/1.1 200 OK\r\n" +
            "CACHE-CONTROL: \(cacheControl)\r\n" +
            "ST: \(searchTarget)\r\n" +
            "USN: \(uniqueServiceName)\r\n" +
            "EXT:\r\n" +
            "SERVER: \(server)\r\n" +
            "LOCATION: \(location)\r\n" +
            "\r\n"

        let serviceData = Data(serviceString.utf8)
        
        let service = sut.parse(serviceData)
        
        let cacheControlDate = dateFactory.currentDate().addingTimeInterval(cacheControlTimeInterval)
        let locationURL = URL(string: location)!
        
        XCTAssertNotNil(service)
        XCTAssertEqual(service?.cacheControl, cacheControlDate)
        XCTAssertEqual(service?.location, locationURL)
        XCTAssertEqual(service?.server, server)
        XCTAssertEqual(service?.searchTarget, searchTarget)
        XCTAssertEqual(service?.uniqueServiceName, uniqueServiceName)
        XCTAssertEqual(service?.otherHeaders, [:])
    }
    
    func testParse_validResponse_otherHeaders() {
        let serviceString = "HTTP/1.1 200 OK\r\n" +
            "CACHE-CONTROL: \(cacheControl)\r\n" +
            "ST: \(searchTarget)\r\n" +
            "USN: \(uniqueServiceName)\r\n" +
            "EXT:\r\n" +
            "SERVER: \(server)\r\n" +
            "LOCATION: \(location)\r\n" +
            "BOOTID.UPNP.ORG: 1\r\n" +
            "CONFIGID.UPNP.ORG: 1337\r\n" +
            "\r\n"

        let serviceData = Data(serviceString.utf8)
        
        let service = sut.parse(serviceData)
        
        let cacheControlDate = dateFactory.currentDate().addingTimeInterval(cacheControlTimeInterval)
        let locationURL = URL(string: location)!
        
        XCTAssertNotNil(service)
        XCTAssertEqual(service?.cacheControl, cacheControlDate)
        XCTAssertEqual(service?.location, locationURL)
        XCTAssertEqual(service?.server, server)
        XCTAssertEqual(service?.searchTarget, searchTarget)
        XCTAssertEqual(service?.uniqueServiceName, uniqueServiceName)
        XCTAssertEqual(service?.otherHeaders, ["BOOTID.UPNP.ORG" : "1", "CONFIGID.UPNP.ORG" : "1337"])
    }
    
    func testParse_invalidResponse_missingCacheControl() {
        let serviceString = "HTTP/1.1 200 OK\r\n" +
            "ST: \(searchTarget)\r\n" +
            "USN: \(uniqueServiceName)\r\n" +
            "EXT:\r\n" +
            "SERVER: \(server)\r\n" +
            "LOCATION: \(location)\r\n" +
            "\r\n"

        let serviceData = Data(serviceString.utf8)
        
        let service = sut.parse(serviceData)
        
        XCTAssertNil(service)
    }
    
    func testParse_invalidResponse_missingSearchTarget() {
        let serviceString = "HTTP/1.1 200 OK\r\n" +
            "CACHE-CONTROL: \(cacheControl)\r\n" +
            "USN: \(uniqueServiceName)\r\n" +
            "EXT:\r\n" +
            "SERVER: \(server)\r\n" +
            "LOCATION: \(location)\r\n" +
            "\r\n"

        let serviceData = Data(serviceString.utf8)
        
        let service = sut.parse(serviceData)
        
        XCTAssertNil(service)
    }
    
    func testParse_invalidResponse_missingUniqueServiceName() {
        let serviceString = "HTTP/1.1 200 OK\r\n" +
            "CACHE-CONTROL: \(cacheControl)\r\n" +
            "ST: \(searchTarget)\r\n" +
            "EXT:\r\n" +
            "SERVER: \(server)\r\n" +
            "LOCATION: \(location)\r\n" +
            "\r\n"

        let serviceData = Data(serviceString.utf8)
        
        let service = sut.parse(serviceData)
        
        XCTAssertNil(service)
    }
    
    func testParse_invalidResponse_missingServer() {
        let serviceString = "HTTP/1.1 200 OK\r\n" +
            "CACHE-CONTROL: \(cacheControl)\r\n" +
            "ST: \(searchTarget)\r\n" +
            "USN: \(uniqueServiceName)\r\n" +
            "EXT:\r\n" +
            "LOCATION: \(location)\r\n" +
            "\r\n"

        let serviceData = Data(serviceString.utf8)
        
        let service = sut.parse(serviceData)
        
        XCTAssertNil(service)
    }
    
    func testParse_invalidResponse_missingLocation() {
        let serviceString = "HTTP/1.1 200 OK\r\n" +
            "CACHE-CONTROL: \(cacheControl)\r\n" +
            "ST: \(searchTarget)\r\n" +
            "USN: \(uniqueServiceName)\r\n" +
            "EXT:\r\n" +
            "SERVER: \(server)\r\n" +
            "\r\n"

        let serviceData = Data(serviceString.utf8)
        
        let service = sut.parse(serviceData)
        
        XCTAssertNil(service)
    }
}
