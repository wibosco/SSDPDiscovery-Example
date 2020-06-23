//
//  UDPSocketTests.swift
//  SSDP-ExampleTests
//
//  Created by William Boles on 15/06/2020.
//  Copyright © 2020 William Boles. All rights reserved.
//

import XCTest
@testable import SSDP_Example

class UDPSocketControllerTests: XCTestCase {
    
    var sut: UDPSocketController!
    
    var socket: MockSocket!
    var socketFactory: MockSocketFactory!
    var delegate: MockUDPSocketControllerDelegate!
    
    let host = "239.255.255.250"
    let port = 1900
    
    // MARK: - Lifecycle
    
    override func setUp() {
        socket = MockSocket()
        socketFactory = MockSocketFactory()
        socketFactory.udpSocketToBeReturned = socket
        delegate = MockUDPSocketControllerDelegate()
        
        sut = UDPSocketController(host: host, port: 1900, socketFactory: socketFactory, callbackQueue: .main)
        sut.delegate = delegate
    }

    override func tearDown() {
        socket = nil
        socketFactory = nil
        delegate = nil
        
        sut = nil
    }
    
    // MARK: - Tests
    
    // MARK: Write
    
    func testWrite_writeMessageToSocketOnCorrectHostAndPot() {
        let testMessage = "test message"
        
        let writeToSocketExpectation = expectation(description: "should write message to host on port expectation")
        socket.writeClosure = { message, host, port in
            XCTAssertEqual(message, testMessage)
            XCTAssertEqual(host, self.host)
            XCTAssertEqual(port, UInt(self.port))
            
            writeToSocketExpectation.fulfill()
        }
    
        sut.write(message: testMessage)
        
        waitForExpectations(timeout: 3) { (_) in
            XCTAssertTrue(self.sut.state.isActive)
        }
    }
    
    func testWrite_onFirstWriteSetUpReading() {
        let readFromSocketExpectation = expectation(description: "should set up socket reading expectation")
        socket.readDatagramClosure = { data in
            readFromSocketExpectation.fulfill()
        }
        
        sut.write(message: "test message")
        
        waitForExpectations(timeout: 3, handler: nil)
    }
    
    func testWrite_writeTwice_onlyOpenForReadingOnce() {
        var readOnce = false
        let firstReadFromSocketExpectation = expectation(description: "should set up socket reading expectation")
        let secondReadFromSocketExpectation = expectation(description: "should only set up socket reading once expectation")
        secondReadFromSocketExpectation.isInverted = true
        socket.readDatagramClosure = { (_) in
            if readOnce {
                secondReadFromSocketExpectation.fulfill()
            } else {
                firstReadFromSocketExpectation.fulfill()
            }
            readOnce = true
        }
        
        sut.write(message: "test message A")
        sut.write(message: "test message B")
        
        waitForExpectations(timeout: 3, handler: nil)
    }
    
    func testWrite_errorOnWrite_closeSocket_triggerDidEncounterErrorDelegate() {
        socket.throwWriteException = true
        
        let didEncounterErrorExpectation = expectation(description: "did encounter error expection")
        delegate.didEncounterErrorClosure = { (_,_) in
            didEncounterErrorExpectation.fulfill()
        }
        
        let closeExpectation = expectation(description: "close socket expectation")
        socket.closureClosure = {
            closeExpectation.fulfill()
        }
        
        sut.write(message: "test message")
        
        waitForExpectations(timeout: 3) { (_) in
            XCTAssertFalse(self.sut.state.isActive)
        }
    }
    
    func testWrite_closedSocket_doesNothing() {
        let writeToSocketExpectation = expectation(description: "should not write message to host on port expectation")
        writeToSocketExpectation.isInverted = true
        socket.writeClosure = { message, host, port in
            writeToSocketExpectation.fulfill()
        }
        
        let readFromSocketExpectation = expectation(description: "should not set up socket reading expectation")
        readFromSocketExpectation.isInverted = true
        socket.readDatagramClosure = { data in
            readFromSocketExpectation.fulfill()
        }
        
        sut.close()
        sut.write(message: "test")
        
        waitForExpectations(timeout: 3, handler: nil)
    }
    
    // MARK: Read
    
    func testRead_validResponse_triggerDidReceiveResponseDelegate() {
        let didReceiveResponseExpectation = expectation(description: "did receive response delegate expectation")
        delegate.didReceiveResponseClosure = { (_,_) in
            didReceiveResponseExpectation.fulfill()
        }
        
        sut.write(message: "test data")
        
        //simulate network call
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.socket.releaseReadQueue = true
        }
        
        waitForExpectations(timeout: 3, handler: nil)
    }
    
    func testRead_receiveValidResponse_socketOpen_readAgain() {
        let readExpectation = expectation(description: "read socket expectation")
        readExpectation.expectedFulfillmentCount = 2
        socket.readDatagramClosure = { (_) in
            readExpectation.fulfill()
        }
        
        sut.write(message: "test data")
        
        //simulate network call
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.socket.releaseReadQueue = true
        }
        
        waitForExpectations(timeout: 3, handler: nil)
    }
    
    func testRead_receiveValidResponse_thenSocketClosed_doNotReadAgain() {
        var readOnce = false
        let firstReadFromSocketExpectation = expectation(description: "should set up socket reading expectation")
        let secondReadFromSocketExpectation = expectation(description: "should only set up socket reading once expectation")
        secondReadFromSocketExpectation.isInverted = true
        socket.readDatagramClosure = { (_) in
            if readOnce {
                secondReadFromSocketExpectation.fulfill()
            } else {
                firstReadFromSocketExpectation.fulfill()
                
                self.sut.close()
                
                //simulate network call
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    self.socket.releaseReadQueue = true
                }
            }
            readOnce = true
        }
        
        sut.write(message: "test data")
        
        waitForExpectations(timeout: 3, handler: nil)
    }
    
    func testRead_errorOnRead_closeSocket_triggerDidEncounterErrorDelegate() {
        socket.throwReadException = true
        
        let didEncounterErrorExpectation = expectation(description: "did encounter error expection")
        delegate.didEncounterErrorClosure = { (_,_) in
            didEncounterErrorExpectation.fulfill()
        }
        
        let closeExpectation = expectation(description: "close socket expectation")
        socket.closureClosure = {
            closeExpectation.fulfill()
        }
        
        sut.write(message: "test message")
        
        waitForExpectations(timeout: 3) { (_) in
            XCTAssertFalse(self.sut.state.isActive)
        }
    }
    
    func testRead_errorOnClosedSocket_doNotTriggerDidEncounterErrorDelegate() {
        let didEncounterErrorExpectation = expectation(description: "did encounter error expection")
        didEncounterErrorExpectation.isInverted = true
        delegate.didEncounterErrorClosure = { (_,_) in
            didEncounterErrorExpectation.fulfill()
        }
        
        sut.write(message: "test message")
        
        //simulate network call
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.sut.close()
            self.socket.throwReadException = true
        }
        
        waitForExpectations(timeout: 3) { (_) in
            XCTAssertFalse(self.sut.state.isActive)
        }
    }
    
    // MARK: Close
    
    func testClose_stateChanged_socketClosed() {
        let closeExpectation = expectation(description: "close socket expectation")
        socket.closureClosure = {
            closeExpectation.fulfill()
        }
        
        sut.close()
        
        waitForExpectations(timeout: 3) { (_) in
            XCTAssertTrue(self.sut.state.isClosed)
        }
    }
}
