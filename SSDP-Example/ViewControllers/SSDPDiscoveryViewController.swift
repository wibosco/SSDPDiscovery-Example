//
//  ViewController.swift
//  SSDP-Example
//
//  Created by William Boles on 16/02/2019.
//  Copyright © 2019 William Boles. All rights reserved.
//

import UIKit

class SSDPDiscoveryViewController: UIViewController, SSDPDeviceSearcherDelegate, UITableViewDataSource {
    @IBOutlet var searchButton: UIButton!
    @IBOutlet var searchingActivityIndicator: UIActivityIndicatorView!
    @IBOutlet var tableView: UITableView!
    
    private var searcher: SSDPDeviceSearcher?
    
    private var responses = [SSDPSearchResponse]()
    
    // MARK: - ViewLifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let config = SSDPSearchSessionConfiguration(searchTarget: "ssdp:all", maximumWaitResponseTime: 2, searchTimeout: 8)
        searcher = SSDPDeviceSearcher(configuration: config)
        searcher?.delegate = self
    }

    // MARK: - ButtonActions
    
    @IBAction func searchButtonPressed(_ sender: Any) {
        responses.removeAll()
        tableView.reloadData()
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
        DispatchQueue.main.async {
            self.responses.append(response)
            self.tableView.reloadData()
        }
    }
    
    func didStopSearching() {
        toggleSearchingUI()
    }
    
    func didTimeout() {
        toggleSearchingUI()
    }
    
    // MARK: - UITableViewDataSource
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return responses.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let response = responses[indexPath.row]
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "SSDPResponseTableViewCell", for: indexPath) as! SSDPResponseTableViewCell
        cell.configure(response)
        
        return cell
    }
}
