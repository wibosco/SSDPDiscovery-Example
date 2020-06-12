//
//  SSDPSearchSessionTests.swift
//  SSDP-ExampleTests
//
//  Created by William Boles on 12/06/2020.
//  Copyright © 2020 William Boles. All rights reserved.
//

import XCTest
@testable import SSDP_Example

class SSDPSearchSessionTests: XCTestCase {
    
    var sut: SSDPSearchSession!
    
    let searchTarget = "search_target"
    let maximumWaitResponseTime = TimeInterval(2)
    let maximumBroadcastsBeforeClosing = UInt(5)
    
    var configuration: SSDPSearchSessionConfiguration!
    var socketFactory: MockSocketFactory!
    var udpSocket: MockUDPSocket!
    var delegate: MockSSDPSearchSessionDelegate!
    
    // MARK: - Lifecycle
    
    override func setUp() {
        configuration = SSDPSearchSessionConfiguration.createMulticastConfiguration(forSearchTarget: searchTarget, maximumWaitResponseTime: maximumWaitResponseTime, maximumBroadcastsBeforeClosing: maximumBroadcastsBeforeClosing)
        udpSocket = MockUDPSocket()
        socketFactory = MockSocketFactory()
        socketFactory.udpSocketToBeReturned = udpSocket
        delegate = MockSSDPSearchSessionDelegate()
        
        sut = SSDPSearchSession(configuration: configuration, socketFactory: socketFactory)
    }

    override func tearDown() {
        configuration = nil
        socketFactory = nil
        udpSocket = nil
        delegate = nil
        
        sut = nil
    }
    
    // MARK: - Tests
    
    // MARK: Init
    
    func testInit_failed() {
        socketFactory.udpSocketToBeReturned = nil

        sut = SSDPSearchSession(configuration: configuration, socketFactory: socketFactory)

        XCTAssertNil(sut)
    }

    func testInit_socketDelegateSet() {
        XCTAssertTrue(sut === udpSocket.delegate)
    }
    
    // MARK: StartSearch
    
    func testStartSearch_sendMSearchMessage() {
        let expectedMessage = "M-SEARCH * HTTP/1.1\r\n" +
            "HOST: 239.255.255.250:1900\r\n" +
            "MAN: \"ssdp:discover\"\r\n" +
            "ST: \(searchTarget)\r\n" +
        "MX: \(Int(maximumWaitResponseTime))\r\n\r\n"

        let writeToSocketExpectation = expectation(description: "write m-search to socket expectation")
        udpSocket.writeClosure = { message in
            XCTAssertEqual(message, expectedMessage)
            
            writeToSocketExpectation.fulfill()
        }
        
        sut.startSearch()

        waitForExpectations(timeout: 3, handler: nil)
    }
    
    func testStartSearch_zeroMaximumBroadcasts_triggerStopSearchDelegate_doesNotWriteToSocket() {
        configuration = SSDPSearchSessionConfiguration.createMulticastConfiguration(forSearchTarget: "searchTarget", maximumWaitResponseTime: maximumWaitResponseTime, maximumBroadcastsBeforeClosing: 0)

        sut = SSDPSearchSession(configuration: configuration, socketFactory: socketFactory)
        sut.delegate = delegate

        let didStopSearchingExpectation = expectation(description: "did trigger stop search delegate expectation")
        delegate.didStopSearchClosure = { (_, services) in
            XCTAssertEqual(services.count, 0)

            didStopSearchingExpectation.fulfill()
        }

        let socketWriteExpectation = expectation(description: "should not write m-search message to socket expectation")
        socketWriteExpectation.isInverted = true
        udpSocket.writeClosure = { _ in
            socketWriteExpectation.fulfill()
        }

        sut.startSearch()

        waitForExpectations(timeout: 3, handler: nil)
    }
    
