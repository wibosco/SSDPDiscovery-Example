//
//  SSDPDeviceSearcher.swift
//  SSDP-Example
//
//  Created by William Boles on 17/02/2019.
//  Copyright © 2019 William Boles. All rights reserved.
//

import Foundation
import os

protocol SSDPSearcherObserver: class {
    func searcher(_ searcher: SSDPSearcher, didFindService service: SSDPService)
    func searcher(_ searcher: SSDPSearcher, didAbortWithError error: SSDPSearcherError)
    func searcherDidStopSearch(_ searcher: SSDPSearcher, foundServices: [SSDPService])
}

enum SSDPSearcherError: Error {
    case unableToOpenSearchSession
    case searchFailed(Error)
}

class SSDPSearcher: SSDPSearchSessionDelegate {
    private var searchSession: SSDPSearchSession?
    private let configuration: SSDPSearchSessionConfiguration
    private let observers = NSHashTable<AnyObject>.weakObjects()
    
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
    
    // MARK: - Observers
    
    func add(observer: SSDPSearcherObserver) {
        if !observers.contains(observer) {
            observers.add(observer)
        }
    }
    
    func remove(observer: SSDPSearcherObserver) {
        observers.remove(observer)
    }
    
    private func notifyObserversOfSearchAbortion(withError error: SSDPSearcherError) {
        for case let observer as SSDPSearcherObserver in observers.allObjects {
            observer.searcher(self, didAbortWithError: error)
        }
    }
    
    private func notifyObserversOfServiceFound(_ service: SSDPService) {
        for case let observer as SSDPSearcherObserver in observers.allObjects {
            observer.searcher(self, didFindService: service)
        }
    }
    
    private func notifyObserversOfSearchEnded(withServicesFound services: [SSDPService]) {
        for case let observer as SSDPSearcherObserver in observers.allObjects {
            observer.searcherDidStopSearch(self, foundServices: services)
        }
    }
    
    // MARK: - Search
    
    func startSearch() {
        guard !isSearching else {
            return
        }
        
        os_log(.info, "Starting SSDP search")
        
        guard let searchSession = SSDPSearchSession(configuration: configuration) else {
            notifyObserversOfSearchAbortion(withError: SSDPSearcherError.unableToOpenSearchSession)
            return
        }
        
        self.searchSession = searchSession
        self.searchSession?.delegate = self
        self.searchSession?.startSearch()
    }
    
    private func stopExistingSearchSession() {
        searchSession?.stopSearch()
        searchSession = nil
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
        
        notifyObserversOfSearchAbortion(withError: SSDPSearcherError.searchFailed(error))
        
        stopExistingSearchSession()
    }
    
    func searchSession(_ searchSession: SSDPSearchSession, didFindService service: SSDPService) {
        guard self.searchSession === searchSession else {
            return
        }
        
        notifyObserversOfServiceFound(service)
    }
    
    func searchSessionDidStopSearch(_ searchSession: SSDPSearchSession, foundServices: [SSDPService]) {
        guard self.searchSession === searchSession else {
            return
        }
        
        notifyObserversOfSearchEnded(withServicesFound: foundServices)
        stopExistingSearchSession()
    }
}
