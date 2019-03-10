//
//  SSDPDeviceSearcher.swift
//  SSDP-Example
//
//  Created by William Boles on 17/02/2019.
//  Copyright © 2019 William Boles. All rights reserved.
//

import Foundation
import os

protocol SSDPSearcherDelegate {
    func didStopSearch(with error: SSDPSearcherError)
    func didReceiveSearchResponse(_ response: SSDPSearchResponse)
    func didTimeout()
}

enum SSDPSearcherError: Error {
    case unableToOpenSearchSession
    case searchFailed(Error)
}

class SSDPSearcher: SSDPSearchSessionDelegate {
    private var searchSession: SSDPSearchSession?
    private let configuration: SSDPSearchSessionConfiguration
    private var timeoutTimer: Timer?
    
    var delegate: SSDPSearcherDelegate?
    var isSearching: Bool {
        return searchSession != nil
    }
    
    // MARK: - Lifecycle
    
    init(configuration: SSDPSearchSessionConfiguration) {
        self.configuration = configuration
    }
    
    deinit {
        stopExistingSearchSession()
    }
    
    // MARK: - Search
    
    func startSearch() {
        guard !isSearching else {
            return
        }
        
        os_log(.info, "Starting SSDP search")
        
        guard let searchSession = SSDPSearchSession(configuration: configuration) else {
            self.delegate?.didStopSearch(with: SSDPSearcherError.unableToOpenSearchSession)
            return
        }
        
        self.searchSession = searchSession
        self.searchSession?.delegate = self
        self.searchSession?.start()

        timeoutTimer = Timer.scheduledTimer(withTimeInterval: configuration.searchTimeout, repeats: false, block: { [weak self] (timer) in
            self?.searchTimedOut()
            timer.invalidate()
        })
    }
    
    private func searchTimedOut() {
        if isSearching {
            os_log(.info, "SSDP search timed out")
            stopExistingSearchSession()
            delegate?.didTimeout()
        }
    }
    
    // MARK: - SSDPSearchSessionDelegate
    
    func didReceiveSearchResponse(_ response: SSDPSearchResponse) {
        delegate?.didReceiveSearchResponse(response)
    }
    
    func didStopSearch(with error: SSDPSearchSessionError) {
        delegate?.didStopSearch(with: SSDPSearcherError.searchFailed(error))
        stopExistingSearchSession()
    }
    
    // MARK: - Stop
    
    private func stopExistingSearchSession() {
        searchSession?.stop()
        searchSession = nil
    }
    
    func stopSearch() {
        os_log(.info, "Stopping SSDP search")
        stopExistingSearchSession()
        timeoutTimer?.invalidate()
        timeoutTimer = nil
    }
}
