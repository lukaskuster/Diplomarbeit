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

class VoicemailTableViewController: UITableViewController {

    var voicemails: [SPVoicemail] {
        return SPManager.shared.getVoicemails() ?? []
    }
    var selectedRow: IndexPath?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tabBarItem.badgeValue = "\(voicemails.count)"
        
        self.tableView.allowsMultipleSelection = false
        self.tableView.allowsSelection = true
        self.tableView.allowsSelectionDuringEditing = false
        self.tableView.tableFooterView = UIView()
                
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
         self.navigationItem.rightBarButtonItem = self.editButtonItem
    }
    
    func addVoicemailsToDB() {
        let sampleAudio = Bundle.main.url(forResource: "sample", withExtension: "m4a")!
        
        let gateway = SPGateway(withIMEI: NSUUID().uuidString, name: "Main-Gateway", phoneNumber: "00436648338455")
        
        SPManager.shared.addVoicemail(SPVoicemail(gateway, date: Date(), origin: SPNumber(withNumber: "00436641817908"), audio: sampleAudio))
        SPManager.shared.addVoicemail(SPVoicemail(gateway, date: Date(), origin: SPNumber(withNumber: "00436648338456"), audio: sampleAudio))
        SPManager.shared.addVoicemail(SPVoicemail(gateway, date: Date(), origin: SPNumber(withNumber: "00436648338457"), audio: sampleAudio))
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
            cell.parentVC = self
            
            return cell
        }else{
            let cell = tableView.dequeueReusableCell(withIdentifier: "voicemailMessageCell", for: indexPath) as! VoicemailTableViewCell
            cell.voicemail = voicemails[indexPath.row]
            
            return cell
        }
    }

    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Disable editing while expanded
        if let selection = self.selectedRow {
            if selection == indexPath && self.tableView.cellForRow(at: indexPath) is SelectedVoicemailTableViewCell {
                return false
            }
        }
        return true
    }

    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
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
    
//    override func tableView(_ tableView: UITableView, willBeginEditingRowAt indexPath: IndexPath) {
//        print(indexPath)
//        if let selectedCell = self.selectedRow {
//            if selectedCell == indexPath {
//                print("match")
//                self.selectedRow = nil
//                self.tableView.reloadRows(at: [indexPath], with: .fade)
//            }
//        }
//    }
    
    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
