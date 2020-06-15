//
//  SSDPSearchSession.swift
//  SSDP-Example
//
//  Created by William Boles on 17/02/2019.
//  Copyright © 2019 William Boles. All rights reserved.
//

import Foundation
import os

enum SSDPSearchSessionError: Error {
    case searchAborted(Error)
}

protocol SSDPSearchSessionDelegate: class {
    func searchSession(_ searchSession: SSDPSearchSession, didFindService service: SSDPService)
    func searchSession(_ searchSession: SSDPSearchSession, didEncounterError error: SSDPSearchSessionError)
    func searchSessionDidStopSearch(_ searchSession: SSDPSearchSession, foundServices: [SSDPService])
}

protocol SSDPSearchSessionProtocol {
    var delegate: SSDPSearchSessionDelegate? { get set }
    
    func startSearch()
    func stopSearch()
}

class SSDPSearchSession: SSDPSearchSessionProtocol, UDPSocketDelegate {
    weak var delegate: SSDPSearchSessionDelegate?
    
    private let socket: UDPSocketProtocol
    private let configuration: SSDPSearchSessionConfiguration
    private let parser: SSDPServiceParserProtocol
    
    private var servicesFoundDuringSearch = [SSDPService]()
    
    private let searchTimeout: TimeInterval
    
    private var broadcastTimer: Timer?
    private var timeoutTimer: Timer?
    
    // MARK: - Init
    
    init?(configuration: SSDPSearchSessionConfiguration, socketFactory: SocketFactoryProtocol = SocketFactory(), parser: SSDPServiceParserProtocol = SSDPServiceParser()) {
        guard let socket = socketFactory.createUDPSocket(host: configuration.host, port: configuration.port) else {
            return nil
        }
        self.socket = socket
        self.configuration = configuration
        self.parser = parser
        self.searchTimeout = (TimeInterval(configuration.maximumBroadcastsBeforeClosing) * configuration.maximumWaitResponseTime) + 0.1
        
        self.socket.delegate = self
    }
    
    // MARK: - Search
    
    func startSearch() {
        guard configuration.maximumBroadcastsBeforeClosing > 0 else {
            delegate?.searchSessionDidStopSearch(self, foundServices:servicesFoundDuringSearch)
            return
        }
        
        os_log(.info, "SSDP search session starting")
        sendMSearchMessages()
        
        timeoutTimer = Timer.scheduledTimer(withTimeInterval: searchTimeout, repeats: false, block: { [weak self] (timer) in
            self?.searchTimedOut()
        })
    }
    
    private func searchTimedOut() {
        os_log(.info, "SSDP search timed out")
        stopSearch()
    }
    
    func stopSearch() {
        os_log(.info, "SSDP search session stopping")
        close()
        
        delegate?.searchSessionDidStopSearch(self, foundServices:servicesFoundDuringSearch)
    }
    
    // MARK: - Close
    
    private func close() {
        broadcastTimer?.invalidate()
        broadcastTimer = nil
        
        timeoutTimer?.invalidate()
        timeoutTimer = nil
        
        if socket.state.isActive {
            socket.close()
        }
    }
    
    // MARK: Write
    
    private func searchMessage() -> String {
        // Each line must end in `\r\n`
        return "M-SEARCH * HTTP/1.1\r\n" +
            "HOST: \(configuration.host):\(configuration.port)\r\n" +
            "MAN: \"ssdp:discover\"\r\n" +
            "ST: \(configuration.searchTarget)\r\n" +
            "MX: \(Int(configuration.maximumWaitResponseTime))\r\n" +
        "\r\n"
    }
    
    private func sendMSearchMessages() {
        let searchMessage = self.searchMessage()
        
        if configuration.maximumBroadcastsBeforeClosing > 1 {
            let window = searchTimeout - configuration.maximumWaitResponseTime
            let interval = window / TimeInterval((configuration.maximumBroadcastsBeforeClosing - 1))
            
            broadcastTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true, block: { [weak self] (timer) in
                self?.writeToSocket(searchMessage)
            })
        }
        writeToSocket(searchMessage)
    }
    
    private func writeToSocket(_ message: String) {
        os_log(.info, "Writing to socket: \r%{public}@", message)
        socket.write(message: message)
    }
    
    // MARK: - UDPSocketDelegate
    
    func session(_ socket: UDPSocketProtocol, didReceiveResponse response: Data) {
        os_log(.info, "Received potential service")
        guard !response.isEmpty,
            let service = parser.parse(response),
            searchedForService(service),
            !servicesFoundDuringSearch.contains(service) else {
                return
        }
        
        os_log(.info, "Received valid service")
        
        servicesFoundDuringSearch.append(service)
        
        delegate?.searchSession(self, didFindService: service)
    }
    
    func session(_ socket: UDPSocketProtocol, didEncounterError error: Error) {
        os_log(.info, "Encountered socket error: \r%{public}@", error.localizedDescription)
        let wrappedError = SSDPSearchSessionError.searchAborted(error)
        delegate?.searchSession(self, didEncounterError: wrappedError)
        close()
    }
    
    private func searchedForService(_ service: SSDPService) -> Bool {
        return service.searchTarget.contains(configuration.searchTarget) || configuration.searchTarget == "ssdp:all"
    }
}