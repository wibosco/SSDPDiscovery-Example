//
//  ViewController.swift
//  SSDP-Example
//
//  Created by William Boles on 16/02/2019.
//  Copyright © 2019 William Boles. All rights reserved.
//

import UIKit

class SSDPDiscoveryViewController: UIViewController, SSDPSearcherObserver, UITableViewDataSource {
    @IBOutlet var searchButton: UIButton!
    @IBOutlet var searchingActivityIndicator: UIActivityIndicatorView!
    @IBOutlet var tableView: UITableView!
    
    private var searcher: SSDPSearcher?
    
    private var servicesFound = [SSDPService]()
    
    // MARK: - ViewLifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let config = SSDPSearchSessionConfiguration(searchTarget: "ssdp:all", maximumWaitResponseTime: 3, searchTimeout: 9)
        searcher = SSDPSearcher(configuration: config)
        searcher?.add(observer: self)
    }

    // MARK: - ButtonActions
    
    @IBAction func searchButtonPressed(_ sender: Any) {
        servicesFound.removeAll()
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
    
    // MARK: - SSDPSearcherObserver
    
    func searcher(_ searcher: SSDPSearcher, didAbortWithError error: SSDPSearcherError) {
        toggleSearchingUI()
    }
    
    func searcher(_ searcher: SSDPSearcher, didFindService service: SSDPService) {
        DispatchQueue.main.async {
            self.servicesFound.insert(service, at: 0)
            self.tableView.insertRows(at: [IndexPath(row: 0, section: 0)], with: .top)
        }
    }
    
    func searcherDidStopSearch(_ searcher: SSDPSearcher, foundServices: [SSDPService]) {
        toggleSearchingUI()
    }
    
    // MARK: - UITableViewDataSource
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return servicesFound.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let response = servicesFound[indexPath.row]
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "SSDPResponseTableViewCell", for: indexPath) as! SSDPResponseTableViewCell
        cell.configure(response)
        
        return cell
    }
}
