//
//  SettingsAccountViewController.swift
//  SIMplePhone
//
//  Created by Lukas Kuster on 06.12.18.
//  Copyright © 2018 Lukas Kuster. All rights reserved.
//

import UIKit
import Static
import SIMplePhoneKit
import SwiftMessages

class SettingsAccountViewController: TableViewController {
    let refreshControl = UIRefreshControl()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = "Account"
        
        self.tableView.rowHeight = 50
        
        self.dataSource = DataSource(tableViewDelegate: self)
        
        self.refreshControl.attributedTitle = NSAttributedString(string: "Pull to refresh")
        self.refreshControl.addTarget(self, action: #selector(refreshTableView), for: UIControl.Event.valueChanged)
        self.tableView.addSubview(refreshControl)
        
        self.dataSource.sections = [
            Section(header: "My Clients", rows: [Row(cellClass: LoadingCell.self)]),
            Section(rows: [
                Row(text: "iCloud Sharing", accessory: .switchToggle(value: SPDevice.local?.sync ?? false, { newState in
                    self.changeiCloudSharing(toState: newState)
                }))
                ], footer: Section.Extremity.init(stringLiteral: "iCloud Sharing automatically authentificates this account on all your other devices. It also syncs messages, the recent calls log and voicemails across the devices.")),
            Section(header: Section.Extremity.init(stringLiteral: "Account\(SPManager.shared.getUsername() != nil ? " ("+SPManager.shared.getUsername()!+")" : "")"), rows: [
                Row(text: "Change account mail", selection: {
                    
                }, accessory: .disclosureIndicator),
                Row(text: "Change account password", selection: {
                    self.demoCentered()
                }, accessory: .disclosureIndicator),
                Row(text: "Delete account", selection: {
                    self.deleteAccount()
                }, cellClass: DestructiveButtonCell.self)]),
            Section(rows: [
                Row(text: "Logout of account", selection: {
                    self.logoutUser()
                    }, cellClass: DestructiveButtonCell.self)
                ])
        ]
        
        self.loadDevices()
    }
    
    @objc func refreshTableView() {
        self.loadDevices()
    }
    
