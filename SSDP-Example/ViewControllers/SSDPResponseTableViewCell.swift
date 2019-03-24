//
//  SSDPResponseTableViewCell.swift
//  SSDP-Example
//
//  Created by William Boles on 26/02/2019.
//  Copyright © 2019 William Boles. All rights reserved.
//

import UIKit
import Foundation

class SSDPResponseTableViewCell: UITableViewCell {
    @IBOutlet var cacheControlValueLabel: UILabel!
    @IBOutlet var locationValueLabel: UILabel!
    @IBOutlet var serverValueLabel: UILabel!
    @IBOutlet var searchTargetValueLabel: UILabel!
    @IBOutlet var usnValueLabel: UILabel!
    @IBOutlet var otherHeadersValueLabel: UILabel!
    
    private static var dateFormatter: DateFormatter {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .short
        dateFormatter.timeStyle = .short
        
        return dateFormatter
    }
    
    // MARK: - Reuse
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        cacheControlValueLabel.text = nil
        locationValueLabel.text = nil
        serverValueLabel.text = nil
        searchTargetValueLabel.text = nil
        usnValueLabel.text = nil
        otherHeadersValueLabel.text = nil
    }
    
    // MARK: - Configure
    
    func configure(_ response: SSDPService) {
        cacheControlValueLabel.text = SSDPResponseTableViewCell.dateFormatter.string(from: response.cacheControl)
        locationValueLabel.text = response.location.absoluteString
        serverValueLabel.text = response.server
        searchTargetValueLabel.text = response.searchTarget
        usnValueLabel.text = response.uniqueServiceName
        otherHeadersValueLabel.text = response.otherHeaders.description
    }
}
