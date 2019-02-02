//
//  SettingsViewController.swift
//  SIMplePhone
//
//  Created by Lukas Kuster on 29.11.18.
//  Copyright © 2018 Lukas Kuster. All rights reserved.
//

import UIKit
import MessageUI
import Static
import SwiftyAcknowledgements
import SIMplePhoneKit
import SwiftMessages
import SafariServices

class SettingsViewController: TableViewController {
    let refreshControl = UIRefreshControl()
    var gatewayCollectionView: GatewayCollectionView?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Settings"
        
        self.tableView.rowHeight = 50
        
        
        self.refreshControl.attributedTitle = NSAttributedString(string: "Pull to refresh")
        self.refreshControl.addTarget(self, action: #selector(refreshGateways), for: .valueChanged)
        self.tableView.addSubview(refreshControl)
        
        self.navigationController?.navigationBar.prefersLargeTitles = true
        self.navigationController?.navigationItem.largeTitleDisplayMode = .automatic
        
        let year = Calendar.current.component(.year, from: Date())
        
        self.tableView.showsVerticalScrollIndicator = false
        
        self.dataSource = DataSource(tableViewDelegate: self)
        
        self.gatewayCollectionView = GatewayCollectionView()
        self.gatewayCollectionView?.delegate = self
        let gatewaySection = Section(header: Section.Extremity.autoLayoutView(self.gatewayCollectionView!))

        self.dataSource.sections = [
            gatewaySection,
            Section(rows: [
                Row(text: "Account", selection: {
                    let vc = SettingsAccountViewController()
                    self.navigationController?.pushViewController(vc, animated: true)
                }, image: #imageLiteral(resourceName: "settings-account"), accessory: .disclosureIndicator),
                Row(text: "Messages", selection: {
                    
                }, image: #imageLiteral(resourceName: "settings-messages"), accessory: .disclosureIndicator),
                Row(text: "Notifications", selection: {
                    
                }, image: #imageLiteral(resourceName: "settings-notifications"), accessory: .disclosureIndicator)
                ]),
            Section(rows: [
                Row(text: "Contact", selection: {
                    if MFMailComposeViewController.canSendMail() {
                        let mail = MFMailComposeViewController()
                        mail.setToRecipients(["mail@lukaskuster.com"])
                        mail.setSubject("SIMple Phone Contact")
                        mail.title = "Contact"
                        mail.mailComposeDelegate = self
                        self.present(mail, animated: true, completion: {
                            mail.becomeFirstResponder()
                        })
                    }else{
                        let email = "mail@lukaskuster.com"
                        let url = URL(string: "mailto:\(email)?subject=SIMple%20Phone%20Contact")
                        UIApplication.shared.open(url!, options: [:], completionHandler: nil)
                    }
                }, image: #imageLiteral(resourceName: "settings-contact"), accessory: .disclosureIndicator),
                Row(text: "Licenses", selection: {
                    let vc = AcknowledgementsTableViewController(acknowledgementsPlistPath: Bundle.main.path(forResource: "Acknowledgements", ofType: "plist"))
                    vc.title = "Licenses"
                    vc.headerText = "This app uses several third-party software frameworks, which we would like to acknowledge."
                    self.navigationController?.pushViewController(vc, animated: true)
                }, image: #imageLiteral(resourceName: "settings-licenses"), accessory: .disclosureIndicator)]),
            Section(rows: [
                Row(text: "Order a gateway", selection: {
                    if let url = URL(string: "https://lukaskuster.com/order-gateway/") {
                        let vc = SFSafariViewController(url: url)
                        self.present(vc, animated: true, completion: nil)
                    }
                }, image: #imageLiteral(resourceName: "settings-order"), accessory: .disclosureIndicator)],
                footer: Section.Extremity.init(stringLiteral: "© \(year) Lukas Kuster. All rights reserved."))
            ]
        
    }
    
    @objc func refreshGateways() {
        self.gatewayCollectionView?.loadGateways(completion: { (error) in
            self.refreshControl.endRefreshing()
        })
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.navigationController?.navigationBar.prefersLargeTitles = true
        self.navigationController?.navigationItem.largeTitleDisplayMode = .automatic
        self.gatewayCollectionView?.loadGateways(completion: { (error) in
        })
    }
    
    required init?(coder aDecoder: NSCoder) {
        let ibvc = UIViewController(coder: aDecoder)!
        super.init(style: .grouped)
        ibvc.parent?.addChild(self)
    }
}

extension SettingsViewController: UITableViewDelegate {
    
}

extension SettingsViewController: GatewayCollectionDelegate {
    func gatewayCollection(didSelectGateway gateway: SPGateway) {
        let vc = SettingsGatewayViewController(gateway: gateway)
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    func gatewayCollection(requestsGatewaySetup bool: Bool) {
        let storyboard = UIStoryboard(name: "Setup", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: String(describing: GSSearchingForGatewayViewController.self))
        let setupNavController = UINavigationController(rootViewController: vc)
        setupNavController.isNavigationBarHidden = true
        setupNavController.isToolbarHidden = true
        self.present(setupNavController, animated: true, completion: nil)
    }
}

extension SettingsViewController: MFMailComposeViewControllerDelegate {
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.dismiss(animated: true, completion: nil)
    }
}
