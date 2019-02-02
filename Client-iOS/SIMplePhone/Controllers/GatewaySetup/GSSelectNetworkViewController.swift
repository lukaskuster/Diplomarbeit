//
//  GSSelectNetworkViewController.swift
//  SIMplePhone
//
//  Created by Lukas Kuster on 01.02.19.
//  Copyright © 2019 Lukas Kuster. All rights reserved.
//

import UIKit
import SwiftyBluetooth
import SIMplePhoneKit

class GSSelectNetworkViewController: UIViewController {
    public var bleGateway: Peripheral?
    public var gateways: [SPGateway]?
    private var availableNetworks = [SPNetwork]()
    
    @IBOutlet weak var headerTitleLabel: UILabel!
    @IBOutlet weak var headerDescLabel: UILabel!
    @IBOutlet weak var networkListTableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.networkListTableView.delegate = self
        self.networkListTableView.dataSource = self
        
        let wifi1 = SPNetwork(ssid: "Ghostpeak", rssi: 80, requiresPassword: true)
        let wifi2 = SPNetwork(ssid: "Wifi Tes 2", rssi: 60, requiresPassword: false)
        self.availableNetworks.append(wifi1)
        self.availableNetworks.append(wifi2)
        self.networkListTableView.reloadData()
        
        if let gateway = self.bleGateway {
            self.loadAvailableNetworks(gateway)
        }
    }
    
    private func loadAvailableNetworks(_ gateway: Peripheral) {
        self.networkListTableView.reloadData()
    }
}

extension GSSelectNetworkViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.availableNetworks.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = self.networkListTableView.dequeueReusableCell(withIdentifier: String(describing: GSSelectNetworkListTableCell.self)) as! GSSelectNetworkListTableCell
        cell.network = self.availableNetworks[indexPath.row]
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let network = self.availableNetworks[indexPath.row]
        if network.requiresPassword {
            let storyboard = UIStoryboard(name: "Setup", bundle: nil)
            let vc = storyboard.instantiateViewController(withIdentifier: String(describing: GSEnterNetworkPasswordViewController.self)) as! GSEnterNetworkPasswordViewController
            vc.network = network
            vc.delegate = self
            let navController = UINavigationController(rootViewController: vc)
            self.present(navController, animated: true, completion: nil)
        }else{
            self.connect(to: network, with: nil)
        }
    }
    
    private func connect(to network: SPNetwork, with password: String?) {
        let storyboard = UIStoryboard(name: "Setup", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: String(describing: GSNameGatewayViewController.self)) as! GSNameGatewayViewController
        let gateway = SPGateway(withIMEI: "82364836462828", name: nil, phoneNumber: nil, colorString: nil, signalStrength: nil, firmwareVersion: nil, carrier: nil)
        if var gateways = self.gateways {
            gateways.append(gateway)
            vc.gateways = gateways
        }else{
            vc.gateways = [gateway]
        }
        self.navigationController?.pushViewController(vc, animated: true)
        
        //        self.setupManager?.connect(to: network, password: password, completion: { error in
        //            if let error = error {
        //                print("setupManager connect error: \(error)")
        //            }
        //            print("connect to wifi")
        //        })
    }
}

extension GSSelectNetworkViewController: GSEnterNetworkPasswordDelegate {
    func enterPasswordViewController(didEnterPassword password: String, for network: SPNetwork) {
        self.connect(to: network, with: password)
    }
}

class GSSelectNetworkListTableCell: UITableViewCell {
    var network: SPNetwork? {
        didSet {
            self.fillCellWithData()
        }
    }
    @IBOutlet weak var networkNameLabel: UILabel!
    @IBOutlet weak var networkPasswordRequiredIndicator: UIImageView!
    @IBOutlet weak var networkSignalStrengthView: UIView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    func fillCellWithData() {
        if let data = self.network {
            self.networkNameLabel.text = data.ssid
            self.networkPasswordRequiredIndicator.isHidden = !data.requiresPassword
            
        }
    }
}
