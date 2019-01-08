//
//  SettingsGatewayViewController.swift
//  SIMplePhone
//
//  Created by Lukas Kuster on 12.12.18.
//  Copyright © 2018 Lukas Kuster. All rights reserved.
//

import UIKit
import Static
import SIMplePhoneKit
import SwiftMessages

class SettingsGatewayViewController: TableViewController {
    var gateway: SPGateway
    
    init(gateway: SPGateway) {
        self.gateway = gateway
        super.init(style: .grouped)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = gateway.name
        
        self.tableView.rowHeight = 50
        
        self.dataSource = DataSource(tableViewDelegate: self)
        
        let phoneNumber = gateway.phoneNumber == nil ? "N/A" : SPNumber(withNumber: gateway.phoneNumber!).prettyPhoneNumber()
        let signal = gateway.signalStrength == nil ? "N/A" : "\(String(format: "%.0f", gateway.signalStrength!*100))%"
        let colorView: UIView = {
            let view = UIView(frame: CGRect(x: 0, y: 0, width: 27, height: 27))
            view.backgroundColor = gateway.color ?? .lightGray
            view.layer.cornerRadius = view.frame.width/2
            return view
        }()
        
        self.dataSource.sections = [
            Section(header: "Gateway",
                    rows: [
                Row(text: "Name", detailText: gateway.name, selection: {
                    let alert = UIAlertController(title: nil, message: self.gateway.imei, preferredStyle: .alert)
                    alert.addTextField(configurationHandler: { (textfield) in
                        textfield.placeholder = self.gateway.name
                    })
                    alert.addAction(UIAlertAction(title: "Save", style: .default, handler: { (alert2) in
                        if let name = alert.textFields?.first?.text {
                            if name != self.gateway.name {
                                SPManager.shared.updateGatewayName(name, of: self.gateway, completion: { (success, error) in
                                    if success {
                                        self.gateway.name = name
                                        DispatchQueue.main.async {
                                            self.dataSource.sections[0].rows[0].detailText = name
                                            self.title = name
                                        }
                                    }
                                })
                            }
                        }
                    }))
                    alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
                    self.present(alert, animated: true, completion: nil)
                }, accessory: .disclosureIndicator, cellClass: Value1Cell.self),
                Row(text: "Color", selection: {
                    let vc = SettingsGatewayColorViewController(color: self.gateway.color)
                    vc.delegate = self
                    self.navigationController?.pushViewController(vc, animated: true)
                }, accessory: .view(colorView)),
                Row(text: "Number", detailText: phoneNumber, cellClass: Value1Cell.self),
                Row(text: "Carrier", detailText: gateway.carrier ?? "N/A", cellClass: Value1Cell.self),
                Row(text: "Signal", detailText: signal, cellClass: Value1Cell.self),
                Row(text: "Firmware", detailText: gateway.firmwareVersion ?? "N/A", cellClass: Value1Cell.self),
                Row(text: "IMEI", detailText: gateway.imei, selection: {
                    let alert = UIAlertController(title: nil, message: self.gateway.imei, preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "Hide", style: .cancel, handler: nil))
                    self.present(alert, animated: true, completion: nil)
                }, cellClass: Value1Cell.self),
                ]),
            Section(rows: [
                Row(text: "Change SIM Pin", selection: {
                    
                }, cellClass: ButtonCell.self)
                ]),
            Section(rows: [
                Row(text: "Check for firmware update", selection: {
                    
                }, cellClass: ButtonCell.self)
                ]),
            Section(rows: [
                Row(text: "Factory reset gateway", selection: {
                    
                }, cellClass: DestructiveButtonCell.self)
                ])
        ]
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.navigationController?.navigationBar.prefersLargeTitles = false
        self.navigationController?.navigationItem.largeTitleDisplayMode = .never
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}

extension SettingsGatewayViewController: UITableViewDelegate {
    
}

extension SettingsGatewayViewController: SettingsGatewayColorViewControllerDelegate {
    func gatewayColorDidChange(to newColor: UIColor) {
        SPManager.shared.updateGatewayColor(newColor, of: self.gateway) { (success, error) in
            if success {
                self.gateway.color = newColor
                DispatchQueue.main.async {
                    let colorView: UIView = {
                        let view = UIView(frame: CGRect(x: 0, y: 0, width: 27, height: 27))
                        view.backgroundColor = newColor
                        view.layer.cornerRadius = view.frame.width/2
                        return view
                    }()
                    self.dataSource.sections[0].rows[1].accessory = .view(colorView)
                }
            }
        }
    }
}
