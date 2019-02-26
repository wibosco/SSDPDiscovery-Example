//
//  SSDPDeviceSearcher.swift
//  SSDP-Example
//
//  Created by William Boles on 17/02/2019.
//  Copyright © 2019 William Boles. All rights reserved.
//

import Foundation
import os

protocol SSDPDeviceSearcherDelegate {
    func didFailSearch(with error: SSDPDeviceSearcherError)
    func didFindDevice(_ response: SSDPSearchResponse)
    func didStopSearching()
    func didTimeout()
}

enum SSDPDeviceSearcherError: Error {
    case unableToCreateSocket
    case searchFailed(Error)
}

class SSDPDeviceSearcher {
    private var socket: SSDPSearchSession?
    private let configuration: SSDPSearchSessionConfiguration
    private var timeoutTimer: Timer?
    
    var delegate: SSDPDeviceSearcherDelegate?
    var isSearching: Bool {
        return socket != nil
    }
    
    // MARK: - Lifecycle
    
    init(configuration: SSDPSearchSessionConfiguration) {
        self.configuration = configuration
    }
    
    deinit {
        destroySocket()
    }
    
    // MARK: - Search
    
    func startSearch() {
        guard !isSearching else {
            return
        }
        
        os_log(.info, "Starting SSDP search")
        
        guard let socket = SSDPSearchSession(configuration: configuration) else {
            self.delegate?.didFailSearch(with: SSDPDeviceSearcherError.unableToCreateSocket)
            return
        }
        
        self.socket = socket
        
        self.socket?.broadcastMulticastSearch(responseHandler: processBroadcastResponse)

        timeoutTimer = Timer.scheduledTimer(withTimeInterval: configuration.searchTimeout, repeats: false, block: { [weak self] (timer) in
            self?.searchTimedOut()
            timer.invalidate()
        })
    }
    
    private func processBroadcastResponse(_ result: Result<SSDPSearchResponse, SSDPSearchSessionError>) {
        switch result {
        case .failure(let error):
            delegate?.didFailSearch(with: SSDPDeviceSearcherError.searchFailed(error))
            destroySocket()
        case .success(let response):
            delegate?.didFindDevice(response)
        }
    }
    
    private func searchTimedOut() {
        if isSearching {
            os_log(.info, "SSDP search timed out")
            destroySocket()
            delegate?.didTimeout()
        }
    }
    
    // MARK: - Stop
    
    private func destroySocket() {
        socket?.close()
        socket = nil
    }
    
    func stopSearch() {
        os_log(.info, "Stopping SSDP search")
        destroySocket()
        timeoutTimer?.invalidate()
        timeoutTimer = nil
        delegate?.didStopSearching()
    }
}
