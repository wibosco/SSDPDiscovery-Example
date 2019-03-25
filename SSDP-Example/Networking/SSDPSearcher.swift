//
//  SSDPDeviceSearcher.swift
//  SSDP-Example
//
//  Created by William Boles on 17/02/2019.
//  Copyright © 2019 William Boles. All rights reserved.
//

import Foundation
import os

protocol SSDPSearcherDelegate: class {
    func searcher(_ searcher: SSDPSearcher, didAbortWithError error: SSDPSearcherError)
    func searcher(_ searcher: SSDPSearcher, didFindService service: SSDPService)
    func searcherDidStopSearch(_ searcher: SSDPSearcher)
}

enum SSDPSearcherError: Error {
    case unableToOpenSearchSession
    case searchFailed(Error)
}

class SSDPSearcher: SSDPSearchSessionDelegate {
    private var searchSession: SSDPSearchSession?
    private let configuration: SSDPSearchSessionConfiguration
    private var timeoutTimer: Timer?
    
    weak var delegate: SSDPSearcherDelegate?
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
            delegate?.searcher(self, didAbortWithError: SSDPSearcherError.unableToOpenSearchSession)
            return
        }
        
        self.searchSession = searchSession
        self.searchSession?.delegate = self
        self.searchSession?.startSearch()

        timeoutTimer = Timer.scheduledTimer(withTimeInterval: (configuration.searchTimeout + 0.1), repeats: false, block: { [weak self] (timer) in
            os_log(.info, "SSDP search timed out")
            self?.stopExistingSearchSession()
        })
    }
    
    private func stopExistingSearchSession() {
        searchSession?.stopSearch()
        searchSession = nil
        timeoutTimer?.invalidate()
        timeoutTimer = nil
    }
    
    func stopSearch() {
        os_log(.info, "Stopping SSDP search")
        stopExistingSearchSession()
    }
    
    // MARK: - SSDPSearchSessionDelegate
    
    func searchSession(_ searchSession: SSDPSearchSession, didAbortWithError error: SSDPSearchSessionError) {
        guard self.searchSession === searchSession else {
            return
        }
        
        delegate?.searcher(self, didAbortWithError: SSDPSearcherError.searchFailed(error))
        stopExistingSearchSession()
    }
    
    func searchSession(_ searchSession: SSDPSearchSession, didFindService service: SSDPService) {
        guard self.searchSession === searchSession else {
            return
        }
        
        delegate?.searcher(self, didFindService: service)
    }
    
    func searchSessionDidStopSearch(_ searchSession: SSDPSearchSession) {
        guard self.searchSession === searchSession else {
            return
        }
        
        delegate?.searcherDidStopSearch(self)
    }
}
