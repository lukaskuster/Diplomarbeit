//
//  GSSelectNetworkViewController.swift
//  SIMplePhone
//
//  Created by Lukas Kuster on 01.02.19.
//  Copyright © 2019 Lukas Kuster. All rights reserved.
//

import UIKit
import SIMplePhoneKit

class GSSelectNetworkViewController: UIViewController {
    public var gateways: [SPGateway]?
    private var availableNetworks = [SPNetwork]()
    public var blesetupmanager: BLESetupManager?
    
    @IBOutlet weak var headerTitleLabel: UILabel!
    @IBOutlet weak var headerDescLabel: UILabel!
    @IBOutlet weak var networkListTableView: UITableView!
    let refreshControl: UIRefreshControl = {
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(refreshTableView), for: .valueChanged)
        refreshControl.attributedTitle = NSAttributedString(string: "Fetching available networks")
        return refreshControl
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.networkListTableView.delegate = self
        self.networkListTableView.dataSource = self
        self.networkListTableView.separatorStyle = .none
        self.networkListTableView.addSubview(self.refreshControl)
        
        self.blesetupmanager?.delegate = self
        self.loadAvailableNetworks()
    }
    
    @objc private func refreshTableView() {
        self.loadAvailableNetworks(isTableRefresh: true)
    }
    
    private func loadAvailableNetworks(isTableRefresh: Bool = false) {
        self.blesetupmanager?.getAvailableNetworks(completion: { (networks, error) in
            guard let networks = networks else {
                if let error = error {
                    print("error while loading networks \(error)")
                }
                return
            }
            self.availableNetworks = networks
            if isTableRefresh {
                self.refreshControl.endRefreshing()
            }
            self.networkListTableView.reloadData()
        })
    }
}

extension GSSelectNetworkViewController: UITableViewDelegate, UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return self.availableNetworks.count
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        let height: CGFloat = section == 0 ? 0.0 : 10.0
        return height
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView = UIView()
        headerView.backgroundColor = UIColor.clear
        return headerView
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = self.networkListTableView.dequeueReusableCell(withIdentifier: String(describing: GSSelectNetworkListTableCell.self)) as! GSSelectNetworkListTableCell
        cell.network = self.availableNetworks[indexPath.section]
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let network = self.availableNetworks[indexPath.section]
        if network.requiresPassword {
            let vc = self.enterPasswordVC(for: network)
            self.present(vc, animated: true, completion: nil)
        }else{
            self.connect(to: network, with: nil)
        }
    }
    
    private func connect(to network: SPNetwork, with password: String?) {
        self.blesetupmanager?.connect(to: network, password: password)
    }
    
    private func didConnectToNetwork(withGateway imei: String) {
        SPManager.shared.getGateway(withImei: imei) { (gateway, error) in
            if let error = error {
                print("error while connecting gateway to network: \(error)")
            }
            guard let gateway = gateway else { return }
            self.finishedGatewayNetworkConnect(with: gateway)
        }
    }
    
    private func enterPasswordVC(for network: SPNetwork, wrongPassword: Bool = false) -> UINavigationController {
        let storyboard = UIStoryboard(name: "Setup", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: String(describing: GSEnterNetworkPasswordViewController.self)) as! GSEnterNetworkPasswordViewController
        vc.network = network
        vc.delegate = self
        vc.wrongPassword = wrongPassword
        let navController = UINavigationController(rootViewController: vc)
        return navController
    }
    
    private func finishedGatewayNetworkConnect(with gateway: SPGateway) {
        let storyboard = UIStoryboard(name: "Setup", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: String(describing: GSNameGatewayViewController.self)) as! GSNameGatewayViewController
        if var gateways = self.gateways {
            gateways.append(gateway)
            vc.gateways = gateways
        }else{
            vc.gateways = [gateway]
        }
        self.navigationController?.pushViewController(vc, animated: true)
    }
}

extension GSSelectNetworkViewController: GSEnterNetworkPasswordDelegate {
    func enterPasswordViewController(didEnterPassword password: String, for network: SPNetwork) {
        self.connect(to: network, with: password)
    }
}

extension GSSelectNetworkViewController: BLESetupManagerDelegate {
    func blesetup(manager: BLESetupManager,
                  didChangeConnectionStatus status: BLESetupManager.Status,
                  with network: SPNetwork) {
        switch status {
        case .connecting:
            if let section = self.availableNetworks.firstIndex(of: network),
                let cell = self.networkListTableView.cellForRow(at: IndexPath(row: 0, section: section)) as? GSSelectNetworkListTableCell {
                cell.connecting()
            }
        case .wrongPSK:
            let vc = self.enterPasswordVC(for: network, wrongPassword: true)
            self.present(vc, animated: true, completion: nil)
        case .connected(let imei):
            self.didConnectToNetwork(withGateway: imei)
        }
    }
    
    func blesetup(manager: BLESetupManager, didReceiveError error: Error) {
        print("got error \(error)")
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
        self.backgroundColor = .tableViewBackground
        self.layer.cornerRadius = 5.0
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    public func connecting() {
        self.networkSignalStrengthView.backgroundColor = .purple
    }
    
    func fillCellWithData() {
        if let data = self.network {
            self.networkNameLabel.text = data.ssid
            self.networkPasswordRequiredIndicator.isHidden = !data.requiresPassword
        }
    }
}
