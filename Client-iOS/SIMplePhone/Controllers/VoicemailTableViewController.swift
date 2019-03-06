//
//  VoicemailTableViewController.swift
//  SIMplePhone
//
//  Created by Lukas Kuster on 18.10.18.
//  Copyright © 2018 Lukas Kuster. All rights reserved.
//

import UIKit
import Contacts
import SIMplePhoneKit
import SwiftMessages

class VoicemailTableViewController: UITableViewController {

    public var voicemails = [SPVoicemail]()
    var selectedRow: IndexPath?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.tableView.allowsMultipleSelection = false
        self.tableView.allowsSelection = true
        self.tableView.allowsSelectionDuringEditing = false
        self.tableView.tableFooterView = UIView()
        
        self.navigationItem.rightBarButtonItem = self.editButtonItem
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        DispatchQueue.main.async {
            self.loadVoicemails()
            self.tableView.reloadData()
        }
    }
    
    func loadVoicemails() {
        if let voicemails = SPManager.shared.getVoicemails() {
            self.voicemails = voicemails
            self.tabBarItem.badgeValue = "\(self.voicemails.count)"
        }
    }
    
    @IBAction func didTapGreetingBtn(_ sender: UIBarButtonItem) {
        let messageView: MessageView = MessageView.viewFromNib(layout: .centeredView)
        messageView.configureBackgroundView(width: 250)
        messageView.configureContent(title: "Sorry", body: "Not yet implemented.", iconImage: nil, iconText: "💩", buttonImage: nil, buttonTitle: "But this adds sample voicemails") { _ in
            SPManager.shared.addSampleVoicemails()
            self.loadVoicemails()
            self.tableView.reloadData()
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

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return voicemails.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if self.selectedRow == indexPath && self.tableView.cellForRow(at: indexPath)?.reuseIdentifier == "voicemailMessageCell" {
            let cell = tableView.dequeueReusableCell(withIdentifier: "expandedVoicemailMessageCell", for: indexPath) as! SelectedVoicemailTableViewCell
            cell.voicemail = voicemails[indexPath.row]
            cell.cellIndex = indexPath
            cell.parentVC = self
            
            return cell
        }else{
            // Reset Audio Player of old cell
            if let index = self.selectedRow,
                let oldCell = self.tableView.cellForRow(at: index) as? SelectedVoicemailTableViewCell {
                oldCell.resetAudioPlayer()
            }
            
            let cell = tableView.dequeueReusableCell(withIdentifier: "voicemailMessageCell", for: indexPath) as! VoicemailTableViewCell
            cell.voicemail = voicemails[indexPath.row]
            
            return cell
        }
    }

    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Disable editing while expanded
        if let selection = self.selectedRow {
            if selection == indexPath && self.tableView.cellForRow(at: indexPath) is SelectedVoicemailTableViewCell {
                return false
            }
        }
        return true
    }

    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            self.deleteVoicemail(at: indexPath)
        }
    }
    
    public func deleteVoicemail(at index: IndexPath) {
        let voicemail = self.voicemails[index.row]
        let otherparty = voicemail.secondParty.contact != nil ? voicemail.secondParty.contact!.attributedFullName().string : voicemail.secondParty.prettyPhoneNumber()
        let date = DateFormatter.localizedString(from: voicemail.time, dateStyle: .long, timeStyle: .short)
        let alert = UIAlertController(title: "Delete Voicemail?", message: "Received from \(otherparty) on \(date). This can not be undone and happens across all your devices.", preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "Delete Voicemail", style: .destructive, handler: { (action) in
            SPManager.shared.deleteVoicemail(withId: self.voicemails[index.row].id, completion: {
                self.loadVoicemails()
                self.tableView.deleteRows(at: [index], with: .fade)
            })
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        if let popoverController = alert.popoverPresentationController {
            popoverController.sourceView = self.tableView.cellForRow(at: index)
            popoverController.sourceRect = self.tableView.cellForRow(at: index)!.bounds
            popoverController.canOverlapSourceViewRect = false
            popoverController.permittedArrowDirections = [.up, .down]
        }
        if let controller = UIApplication.shared.topMostViewController() {
            controller.present(alert, animated: true)
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let cache: IndexPath? = self.selectedRow
        self.selectedRow = indexPath
        if let oldCell = cache {
            if oldCell != indexPath {
                self.tableView.reloadRows(at: [oldCell], with: .fade)
            }
        }
        self.tableView.reloadRows(at: [indexPath], with: .fade)
    }
 
}
