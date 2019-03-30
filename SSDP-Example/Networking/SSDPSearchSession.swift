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

protocol SSDPSearchSessionDelegate: class {
    func searchSession(_ searchSession: SSDPSearchSession, didFindService service: SSDPService)
    func searchSession(_ searchSession: SSDPSearchSession, didAbortWithError error: SSDPSearchSessionError)
    func searchSessionDidStopSearch(_ searchSession: SSDPSearchSession, foundServices: [SSDPService])
}

class SSDPSearchSession {
    weak var delegate: SSDPSearchSessionDelegate?
    
    private let socket: Socket
    private let configuration: SSDPSearchSessionConfiguration
    private var isListening = false
    private let listeningQueue = DispatchQueue(label: "com.williamboles.listening")
    private var servicesFoundDuringSearch = [SSDPService]()
    private var broadcastTimer: Timer?
    private var timeoutTimer: Timer?
    
    // MARK: - Init
    
    init?(configuration: SSDPSearchSessionConfiguration) {
        guard let socket = try? Socket.create(type: .datagram, proto: .udp) else {
            return nil
        }
        self.socket = socket
        self.configuration = configuration
    }
    
    // MARK: - Search
    
    func startSearch() {
        os_log(.info, "SSDP search session starting")
        prepareSocketForResponses()
        broadcastMultipleSearchRequests()
        
        let searchTimeout = (TimeInterval(configuration.maximumBroadcastsBeforeClosing) * configuration.maximumWaitResponseTime) + 0.1
        timeoutTimer = Timer.scheduledTimer(withTimeInterval: searchTimeout, repeats: false, block: { [weak self] (timer) in
            self?.searchTimedOut()
        })
    }
    
    private func searchTimedOut() {
        os_log(.info, "SSDP search timed out")
        close(dueToError: nil)
    }
    
    func stopSearch() {
        os_log(.info, "SSDP search session stopping")
        close(dueToError: nil)
    }
    
    // MARK: - Close
    
    private func close(dueToError error: SSDPSearchSessionError?) {
        guard isListening else {
            return
        }
        broadcastTimer?.invalidate()
        broadcastTimer = nil
        timeoutTimer?.invalidate()
        timeoutTimer = nil
        isListening = false
        socket.close()
        
        if let error = error {
            delegate?.searchSession(self, didAbortWithError: error)
        } else {
            delegate?.searchSessionDidStopSearch(self, foundServices: servicesFoundDuringSearch)
        }
    }
    
    private func handleError(_ error: Error) {
        os_log(.error, "SSDP discovery error: %{public}@", error.localizedDescription)
        let wrappedError = SSDPSearchSessionError.searchAborted(error)
        close(dueToError: wrappedError)
    }
    
    // MARK: Write
    
    private func broadcastMultipleSearchRequests() {
        let searchMessage = self.searchMessage()
        broadcastTimer = Timer.scheduledTimer(withTimeInterval: configuration.maximumWaitResponseTime, repeats: true, block: { [weak self] (timer) in
            self?.writeToSocket(searchMessage)
        })
        broadcastTimer?.fire()
    }
    
    private func writeToSocket(_ datagram: String) {
        guard let address = Socket.createAddress(for: configuration.host, on: Int32(configuration.port)) else {
            handleError(SSDPSearchSessionError.addressCreationFailure)
            return
        }
        
        do {
            os_log(.info, "Writing datagram to socket: \r%{public}@", datagram)
            try socket.write(from: datagram, to: address)
        } catch {
            handleError(error)
        }
    }
    
    private func searchMessage() -> String {
        // Each line must end in `\r\n`
        return "M-SEARCH * HTTP/1.1\r\n" +
            "HOST: \(configuration.host):\(configuration.port)\r\n" +
            "MAN: \"ssdp:discover\"\r\n" +
            "ST: \(configuration.searchTarget)\r\n" +
            "MX: \(Int(configuration.maximumWaitResponseTime))\r\n" +
        "\r\n"
    }
    
    // MARK: - Read
    
    private func prepareSocketForResponses() {
        listeningQueue.async() { [weak self] in
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
                let service = SSDPServiceParser.parse(data),
                searchedForService(service),
                !servicesFoundDuringSearch.contains(service) else {
                    return
            }
            
            servicesFoundDuringSearch.append(service)
            
            delegate?.searchSession(self, didFindService: service)
        } catch {
            if isListening {
                handleError(error)
            }
        }
    }
    
    private func searchedForService(_ service: SSDPService) -> Bool {
        return service.searchTarget.contains(configuration.searchTarget) || configuration.searchTarget == "ssdp:all"
    }
}
