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
    private var respondedDevices: [SSDPSearchResponse]
    
    // MARK: - Init
    
    init?(configuration: SSDPSearchSessionConfiguration) {
        guard let socket = try? Socket.create(type: .datagram, proto: .udp) else {
            return nil
        }
        self.socket = socket
        self.configuration = configuration
        self.respondedDevices = [SSDPSearchResponse]()
    }
    
    // MARK: - Broadcast
    
    func broadcastMulticastSearch(responseHandler: @escaping SSDPResponseHandler) {
        self.responseHandler = responseHandler
        
        prepareSocketForResponses()
        broadcastMultipleMulticastSearchRequests()
    }
    
    private func broadcastMultipleMulticastSearchRequests() {
        let queue = DispatchQueue.global(qos: .userInitiated)
        let broadcastWindow = configuration.searchTimeout - configuration.maximumWaitResponseTime
        let strideInterval = broadcastWindow / TimeInterval(configuration.possibleSearchBroadcasts)
        
        for interval in stride(from: 0.0, to: broadcastWindow, by: strideInterval) {
            queue.asyncAfter(deadline: .now() + interval, execute: { [weak self] in
                self?.writeDatagramToSocket()
            })
        }
    }
    
    // MARK: Write
    
    private func writeDatagramToSocket() {
        guard let address = Socket.createAddress(for: configuration.host, on: Int32(configuration.port)) else {
            handleError(SSDPSearchSessionError.addressCreationFailure)
            return
        }
        
        do {
            let multicastSearchMessage = self.multicastSearchMessage()
            os_log(.info, "Writing SSDP M-Search request: %{public}@", multicastSearchMessage)
            try socket.write(from: multicastSearchMessage, to: address)
        } catch {
            handleError(error)
        }
    }
    
    private func multicastSearchMessage() -> String {
        // Each line must end in `\r\n`
        return "M-SEARCH * HTTP/1.1\r\n" +
            "MAN: \"ssdp:discover\"\r\n" +
            "HOST: \(configuration.host):\(configuration.port)\r\n" +
            "ST: \(configuration.searchTarget)\r\n" +
        "MX: \(Int(configuration.maximumWaitResponseTime))\r\n\r\n"
    }
    
    // MARK: - Read
    
    private func prepareSocketForResponses() {
        let queue = DispatchQueue.global(qos: .userInitiated)
        queue.async() { [weak self] in
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
            
            guard bytesRead > 0,
                let searchResponse = SSDPSearchResponse(data: data),
                (searchResponse.searchTarget.contains(configuration.searchTarget) || configuration.searchTarget == "ssdp:all"),
                !respondedDevices.contains(searchResponse) else {
                    return
            }
            
            os_log(.info, "Recieved unique SSDP response: %{public}@", String(describing: searchResponse))
            
            respondedDevices.append(searchResponse)
            
            responseHandler?(Result.success(searchResponse))
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
        isListening = false
        socket.close()
        responseHandler = nil
    }
}
