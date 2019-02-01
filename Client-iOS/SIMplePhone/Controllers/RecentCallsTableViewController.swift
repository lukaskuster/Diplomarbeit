//
//  RecentCallsTableViewController.swift
//  SIMplePhone
//
//  Created by Lukas Kuster on 31.10.18.
//  Copyright © 2018 Lukas Kuster. All rights reserved.
//

import UIKit
import SIMplePhoneKit
import Contacts
import ContactsUI

class RecentCallsTableViewController: UITableViewController {

    var recentCalls = [SPRecentCall]()
    var showMissedCallsOnly = false
    var missedCalls: [SPRecentCall] {
        var missed = [SPRecentCall]()
        for call in recentCalls {
            if call.missed {
                missed.append(call)
            }
        }
        return missed
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.rightBarButtonItem = self.editButtonItem
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.loadCalls()
    }
    
    func loadCalls() {
        if let calls = SPManager.shared.getRecentCalls() {
            self.recentCalls = calls
        }else{
            self.recentCalls = [SPRecentCall]()
        }
        self.tableView.reloadData()
    }
    
    @IBAction func allOrMissedSelectorChanged(_ sender: UISegmentedControl) {
        if sender.selectedSegmentIndex == 0 {
            // All
            self.showMissedCallsOnly = false
            self.tableView.reloadData()
        }else{
            // Missed
            self.showMissedCallsOnly = true
            self.tableView.reloadData()
        }
    }
    

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if self.showMissedCallsOnly { return missedCalls.count }
        return recentCalls.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "recentCallCell") as! RecentCallsTableViewCell
        
        cell.call = self.showMissedCallsOnly ? missedCalls[indexPath.row] : recentCalls[indexPath.row]
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let call = self.showMissedCallsOnly ? missedCalls[indexPath.row] : recentCalls[indexPath.row]
        let phoneNumber = call.secondParty
        SPDelegate.shared.initiateCall(with: phoneNumber)
    }
    
    override func tableView(_ tableView: UITableView, accessoryButtonTappedForRowWith indexPath: IndexPath) {
        let call = self.showMissedCallsOnly ? missedCalls[indexPath.row] : recentCalls[indexPath.row]
        
        if let contact = call.secondParty.contact {
            let view = CNContactViewController(for: contact)
            view.delegate = self
            self.navigationController?.pushViewController(view, animated: true)
        }else{
            let phoneNumber = call.secondParty.prettyPhoneNumber()
            let contact = CNMutableContact()
            contact.phoneNumbers.append(CNLabeledValue<CNPhoneNumber>(label: CNLabelPhoneNumberMobile, value: CNPhoneNumber(stringValue: phoneNumber)))
            let view = CNContactViewController(forUnknownContact: contact)
            view.alternateName = phoneNumber
            view.message = "Unknown Phone Number"
            view.contactStore = CNContactStore()
            view.delegate = self
            self.navigationController?.pushViewController(view, animated: true)
        }
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let call = self.recentCalls[indexPath.row]
            SPManager.shared.deleteRecentCall(call)
            self.loadCalls()
        }
    }
    
    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

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
    
    func initiateCall(with contact: CNContact, _ property: CNContactProperty) {
        let phoneNumber = (property.value as! CNPhoneNumber).stringValue
        let spNumber = SPNumber(withNumber: phoneNumber)
        SPDelegate.shared.initiateCall(with: spNumber)
    }

}

extension RecentCallsTableViewController: CNContactViewControllerDelegate {
    func contactViewController(_ viewController: CNContactViewController, shouldPerformDefaultActionFor property: CNContactProperty) -> Bool {
        if property.key == "phoneNumbers" {
            self.initiateCall(with: viewController.contact, property)
            return false
        }else{
            return true
        }
    }
}