    func testStartSearch_numberOfMSearchMessagesSentMatchConfig_timeOut_triggerDidStopSearcDelegate() {
        configuration = SSDPSearchSessionConfiguration.createMulticastConfiguration(forSearchTarget: searchTarget, maximumWaitResponseTime: 1, maximumBroadcastsBeforeClosing: 2)

        let didStopSearchExpectation = expectation(description: "did trigger stop search delegate expectation")
        delegate.didStopSearchClosure = { (_, _) in
            didStopSearchExpectation.fulfill()
        }

        let writeMSearchMesagesExpectation = self.expectation(description: "should send multiple M-SEARCH requests expectation")
        writeMSearchMesagesExpectation.expectedFulfillmentCount = 2
        udpSocket.writeClosure = { _ in
            writeMSearchMesagesExpectation.fulfill()
        }

        sut = SSDPSearchSession(configuration: configuration, socketFactory: socketFactory)
        sut.delegate = delegate

        sut.startSearch()

        waitForExpectations(timeout: 3, handler: nil)
    }

    func testStartSearch_maximumBroadcastsBeforeClosingConfiguredTo1_writeOnly1MSearchMessage() {
        configuration = SSDPSearchSessionConfiguration.createMulticastConfiguration(forSearchTarget: searchTarget, maximumWaitResponseTime: maximumWaitResponseTime, maximumBroadcastsBeforeClosing: 1)

        let writeMSearchMesagesExpectation = expectation(description: "should handle edge case of broadcasting only 1 SSDP requests expectation")
        writeMSearchMesagesExpectation.expectedFulfillmentCount = 1
        udpSocket.writeClosure = { _ in
            writeMSearchMesagesExpectation.fulfill()
        }

        sut = SSDPSearchSession(configuration: configuration, socketFactory: socketFactory)

        sut.startSearch()

        waitForExpectations(timeout: 3, handler: nil)
    }

    // MARK: - StopSearch

    func testStopSearch_closeSocket() {
        let closeExpectation = expectation(description: "close socket expectation")
        udpSocket.closeClosure = {
            closeExpectation.fulfill()
        }

        sut.startSearch()
        sut.stopSearch()

        waitForExpectations(timeout: 3, handler: nil)
    }

    func testStopSearch_triggerDidStopDelegate() {
        let didStopSearchExpectation = expectation(description: "did trigger stop search delegate expectation")
        delegate.didStopSearchClosure = { (_,_) in
            didStopSearchExpectation.fulfill()
        }

        sut.delegate = delegate
        sut.startSearch()
        sut.stopSearch()

        waitForExpectations(timeout: 3, handler: nil)
    }

    func testStopSearch_stopsSendingMSearchMessages() {
        configuration = SSDPSearchSessionConfiguration.createMulticastConfiguration(forSearchTarget: searchTarget, maximumWaitResponseTime: 4, maximumBroadcastsBeforeClosing: 6)
        // An M-Search message should be sent every 0.5 seconds

        let writeMSearchMesagesExpectation = expectation(description: "write M-Search expectation")
        writeMSearchMesagesExpectation.expectedFulfillmentCount = 1

        var stopSearchCalled = false
        let writeMSearchMesagesAfterStopSearchCalledExpectation = expectation(description: "write M-Search after stop called expectation")
        // We need this isInverted because the code is executed with a timer
        writeMSearchMesagesAfterStopSearchCalledExpectation.isInverted = true

        udpSocket.writeClosure = { _ in
            writeMSearchMesagesExpectation.fulfill()

            self.sut.stopSearch()

            if stopSearchCalled {
                writeMSearchMesagesAfterStopSearchCalledExpectation.fulfill()
            }

            stopSearchCalled = true
        }

        let closeExpectation = expectation(description: "close socket expectation")
        udpSocket.closeClosure = {
            closeExpectation.fulfill()
        }

        sut = SSDPSearchSession(configuration: configuration, socketFactory: socketFactory)

        sut.startSearch()

        wait(for: [writeMSearchMesagesExpectation, closeExpectation], timeout: 3)

        // We need at least one second to test this is correct
        wait(for: [writeMSearchMesagesAfterStopSearchCalledExpectation], timeout: 1.5)
    }

    // MARK: - DidFindService

