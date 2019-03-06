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
        
        self.dataSource.sections = [
            Section(header: "Gateway",
                    rows: [
                Row(text: "Name", detailText: gateway.name, selection: {
                    let vc = SettingsGatewayNameViewController(name: self.gateway.name)
                    vc.delegate = self
                    self.navigationController?.pushViewController(vc, animated: true)
                }, accessory: .disclosureIndicator, cellClass: Value1Cell.self),
                Row(text: "Color", selection: {
                    let vc = SettingsGatewayColorViewController(color: self.gateway.color)
                    vc.delegate = self
                    self.navigationController?.pushViewController(vc, animated: true)
                }, accessory: .disclosureIndicator, cellClass: ColorPreviewCell.self,
                   context: ["color": self.gateway.color ?? .lightGray]),
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
                    let vc = SettingsGatewayChangeSIMPinViewController(gateway: self.gateway)
                    self.navigationController?.pushViewController(vc, animated: false)
                }, cellClass: ButtonCell.self),
                Row(text: "Check for firmware update", cellClass: FirmwareUpdateCheckerCell.self,
                    context: ["gateway": self.gateway])
                ]),
            Section(rows: [
                Row(text: "Factory reset gateway", selection: {
                    
                }, cellClass: DestructiveButtonCell.self)
                ]),
            Section(header: "Testing", rows: [
                Row(text: "WebRTC Test", selection: {
                    let storyboard = UIStoryboard(name: "Call", bundle: nil)
                    let controller = storyboard.instantiateViewController(withIdentifier: "WebRTCTest") as! WebRTCTestViewController
                    controller.gateway = self.gateway
                    self.navigationController?.pushViewController(controller, animated: true)
                }, accessory: .disclosureIndicator)])
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

class ColorPreviewCell: UITableViewCell, Cell {
    private var color: UIColor?
    private var colorView: UIView?
    
    public override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: .default, reuseIdentifier: reuseIdentifier)
    }
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    func configure(row: Row) {
        if let color = row.context?["color"] as! UIColor? {
            self.color = color
        }
        textLabel?.text = row.text
        accessoryType = row.accessory.type
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        if let colorView = self.colorView {
            colorView.backgroundColor = self.color
        }else{
            let view = UIView(frame: CGRect(x: self.frame.width-60, y: (self.frame.height/2)-13.5, width: 27, height: 27))
            view.backgroundColor = self.color
            view.layer.cornerRadius = view.frame.width/2
            self.colorView = view
            self.addSubview(view)
        }
    }
    
    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        let color = colorView?.backgroundColor
        super.setHighlighted(highlighted, animated: animated)
        if highlighted {
            colorView?.backgroundColor = color
        }
    }
}

extension SettingsGatewayViewController: SettingsGatewayColorViewControllerDelegate, SettingsGatewayNameViewControllerDelegate {
    func gatewayNameDidChange(to newName: String) {
        SPManager.shared.updateGatewayName(newName, of: self.gateway) { error in
            if let error = error {
                SPDelegate.shared.display(error: error)
                return
            }
            DispatchQueue.main.async {
                self.dataSource.sections[0].rows[0].detailText = self.gateway.name
                self.title = self.gateway.name
            }
        }
    }
    
    func gatewayColorDidChange(to newColor: UIColor) {
        SPManager.shared.updateGatewayColor(newColor, of: self.gateway) { error in
            if let error = error {
                SPDelegate.shared.display(error: error)
                return
            }
            DispatchQueue.main.async {
                self.dataSource.sections[0].rows[1].context?["color"] = self.gateway.color
            }
        }
    }
}
