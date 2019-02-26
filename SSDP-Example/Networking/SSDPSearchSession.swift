//
//  SSDPSearchSession.swift
//  SSDP-Example
//
//  Created by William Boles on 17/02/2019.
//  Copyright © 2019 William Boles. All rights reserved.
//

import Foundation
import Socket
import os

enum SSDPSearchSessionError: Error {
    case addressCreationFailure
    case searchAborted(Error)
}

class SSDPSearchSession {
    typealias SSDPResponseHandler = (Result<SSDPSearchResponse, SSDPSearchSessionError>) -> Void
    
    private let socket: Socket
    private let configuration: SSDPSearchSessionConfiguration
    private var isListening = false
    private var responseHandler: SSDPResponseHandler?
    private var respondedDevices = [SSDPSearchResponse]()
    private let searchQueue = DispatchQueue(label: "com.williamboles.searchqueue", attributes: .concurrent)
    private let processingQueue = DispatchQueue(label: "com.williamboles.processingqueue")
    private var broadcastTimer: Timer?
    private var finalBroadcastTimer: Timer?
    
    // MARK: - Init
    
    init?(configuration: SSDPSearchSessionConfiguration) {
        guard let socket = try? Socket.create(type: .datagram, proto: .udp) else {
            return nil
        }
        self.socket = socket
        self.configuration = configuration
    }
    
    // MARK: - Broadcast
    
    func broadcastMulticastSearch(responseHandler: @escaping SSDPResponseHandler) {
        self.responseHandler = responseHandler
        
        prepareSocketForResponses()
        broadcastMultipleMulticastSearchRequests()
    }
    
    private func broadcastMultipleMulticastSearchRequests() {
        let broadcastTimeInterval = configuration.maximumWaitResponseTime
        broadcastTimer = Timer.scheduledTimer(withTimeInterval: broadcastTimeInterval, repeats: true, block: { [weak self] (timer) in
            self?.writeDatagramToSocket()
        })
        broadcastTimer?.fire()
        
        let finalBroadcastTimeInterval = configuration.searchTimeout - configuration.maximumWaitResponseTime
        finalBroadcastTimer = Timer.scheduledTimer(withTimeInterval: finalBroadcastTimeInterval, repeats: false, block: { [weak self] (timer) in
            self?.finalBroadcastTimer?.invalidate()
            self?.broadcastTimer?.invalidate()
        })
    }
    
    // MARK: Write
    
    private func writeDatagramToSocket() {
        guard let address = Socket.createAddress(for: configuration.host, on: Int32(configuration.port)) else {
            handleError(SSDPSearchSessionError.addressCreationFailure)
            return
        }
        
        do {
            let multicastSearchMessage = self.multicastSearchMessage()
            os_log(.info, "Writing SSDP M-Search request: \r%{public}@", multicastSearchMessage)
            try socket.write(from: multicastSearchMessage, to: address)
        } catch {
            handleError(error)
        }
    }
    
    private func multicastSearchMessage() -> String {
        // Each line must end in `\r\n`
        return "M-SEARCH * HTTP/1.1\r\n" +
            "HOST: \(configuration.host):\(configuration.port)\r\n" +
            "MAN: \"ssdp:discover\"\r\n" +
            "ST: \(configuration.searchTarget)\r\n" +
        "MX: \(Int(configuration.maximumWaitResponseTime))\r\n\r\n"
    }
    
    // MARK: - Read
    
    private func prepareSocketForResponses() {
        searchQueue.async() { [weak self] in
            self?.isListening = true
            self?.readResponse() // contains blocking call
        }
    }
    
    private func readResponse() {
        defer {
            if isListening {
                readResponse()
            }
        }
        
        do {
            var data = Data()
            let (bytesRead, _) = try socket.readDatagram(into: &data) //blocking call
            
            processingQueue.sync {
                guard bytesRead > 0,
                    let searchResponse = SSDPSearchResponse(data: data),
                    (searchResponse.searchTarget.contains(configuration.searchTarget) || configuration.searchTarget == "ssdp:all"),
                    !respondedDevices.contains(searchResponse) else {
                        return
                }
                
                respondedDevices.append(searchResponse)
                
                responseHandler?(Result.success(searchResponse))
            }
        } catch {
            if isListening {
                handleError(error)
            }
        }
    }
    
    private func handleError(_ error: Error) {
        os_log(.error, "SSDP discovery error: %{public}@", error.localizedDescription)
        close()
        let wrappedError = SSDPSearchSessionError.searchAborted(error)
        responseHandler?(Result.failure(wrappedError))
    }
    
    // MARK: - Close
    
    func close() {
        os_log(.info, "SSDP search session is closing")
        finalBroadcastTimer?.invalidate()
        finalBroadcastTimer = nil
        broadcastTimer?.invalidate()
        broadcastTimer = nil
        isListening = false
        socket.close()
        responseHandler = nil
    }
}
