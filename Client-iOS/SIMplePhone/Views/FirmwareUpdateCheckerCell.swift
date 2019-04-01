//
//  FirmwareUpdateCheckerCell.swift
//  SIMplePhone
//
//  Created by Lukas Kuster on 10.01.19.
//  Copyright © 2019 Lukas Kuster. All rights reserved.
//

import UIKit
import Static
import SIMplePhoneKit

class FirmwareUpdateCheckerCell: UITableViewCell, Cell {
    var gateway: SPGateway?
    
    private enum FirmwareState {
        case updateAvailable(version: String)
        case upToDate
        case couldNotFetch
    }
    
    public override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: .default, reuseIdentifier: reuseIdentifier)
    }
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    func configure(row: Row) {
        textLabel?.text = row.text
        textLabel?.textColor = tintColor
        if let gateway = row.context?["gateway"] as! SPGateway? {
            self.gateway = gateway
        }
    }
    
    open override func tintColorDidChange() {
        super.tintColorDidChange()
        textLabel?.textColor = tintColor
    }
    
    private func fetchInformation() {
        textLabel?.textColor = .gray
        let activityIndicator = UIActivityIndicatorView(style: .gray)
        self.accessoryView = activityIndicator
        activityIndicator.startAnimating()
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            self.accessoryView = nil
            self.tintColorDidChange()
            self.respondInterface(to: .updateAvailable(version: "0.1.1"))
        }
    }
    
    private func respondInterface(to state: FirmwareState) {
        if let vc = self.findViewController() {
            let alert = UIAlertController(title: nil, message: nil, preferredStyle: .alert)
            switch state {
            case .updateAvailable(version: let version):
                alert.title = "Update available"
                alert.message = "There is a firmware update available (\(version)). Do you want to update?"
                alert.addAction(UIAlertAction(title: "Update now", style: .default, handler: { _ in
                    let statusVC = SettingsGatewayFirmwareUpdateStatusViewController(gateway: self.gateway, to: version)
                    vc.present(statusVC, animated: true, completion: nil)
                }))
                alert.addAction(UIAlertAction(title: "Schedule for tonight (23:30-03:30)", style: .default, handler: { _ in
                    print("schedule update")
                }))
                alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            case .upToDate:
                alert.title = "The gateway is up-to-date"
                alert.message = "Normally the gateway checks if there is an update available by itself. So there is no need to check manually over here."
                alert.addAction(UIAlertAction(title: "Okay", style: .cancel, handler: nil))
            case .couldNotFetch:
                alert.title = "An error occured"
                alert.message = "The gateway wasn't able to connect with the update servers, please try again later."
                alert.addAction(UIAlertAction(title: "Okay", style: .cancel, handler: nil))
            }
            vc.present(alert, animated: true, completion: nil)
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        if (touches.first != nil) {
            self.fetchInformation()
        }
    }
}
