//
//  ChatsTableViewController.swift
//  SIMplePhone
//
//  Created by Lukas Kuster on 07.03.19.
//  Copyright © 2019 Lukas Kuster. All rights reserved.
//

import UIKit
import SIMplePhoneKit

class ChatsTableViewController: UITableViewController, UISearchBarDelegate {
    var chats: [SPChat]?
    var filteredChats: [SPChat]?
    var resultSearchController: UISearchController?
    var cellsWithHighlightedMessage = [IndexPath]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationItem.leftBarButtonItem = self.editButtonItem
        self.navigationController?.navigationBar.prefersLargeTitles = true
        
        self.resultSearchController = ( {
            let controller = UISearchController(searchResultsController: nil)
            controller.searchResultsUpdater = self
            controller.dimsBackgroundDuringPresentation = false
            controller.hidesNavigationBarDuringPresentation = false
            controller.searchBar.sizeToFit()
            controller.searchBar.delegate = self
            self.navigationItem.searchController = controller
            self.navigationItem.hidesSearchBarWhenScrolling = true
            return controller
        })()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.loadChats {
            self.tableView.reloadData()
        }
    }
    
    private func loadChats(_ completion: @escaping () -> ()) {
        SPManager.shared.getAllChats { (chats, error) in
            if let error = error {
                SPDelegate.shared.display(error: error)
                completion()
                return
            }
            guard let chats = chats else { return }
            self.chats = chats.sorted(by: { (chat1, chat2) -> Bool in
                return (chat1.latestMessage()?.time ?? .distantPast) > (chat2.latestMessage()?.time ?? .distantPast)
            })
            completion()
        }
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if self.resultSearchController?.isActive ?? false { return self.filteredChats?.count ?? 0 }
        return self.chats?.count ?? 0
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: ChatPreviewTableViewCell.self), for: indexPath) as! ChatPreviewTableViewCell
        
        let chats: [SPChat]?
        if self.resultSearchController?.isActive ?? false {
            chats = self.filteredChats
        }else{
            chats = self.chats
        }
        guard let chat = chats?[indexPath.row] else { return cell }
        
        cell.chat = chat
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let chat = self.chats?[indexPath.row] else { return }
        // TODO: Implement Transition to Chat VC
        print("chat vc for \(chat.id)")
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            if let chat = self.chats?[indexPath.row] {
                SPManager.shared.deleteChat(chat) { error in
                    if let error = error {
                        SPDelegate.shared.display(error: error)
                        return
                    }
                    self.chats?.remove(at: indexPath.row)
                    self.tableView.deleteRows(at: [indexPath], with: .fade)
                }
            }
        }
    }
    
    @IBAction func didTapComposeNewMessage(_ sender: Any) {
        // TODO: Implement Message Composer
        print("compose new message")
        SPManager.shared.addSampleChats()
    }
}

extension ChatsTableViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        DispatchQueue.main.async {
            if let searchText = self.resultSearchController?.searchBar.text,
                searchController.isActive {
                if searchText.count > 0 {
                    self.filteredChats = self.chats?.filter({ chat -> Bool in
                        return chat.matches(searchText)
                    })
                }else{
                    self.filteredChats = []
                    self.cellsWithHighlightedMessage = []
                }
            }
            self.tableView.reloadData()
        }
    }
}