    func deleteAccount() {
        let alert = UIAlertController(title: "Delete account?", message: "Do you really want to delete your account? This deletes all of your user data on our servers, revokes all your other clients, as well as resets all your gateways to factory mode. This can not be undone.", preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "Delete", style: .destructive, handler: { (action) in
            // TO-DO: Delete user
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    func changeiCloudSharing(toState newState: Bool) {
        SPManager.shared.setiCloudSyncState(newState, completion: { (success, error) in
            if success {
                DispatchQueue.main.async {
                    self.loadDevices()
                    self.dataSource.sections[1].rows[0].accessory = .switchToggle(value: SPDevice.local?.sync ?? false, { newState in
                        self.changeiCloudSharing(toState: newState)
                    })
//                    self.tableView.reloadRows(at: [IndexPath(row: 0, section: 1)], with: .fade)
                }
            }else{
                print("error \(error!)")
            }
        })
    }
    
    func demoCentered() {
        let messageView: MessageView = MessageView.viewFromNib(layout: .centeredView)
        messageView.configureBackgroundView(width: 250)
        messageView.configureContent(title: "Hey There!", body: "Please try swiping to dismiss this message.", iconImage: nil, iconText: "🦄", buttonImage: nil, buttonTitle: "No Thanks") { _ in
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
    
    func loadDevices() {
        self.dataSource.sections[0].rows.removeAll()
        self.dataSource.sections[0].rows.insert(Row(cellClass: LoadingCell.self), at: 0)
        SPManager.shared.getAllDevices { (success, devices, error) in
            if success {
                if var devices = devices {
                    devices.sort(by: { (device1, device2) -> Bool in
                        return (device1.id == SPDevice.local?.id) && !(device2.id == SPDevice.local?.id)
                    })
                    DispatchQueue.main.async {
                        self.dataSource.sections[0].rows.remove(at: 0)
                    }
                    for device in devices {
                        var editActions = [Row.EditAction]()
                        
                        if SPDevice.local?.id != device.id {
                            editActions.append(Row.EditAction.init(title: "Revoke this device", style: .destructive, backgroundColor: .red, selection: { index in
                                self.revoke(device: device, completion: { (success) in
                                    if success {
                                        DispatchQueue.main.async {
                                            self.dataSource.sections[0].rows.remove(at: index.row)
                                        }
                                    }
                                })
                            }))
                        }
                        
                        DispatchQueue.main.async {
                            let syncIcon = UIImageView(image: #imageLiteral(resourceName: "cloud_sync"))
                            syncIcon.sizeThatFits(CGSize(width: 10, height: 10))
                            syncIcon.tintColor = UIColor.lightGray
                            let accessory: Row.Accessory = device.sync ? Row.Accessory.view(syncIcon) : Row.Accessory.none
                            
                            let row = Row(text: device.name, detailText: (SPDevice.local?.id == device.id ? "This Device (\(device.deviceModel))" : device.deviceModel), image: nil, accessory: accessory, cellClass: SubtitleCell.self, editActions: editActions, uuid: "device-\(device.id)")
                            
                            self.dataSource.sections[0].rows.append(row)
                            if self.refreshControl.isRefreshing {
                                self.refreshControl.endRefreshing()
                            }
                        }
                    }
                }
            }else{
                
            }
        }
    }
    
    func revoke(device: SPDevice, completion: @escaping (_ success: Bool) -> Void) {
        let alert = UIAlertController(title: "Revoke \(device.name)?", message: "This will sign out this device from your account and delete all the locally cached data on that device.", preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "Revoke", style: .destructive, handler: { (action) in
            SPManager.shared.revoke(device: device, completion: { (success, error) in
                if success {
                    completion(true)
                }else{
                    // TO-DO: Respond to error
                }
            })
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (action) in
            completion(false)
        }))
        self.present(alert, animated: true, completion: nil)
    }
    
    func logoutUser() {
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .alert)
        if SPDevice.local?.sync ?? false {
            alert.title = "Logout of all devices?"
            alert.message = "This account is associated with other devices, through iCloud. Where do you want to log out?"
            alert.addAction(UIAlertAction(title: "All devices", style: .destructive, handler: { (action) in
                SPManager.shared.logoutUser(reportToServer: true, onAllDevices: true, completion: { (success, error) in
                    DispatchQueue.main.async {
                        UIApplication.shared.unregisterForRemoteNotifications()
                        let storyboard = UIStoryboard(name: "Setup", bundle: nil)
                        let controller = storyboard.instantiateViewController(withIdentifier: "login")
                        self.present(controller, animated: false, completion: nil)
                    }
                })
            }))
            alert.addAction(UIAlertAction(title: "Just this device", style: .default, handler: { (action) in
                SPManager.shared.logoutUser(reportToServer: true, onAllDevices: false, completion: { (success, error) in
                    DispatchQueue.main.async {
                        UIApplication.shared.unregisterForRemoteNotifications()
                        let storyboard = UIStoryboard(name: "Setup", bundle: nil)
                        let controller = storyboard.instantiateViewController(withIdentifier: "login")
                        self.present(controller, animated: false, completion: nil)
                    }
                })
            }))
        }else{
            alert.title = "Logout on this devices?"
            alert.message = ""
            alert.addAction(UIAlertAction(title: "Logout", style: .destructive, handler: { (action) in
                SPManager.shared.logoutUser(reportToServer: true, onAllDevices: false, completion: { (success, error) in
                    DispatchQueue.main.async {
                        UIApplication.shared.unregisterForRemoteNotifications()
                        let storyboard = UIStoryboard(name: "Setup", bundle: nil)
                        let controller = storyboard.instantiateViewController(withIdentifier: "login")
                        self.present(controller, animated: false, completion: nil)
                    }
                })
            }))
        }
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.navigationController?.navigationBar.prefersLargeTitles = false
        self.navigationController?.navigationItem.largeTitleDisplayMode = .never
    }
    
    init() {
        super.init(style: .grouped)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}

extension SettingsAccountViewController: UITableViewDelegate {
}

class DestructiveButtonCell: UITableViewCell, Cell {
    public override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: .default, reuseIdentifier: reuseIdentifier)
        initialize()
    }
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        initialize()
    }
    
    open override func tintColorDidChange() {
        super.tintColorDidChange()
        textLabel?.textColor = UIColor.red
    }
    
    private func initialize() {
        tintColorDidChange()
    }
}

class LoadingCell: UITableViewCell, Cell {
    public override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: .default, reuseIdentifier: reuseIdentifier)
    }
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        let activityIndicator = UIActivityIndicatorView(style: .gray)
        activityIndicator.center = CGPoint(x: self.bounds.width/2, y: self.bounds.height/2)
        self.addSubview(activityIndicator)
        activityIndicator.startAnimating()
    }
}
