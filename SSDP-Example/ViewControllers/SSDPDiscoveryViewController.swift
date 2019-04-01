//
//  ViewController.swift
//  SSDP-Example
//
//  Created by William Boles on 16/02/2019.
//  Copyright © 2019 William Boles. All rights reserved.
//

import UIKit

class SSDPDiscoveryViewController: UIViewController, SSDPSearchSessionDelegate, UITableViewDataSource {
    @IBOutlet var searchButton: UIButton!
    @IBOutlet var searchingActivityIndicator: UIActivityIndicatorView!
    @IBOutlet var tableView: UITableView!
    
    private var searchSession: SSDPSearchSession?
    
    private var servicesFound = [SSDPService]()

    // MARK: - ButtonActions
    
    @IBAction func searchButtonPressed(_ sender: Any) {
        servicesFound.removeAll()
        tableView.reloadData()
        toggleSearchingUI()
        
        let configuration = SSDPSearchSessionConfiguration.createMulticastConfiguration(forSearchTarget: "ssdp:all")
        searchSession = SSDPSearchSession(configuration: configuration)
        searchSession?.delegate = self
        searchSession?.startSearch()
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
    
    // MARK: - SSDPSearchSessionDelegate
    
    func searchSession(_ searchSession: SSDPSearchSession, didFindService service: SSDPService) {
        guard self.searchSession === searchSession else {
            return
        }
        
        DispatchQueue.main.async {
            self.servicesFound.insert(service, at: 0)
            self.tableView.insertRows(at: [IndexPath(row: 0, section: 0)], with: .top)
        }
    }
    
    func searchSession(_ searchSession: SSDPSearchSession, didAbortWithError error: SSDPSearchSessionError) {
        guard self.searchSession === searchSession else {
            return
        }
        
        toggleSearchingUI()
    }
    
    func searchSessionDidStopSearch(_ searchSession: SSDPSearchSession, foundServices: [SSDPService]) {
        guard self.searchSession === searchSession else {
            return
        }
        
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
