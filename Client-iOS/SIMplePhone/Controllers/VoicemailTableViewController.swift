//
//  VoicemailTableViewController.swift
//  SIMplePhone
//
//  Created by Lukas Kuster on 18.10.18.
//  Copyright © 2018 Lukas Kuster. All rights reserved.
//

import UIKit
import Contacts

class VoicemailTableViewController: UITableViewController {

    let currentGateway = Gateway(imei: "98DEF5FD-3596-4003-92D3-A28263A5E479", name: "Home", number: CNPhoneNumber(stringValue: "+43 6641817908"))
    var voicemails: [Voicemail] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        voicemails.append(Voicemail(currentGateway, date: Date(), origin: "+43 6648338455", audio: "avlocation"))
        voicemails.append(Voicemail(currentGateway, date: Date(), origin: "+43 6648338456", audio: "avlocation"))
        voicemails.append(Voicemail(currentGateway, date: Date(), origin: "+43 6648338457", audio: "avlocation"))
        
        print(voicemails)
        
        self.tabBarItem.badgeValue = "\(voicemails.count)"
        
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
         self.navigationItem.rightBarButtonItem = self.editButtonItem
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return voicemails.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> VoicemailTableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "voicemailMessageCell", for: indexPath) as! VoicemailTableViewCell
        cell.voicemail = voicemails[indexPath.row]
        
        return cell
    }

    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

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
        self.tableView.beginUpdates()
        self.tableView.endUpdates()
        
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath == self.tableView.indexPathForSelectedRow {
            return 140.0
        }else{
            return 60.0
        }
    }
    
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
