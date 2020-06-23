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
    var socketControllerFactory: MockSocketControllerFactory!
    var socketController: MockUDPSocketController!
    var delegate: MockSSDPSearchSessionDelegate!
    var parser: MockSSDPServiceParser!
    
    // MARK: - Lifecycle
    
    override func setUp() {
        configuration = SSDPSearchSessionConfiguration.createMulticastConfiguration(forSearchTarget: searchTarget, maximumWaitResponseTime: maximumWaitResponseTime, maximumBroadcastsBeforeClosing: maximumBroadcastsBeforeClosing)
        socketController = MockUDPSocketController()
        socketControllerFactory = MockSocketControllerFactory()
        socketControllerFactory.udpSocketControllerToBeReturned = socketController
        delegate = MockSSDPSearchSessionDelegate()
        parser = MockSSDPServiceParser()
        
        sut = SSDPSearchSession(configuration: configuration, socketControllerFactory: socketControllerFactory, parser: parser)
    }
    
    override func tearDown() {
        configuration = nil
        socketControllerFactory = nil
        socketController = nil
        delegate = nil
        parser = nil
        
        sut = nil
    }
    
    // MARK: - Tests
    
    // MARK: Init
    
    func testInit_failed() {
        socketControllerFactory.udpSocketControllerToBeReturned = nil
        
        sut = SSDPSearchSession(configuration: configuration, socketControllerFactory: socketControllerFactory, parser: parser)
        
        XCTAssertNil(sut)
    }
    
    func testInit_socketDelegateSet() {
        XCTAssertTrue(sut === socketController.delegate)
    }
    
    // MARK: StartSearch
    
    func testStartSearch_sendMSearchMessage() {
        let expectedMessage = "M-SEARCH * HTTP/1.1\r\n" +
            "HOST: 239.255.255.250:1900\r\n" +
            "MAN: \"ssdp:discover\"\r\n" +
            "ST: \(searchTarget)\r\n" +
        "MX: \(Int(maximumWaitResponseTime))\r\n\r\n"
        
        let writeToSocketExpectation = expectation(description: "write m-search to socket expectation")
        socketController.writeClosure = { message in
            XCTAssertEqual(message, expectedMessage)
            
            writeToSocketExpectation.fulfill()
        }
        
        sut.startSearch()
        
        waitForExpectations(timeout: 3, handler: nil)
    }
    
    func testStartSearch_zeroMaximumBroadcasts_triggerStopSearchDelegate_doesNotWriteToSocket() {
        configuration = SSDPSearchSessionConfiguration.createMulticastConfiguration(forSearchTarget: "searchTarget", maximumWaitResponseTime: maximumWaitResponseTime, maximumBroadcastsBeforeClosing: 0)
        
        sut = SSDPSearchSession(configuration: configuration, socketControllerFactory: socketControllerFactory, parser: parser)
        sut.delegate = delegate
        
        let didStopSearchingExpectation = expectation(description: "did trigger stop search delegate expectation")
        delegate.didStopSearchClosure = { (_, services) in
            XCTAssertEqual(services.count, 0)
            
            didStopSearchingExpectation.fulfill()
        }
        
        let socketWriteExpectation = expectation(description: "should not write m-search message to socket expectation")
        socketWriteExpectation.isInverted = true
        socketController.writeClosure = { _ in
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
        socketController.writeClosure = { _ in
            writeMSearchMesagesExpectation.fulfill()
        }
        
        sut = SSDPSearchSession(configuration: configuration, socketControllerFactory: socketControllerFactory)
        sut.delegate = delegate
        
        sut.startSearch()
        
        waitForExpectations(timeout: 3, handler: nil)
    }
    
    func testStartSearch_maximumBroadcastsBeforeClosingConfiguredTo1_writeOnly1MSearchMessage() {
        configuration = SSDPSearchSessionConfiguration.createMulticastConfiguration(forSearchTarget: searchTarget, maximumWaitResponseTime: maximumWaitResponseTime, maximumBroadcastsBeforeClosing: 1)
        
        let writeMSearchMesagesExpectation = expectation(description: "should handle edge case of broadcasting only 1 SSDP requests expectation")
        writeMSearchMesagesExpectation.expectedFulfillmentCount = 1
        socketController.writeClosure = { _ in
            writeMSearchMesagesExpectation.fulfill()
        }
        
        sut = SSDPSearchSession(configuration: configuration, socketControllerFactory: socketControllerFactory)
        
        sut.startSearch()
        
        waitForExpectations(timeout: 3, handler: nil)
    }
    
    // MARK: - StopSearch
    
    func testStopSearch_closeSocket() {
        let closeExpectation = expectation(description: "close socket expectation")
        socketController.closeClosure = {
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
        
        socketController.writeClosure = { _ in
            writeMSearchMesagesExpectation.fulfill()
            
            self.sut.stopSearch()
            
            if stopSearchCalled {
                writeMSearchMesagesAfterStopSearchCalledExpectation.fulfill()
            }
            
            stopSearchCalled = true
        }
        
        let closeExpectation = expectation(description: "close socket expectation")
        socketController.closeClosure = {
            closeExpectation.fulfill()
        }
        
        sut = SSDPSearchSession(configuration: configuration, socketControllerFactory: socketControllerFactory)
        
        sut.startSearch()
        
        wait(for: [writeMSearchMesagesExpectation, closeExpectation], timeout: 3)
        
        // We need at least one second to test this is correct
        wait(for: [writeMSearchMesagesAfterStopSearchCalledExpectation], timeout: 1.5)
    }
    
    // MARK: - DidFindService
    
    func testDidReceiveResponse_validServiceWithMatchingSearchTarget_triggerDidFindServiceDelegate() {
        let didFindServiceExpectation = expectation(description: "did trigger found service delegate expectation")
        delegate.didFindServiceClosure = { (_,_) in
            didFindServiceExpectation.fulfill()
        }
        
        let service = SSDPService(cacheControl: Date.distantPast, location: URL(string: "http://www.location.com")!, server: "server", searchTarget: searchTarget, uniqueServiceName: "uniqueServiceName", otherHeaders: [:])
        parser.serviceToBeReturned = service
        
        let serviceString = "validService"
        let serviceData = Data(serviceString.utf8)
        
        sut.delegate = delegate
        sut.controller(socketController, didReceiveResponse: serviceData)
        
        waitForExpectations(timeout: 3, handler: nil)
    }
    
    func testDidReceiveResponse_validServiceWithMatchingSearchTarget_duplicateService_triggerDidFindServiceDelegateOnce() {
        let didFindServiceExpectation = expectation(description: "did trigger found service delegate expectation")
        didFindServiceExpectation.expectedFulfillmentCount = 1
        delegate.didFindServiceClosure = { (_,_) in
            didFindServiceExpectation.fulfill()
        }
        
        let service = SSDPService(cacheControl: Date.distantPast, location: URL(string: "http://www.location.com")!, server: "server", searchTarget: searchTarget, uniqueServiceName: "uniqueServiceName", otherHeaders: [:])
        parser.serviceToBeReturned = service
        
        let serviceString = "validService"
        let serviceData = Data(serviceString.utf8)
        
        sut.delegate = delegate
        
        sut.controller(socketController, didReceiveResponse: serviceData)
        sut.controller(socketController, didReceiveResponse: serviceData)
        
        waitForExpectations(timeout: 3, handler: nil)
    }
    
    func testDidReceiveResponse_validService_searchingForSSDPAll_triggerDidFindServiceDelegate() {
        let didFindServiceExpectation = expectation(description: "did trigger found service delegate expectation")
        didFindServiceExpectation.expectedFulfillmentCount = 1
        delegate.didFindServiceClosure = { (_,_) in
            didFindServiceExpectation.fulfill()
        }
        
        let service = SSDPService(cacheControl: Date.distantPast, location: URL(string: "http://www.location.com")!, server: "server", searchTarget: "randomSearchTarget", uniqueServiceName: "uniqueServiceName", otherHeaders: [:])
        parser.serviceToBeReturned = service
        
        let serviceString = "validService"
        let serviceData = Data(serviceString.utf8)
        
        configuration = SSDPSearchSessionConfiguration.createMulticastConfiguration(forSearchTarget: "ssdp:all", maximumWaitResponseTime: maximumWaitResponseTime, maximumBroadcastsBeforeClosing: maximumBroadcastsBeforeClosing)
        sut = SSDPSearchSession(configuration: configuration, socketControllerFactory: socketControllerFactory, parser: parser)
        sut.delegate = delegate
        
        sut.controller(socketController, didReceiveResponse: serviceData)
        sut.controller(socketController, didReceiveResponse: serviceData)
        
        waitForExpectations(timeout: 3, handler: nil)
    }
    
    func testDidReceiveResponse_validServiceWithNonMatchingSearchTarget_doNotTriggerDidFindServiceDelegate() {
        let didFindServiceExpectation = expectation(description: "did trigger found service delegate expectation")
        didFindServiceExpectation.isInverted = true
        delegate.didFindServiceClosure = { (_,_) in
            didFindServiceExpectation.fulfill()
        }
        
        let service = SSDPService(cacheControl: Date.distantPast, location: URL(string: "http://www.location.com")!, server: "server", searchTarget: "randomSearchTarget", uniqueServiceName: "uniqueServiceName", otherHeaders: [:])
        parser.serviceToBeReturned = service
        
        let serviceString = "validService"
        let serviceData = Data(serviceString.utf8)
        
        sut.controller(socketController, didReceiveResponse: serviceData)
        
        waitForExpectations(timeout: 3, handler: nil)
    }
    
    func testDidReceiveResponse_invalidServiceStructure_doNotTriggerDidFindServiceDelegate() {
        let didFindServiceExpectation = expectation(description: "did trigger found service delegate expectation")
        didFindServiceExpectation.isInverted = true
        delegate.didFindServiceClosure = { (_,_) in
            didFindServiceExpectation.fulfill()
        }
        
        parser.serviceToBeReturned = nil
        
        let serviceString = "invalidService"
        let serviceData = Data(serviceString.utf8)
        
        sut.controller(socketController, didReceiveResponse: serviceData)
        
        waitForExpectations(timeout: 3, handler: nil)
    }
    
    func testDidReceiveResponse_emptyReponse_doNotTriggerDidFindServiceDelegate() {
        let didFindServiceExpectation = expectation(description: "did trigger found service delegate expectation")
        didFindServiceExpectation.isInverted = true
        delegate.didFindServiceClosure = { (_,_) in
            didFindServiceExpectation.fulfill()
        }
        
        parser.serviceToBeReturned = nil
        
        let serviceData = Data()
        
        sut.controller(socketController, didReceiveResponse: serviceData)
        
        waitForExpectations(timeout: 3, handler: nil)
    }
    
    // MARK: didEncounterError
    
    func testDidEncounterError_closeSocket() {
        let closeExpectation = expectation(description: "close socket expectation")
        socketController.closeClosure = {
            closeExpectation.fulfill()
        }
        socketController.state = .active
        
        let testError = TestError.test
        
        sut.controller(socketController, didEncounterError: testError)
        
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
        sut.controller(socketController, didEncounterError: testError)
        
        waitForExpectations(timeout: 3, handler: nil)
    }
}
