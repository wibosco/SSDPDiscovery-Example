//
//  ViewController.swift
//  SSDP-Example
//
//  Created by William Boles on 16/02/2019.
//  Copyright © 2019 William Boles. All rights reserved.
//

import UIKit

class ViewController: UIViewController, SSDPDeviceSearcherDelegate {
    
    @IBOutlet var searchButton: UIButton!
    @IBOutlet var searchingActivityIndicator: UIActivityIndicatorView!
    
    private var searcher: SSDPDeviceSearcher?
    
    // MARK: - ViewLifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let config = SSDPSearchSessionConfiguration(searchTarget: "ssdp:all", maximumWaitResponseTime: 2, searchTimeout: 8)
        searcher = SSDPDeviceSearcher(configuration: config)
        searcher?.delegate = self
    }

    // MARK: - ButtonActions
    
    @IBAction func searchButtonPressed(_ sender: Any) {
        toggleSearchingUI()
        searcher?.startSearch()
    }
    
    private func toggleSearchingUI() {
        DispatchQueue.main.async {
            self.searchButton.isHidden.toggle()
            
            if self.searchingActivityIndicator.isAnimating {
                self.searchingActivityIndicator.stopAnimating()
            } else {
                self.searchingActivityIndicator.startAnimating()
            }
        }
    }
    
    // MARK: - SSDPDeviceSearcherDelegate
    
    func didFailSearch(with error: SSDPDeviceSearcherError) {
        toggleSearchingUI()
    }
    
    func didFindDevice(_ response: SSDPSearchResponse) {
        //Respond to found device
//        searcher?.stopSearch()
    }
    
    func didStopSearching() {
        toggleSearchingUI()
    }
    
    func didTimeout() {
        toggleSearchingUI()
    }
}
