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
        let gatewaySection = Section(header: Section.Extremity.autoLayoutView(self.gatewayCollectionView!), footer: Section.Extremity.init(stringLiteral: "Tap a gateway to change its configuration."))

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
                }, image: #imageLiteral(resourceName: "settings-licenses"), accessory: .disclosureIndicator)],
                footer: Section.Extremity.init(stringLiteral: "© \(year) Lukas Kuster. All rights reserved.")),
            Section(header: "Testing", rows: [
                Row(text: "WebRTC Test", selection: {
                    let storyboard = UIStoryboard(name: "Main", bundle: nil)
                    let controller = storyboard.instantiateViewController(withIdentifier: "WebRTCTest")
                    self.navigationController?.pushViewController(controller, animated: true)
                }, accessory: .disclosureIndicator)])
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
        let messageView: MessageView = MessageView.viewFromNib(layout: .centeredView)
        messageView.configureBackgroundView(width: 250)
        messageView.configureContent(title: "Sorry", body: "Not yet implemented.", iconImage: nil, iconText: "💩", buttonImage: nil, buttonTitle: "Okay") { _ in
            SwiftMessages.hide()
        }
        messageView.backgroundView.backgroundColor = UIColor.init(white: 0.97, alpha: 1)
        messageView.backgroundView.layer.cornerRadius = 10
        var config = SwiftMessages.defaultConfig
        config.presentationStyle = .center
        config.duration = .forever
        config.dimMode = .blur(style: .dark, alpha: 1, interactive: true)
        config.presentationContext  = .window(windowLevel: UIWindow.Level.statusBar)
        SwiftMessages.show(config: config, view: messageView)
    }
}

extension SettingsViewController: MFMailComposeViewControllerDelegate {
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.dismiss(animated: true, completion: nil)
    }
}

class LargeAutoSizedExtremityView: UIView {
    lazy var label: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "Is this the real life?\nIs this just fantasy?\nCaught in a landslide,\nNo escape from reality."
        return label
    }()
    
    init() {
        super.init(frame: .zero)
        
        layoutMargins = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        addSubview(label)
        label.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor).isActive = true
        label.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor).isActive = true
        label.topAnchor.constraint(equalTo: layoutMarginsGuide.topAnchor).isActive = true
        label.bottomAnchor.constraint(equalTo: layoutMarginsGuide.bottomAnchor).isActive = true
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