    func testDidReceiveResponse_validService_triggerDidFindServiceDelegate() {
        let didFindServiceExpectation = expectation(description: "did trigger found service delegate expectation")
        delegate.didFindServiceClosure = { (_,_) in
            didFindServiceExpectation.fulfill()
        }

        let serviceString = "HTTP/1.1 200 OK\r\n" +
            "CACHE-CONTROL: max-age=3600\r\n" +
            "ST: \(searchTarget)\r\n" +
            "USN: uuid:0175c106-5400-10f8-802d-b0a7374360b7::urn:dial-multiscreen-org:service:dial:1\r\n" +
             "EXT:\r\n" +
            "SERVER: Roku UPnP/1.0 MiniUPnPd/1.4\r\n" +
        "LOCATION: http://192.168.1.104:8060/dial/dd.xml\r\n\r\n"

        let serviceData = Data(serviceString.utf8)
        
        sut.delegate = delegate
        sut.session(udpSocket, didReceiveResponse: serviceData)

        waitForExpectations(timeout: 3, handler: nil)
    }

    func testDidReceiveResponse_validService_duplicateService_triggerDidFindServiceDelegateOnce() {
        let didFindServiceExpectation = expectation(description: "did trigger found service delegate expectation")
        didFindServiceExpectation.expectedFulfillmentCount = 1
        delegate.didFindServiceClosure = { (_,_) in
            didFindServiceExpectation.fulfill()
        }

        let serviceString = "HTTP/1.1 200 OK\r\n" +
            "CACHE-CONTROL: max-age=3600\r\n" +
            "ST: \(searchTarget)\r\n" +
            "USN: uuid:0175c106-5400-10f8-802d-b0a7374360b7::urn:dial-multiscreen-org:service:dial:1\r\n" +
            "EXT:\r\n" +
            "SERVER: Roku UPnP/1.0 MiniUPnPd/1.4\r\n" +
        "LOCATION: http://192.168.1.104:8060/dial/dd.xml\r\n\r\n"

        let serviceData = Data(serviceString.utf8)
        
        sut.delegate = delegate

        sut.session(udpSocket, didReceiveResponse: serviceData)
        sut.session(udpSocket, didReceiveResponse: serviceData)

        waitForExpectations(timeout: 3, handler: nil)
    }

    func testDidReceiveResponse_invalidService_doNotTriggerDidFindServiceDelegate() {
        let didFindServiceExpectation = expectation(description: "did trigger found service delegate expectation")
        didFindServiceExpectation.isInverted = true
        delegate.didFindServiceClosure = { (_,_) in
            didFindServiceExpectation.fulfill()
        }

        let serviceString = "HTTP/1.1 200 OK\r\n" +
            "CACHE-CONTROL: max-age=3600\r\n" +
            "ST: RandomSearchTarget\r\n" +
            "USN: uuid:0175c106-5400-10f8-802d-b0a7374360b7::urn:dial-multiscreen-org:service:dial:1\r\n" +
            "EXT:\r\n" +
            "SERVER: Roku UPnP/1.0 MiniUPnPd/1.4\r\n" +
        "LOCATION: http://192.168.1.104:8060/dial/dd.xml\r\n\r\n"

        let serviceData = Data(serviceString.utf8)

        sut.session(udpSocket, didReceiveResponse: serviceData)

        waitForExpectations(timeout: 3, handler: nil)
    }

    // MARK: didEncounterError

    func testDidEncounterError_closeSocket() {
        let closeExpectation = expectation(description: "close socket expectation")
        udpSocket.closeClosure = {
            closeExpectation.fulfill()
        }
        udpSocket.isOpen = true

        let testError = TestError.test

        sut.session(udpSocket, didEncounterError: testError)

        waitForExpectations(timeout: 3, handler: nil)
    }

    func testDidEncounterError_wrapsError_triggerDidEncounterErrorDelegate() {
        let didEncounterErrorExpectation = expectation(description: "did trigger error encountered delegate expectation")
        delegate.didEncounterErrorClosure = { (_, error) in
            if case let SSDPSearchSessionError.searchAborted(nestedError) = error {
                XCTAssertTrue(nestedError is TestError)
            } else {
                XCTFail("Unexpected error type")
            }

            didEncounterErrorExpectation.fulfill()
        }

        let testError = TestError.test
        
        sut.delegate = delegate
        sut.session(udpSocket, didEncounterError: testError)

        waitForExpectations(timeout: 3, handler: nil)
    }
}
