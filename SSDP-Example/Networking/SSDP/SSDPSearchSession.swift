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

class SSDPSearchSession: SSDPSearchSessionProtocol, UDPSocketControllerDelegate {
    weak var delegate: SSDPSearchSessionDelegate?
    
    private let socketController: UDPSocketControllerProtocol
    private let configuration: SSDPSearchSessionConfiguration
    private let parser: SSDPServiceParserProtocol
    
    private var servicesFoundDuringSearch = [SSDPService]()
    
    private let searchTimeout: TimeInterval
    
    private var broadcastTimer: Timer?
    private var timeoutTimer: Timer?
    
    private lazy var mSearchMessage = {
        // Each line must end in `\r\n`
        return "M-SEARCH * HTTP/1.1\r\n" +
            "HOST: \(configuration.host):\(configuration.port)\r\n" +
            "MAN: \"ssdp:discover\"\r\n" +
            "ST: \(configuration.searchTarget)\r\n" +
            "MX: \(Int(configuration.maximumWaitResponseTime))\r\n" +
        "\r\n"
    }()
    
    // MARK: - Init
    
    init?(configuration: SSDPSearchSessionConfiguration, socketControllerFactory: SocketControllerFactoryProtocol = SocketControllerFactory(), parser: SSDPServiceParserProtocol = SSDPServiceParser()) {
        guard let socketController = socketControllerFactory.createUDPSocketController(host: configuration.host, port: configuration.port, socketFactory: SocketFactory(), callbackQueue: .main) else {
            return nil
        }
        self.socketController = socketController
        self.configuration = configuration
        self.parser = parser
        self.searchTimeout = (TimeInterval(configuration.maximumBroadcastsBeforeClosing) * configuration.maximumWaitResponseTime) + 0.1
        
        self.socketController.delegate = self
    }
    
    // MARK: - Search
    
    func startSearch() {
        guard configuration.maximumBroadcastsBeforeClosing > 0 else {
            delegate?.searchSessionDidStopSearch(self, foundServices: servicesFoundDuringSearch)
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
        
        if socketController.state.isActive {
            socketController.close()
        }
    }
    
    // MARK: Write
    
    private func sendMSearchMessages() {
        let message = mSearchMessage
        
        if configuration.maximumBroadcastsBeforeClosing > 1 {
            let window = searchTimeout - configuration.maximumWaitResponseTime
            let interval = window / TimeInterval((configuration.maximumBroadcastsBeforeClosing - 1))
            
            broadcastTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true, block: { [weak self] (timer) in
                self?.socketController.write(message: message)
            })
        }
        writeMessageToSocket(message)
    }
    
    private func writeMessageToSocket(_ message: String) {
        os_log(.info, "Writing to socket: \r%{public}@", message)
        socketController.write(message: message)
    }
    
    // MARK: - UDPSocketControllerDelegate
    
    func controller(_ controller: UDPSocketControllerProtocol, didReceiveResponse response: Data) {
        guard !response.isEmpty,
            let service = parser.parse(response),
            searchedForService(service),
            !servicesFoundDuringSearch.contains(service) else {
                return
        }
        
        os_log(.info, "Received a valid service response")
        
        servicesFoundDuringSearch.append(service)
        
        delegate?.searchSession(self, didFindService: service)
    }
    
    func controller(_ controller: UDPSocketControllerProtocol, didEncounterError error: Error) {
        os_log(.info, "Encountered socket error: \r%{public}@", error.localizedDescription)
        let wrappedError = SSDPSearchSessionError.searchAborted(error)
        delegate?.searchSession(self, didEncounterError: wrappedError)
        close()
    }
    
    private func searchedForService(_ service: SSDPService) -> Bool {
        return service.searchTarget.contains(configuration.searchTarget) || configuration.searchTarget == "ssdp:all"
    }
}
