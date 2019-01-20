//
//  SelectGatewayViewController.swift
//  SIMplePhone
//
//  Created by Lukas Kuster on 15.01.19.
//  Copyright © 2019 Lukas Kuster. All rights reserved.
//

import UIKit
import SIMplePhoneKit
import SwiftMessages

class SelectGatewaySegue: SwiftMessagesSegue {
    override public init(identifier: String?, source: UIViewController, destination: UIViewController) {
        super.init(identifier: identifier, source: source, destination: destination)
        self.configure(layout: .centered)
        self.dimMode = .blur(style: .dark, alpha: 0.9, interactive: false)
        self.interactiveHide = false
        self.messageView.configureNoDropShadow()
        self.presentationStyle = .center
        self.containerView.cornerRadius = 20
    }
}

class SelectGatewayViewController: UICollectionViewController {
    private let number: SPNumber
    private var gateways: [SPGateway]?
    public var parentVC: UIViewController?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Register cell classes
        self.title = "Select a gateway"
        let cancelBtn = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(self.closeModal))
        self.navigationItem.leftBarButtonItem = cancelBtn
        self.collectionView?.register(GatewayCollectionCell.self, forCellWithReuseIdentifier: String(describing: GatewayCollectionCell.self))
        let height = (self.parentVC?.view.frame.height ?? 0)*0.65
        self.preferredContentSize = CGSize(width: 0, height: height)
        self.loadGateways { (error) in
            if let error = error {
                print("error while loading gateways \(error)")
            }
        }
        self.collectionView.backgroundColor = .tableViewBackground
        // Do any additional setup after loading the view.
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    init(number: SPNumber) {
        self.number = number
        let layout = UICollectionViewFlowLayout()
        layout.sectionInset = UIEdgeInsets(top: 15, left: 10, bottom: 15, right: 10)
        layout.scrollDirection = .vertical
        let itemWidth = min((UIScreen.main.bounds.width * 0.85), 400)
        layout.itemSize = CGSize(width: itemWidth, height: 150)
        layout.minimumLineSpacing = 10.0
        super.init(collectionViewLayout: layout)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc private func closeModal() {
        self.dismiss(animated: true, completion: nil)
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using [segue destinationViewController].
        // Pass the selected object to the new view controller.
    }
    */

    // MARK: UICollectionViewDataSource
    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }


    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return gateways?.count ?? 0
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = self.collectionView?.dequeueReusableCell(withReuseIdentifier: String(describing: GatewayCollectionCell.self), for: indexPath) as! GatewayCollectionCell
        cell.gateway = gateways?[indexPath.row]
        return cell
    }
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let gateway = self.gateways![indexPath.item]
        let storyboard = UIStoryboard(name: "Call", bundle: nil)
        let callUIVC = storyboard.instantiateViewController(withIdentifier: "CallUI") as! CallViewController
        callUIVC.receiver = self.number
        callUIVC.gateway = gateway
        self.dismiss(animated: true, completion: {
            callUIVC.show()
        })
        
        SPManager.shared.makeCall(to: self.number, on: gateway) { error in
            if let error = error {
                DispatchQueue.main.async {
                    callUIVC.close(error)
                }
                return
            }

            DispatchQueue.main.async {
                callUIVC.connected()
            }
        }
    }
    
    func loadGateways(completion: @escaping (_ error: Error?) -> Void) {
        SPManager.shared.getAllGateways { (success, gateways, error) in
            if success {
                if gateways?.count == 1 {
                    // Call directly
                }
                if gateways?.count == 0 {
                    // No gateway / configure now
                }
                self.gateways = gateways
                DispatchQueue.main.async {
                    self.collectionView!.reloadData()
                    completion(nil)
                }
            }else{
                completion(error)
                // TO-DO: Error handling
            }
        }
    }

    // MARK: UICollectionViewDelegate

    /*
    // Uncomment this method to specify if the specified item should be highlighted during tracking
    override func collectionView(_ collectionView: UICollectionView, shouldHighlightItemAt indexPath: IndexPath) -> Bool {
        return true
    }
    */

    /*
    // Uncomment this method to specify if the specified item should be selected
    override func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        return true
    }
    */

    /*
    // Uncomment these methods to specify if an action menu should be displayed for the specified item, and react to actions performed on the item
    override func collectionView(_ collectionView: UICollectionView, shouldShowMenuForItemAt indexPath: IndexPath) -> Bool {
        return false
    }

    override func collectionView(_ collectionView: UICollectionView, canPerformAction action: Selector, forItemAt indexPath: IndexPath, withSender sender: Any?) -> Bool {
        return false
    }

    override func collectionView(_ collectionView: UICollectionView, performAction action: Selector, forItemAt indexPath: IndexPath, withSender sender: Any?) {
    
    }
    */

}
