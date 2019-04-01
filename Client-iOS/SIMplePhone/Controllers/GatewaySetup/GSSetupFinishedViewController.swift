//
//  GSSetupFinishedViewController.swift
//  SIMplePhone
//
//  Created by Lukas Kuster on 01.02.19.
//  Copyright © 2019 Lukas Kuster. All rights reserved.
//

import UIKit
import SIMplePhoneKit

class GSSetupFinishedViewController: UIViewController {
    @IBOutlet weak var headerTitleLabel: UILabel!
    @IBOutlet weak var headerDescLabel: UILabel!
    @IBOutlet weak var gatewayPreviewView: UICollectionView!
    @IBOutlet weak var doneBtn: SetupBoldButton!
    @IBOutlet weak var setupAnotherGatewayBtn: UIButton!
    public var gateways: [SPGateway]?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.gatewayPreviewView.backgroundColor = .clear
        self.gatewayPreviewView.delegate = self
        self.gatewayPreviewView.dataSource = self
        self.gatewayPreviewView.register(GatewayCollectionCell.self, forCellWithReuseIdentifier: String(describing: GatewayCollectionCell.self))
        if gateways?.count ?? 0 > 1 {
            headerDescLabel.text = "Your gateways are now ready to be used."
        }
    }
    
    @IBAction func didTapDoneBtn(_ sender: SetupBoldButton) {
        self.navigationController?.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func didTapSetupAnotherGatewayBtn(_ sender: UIButton) {
        let storyboard = UIStoryboard(name: "Setup", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: String(describing: GSSearchingForGatewayViewController.self)) as! GSSearchingForGatewayViewController
        vc.gateways = gateways
        self.navigationController?.pushViewController(vc, animated: true)
    }
}

extension GSSetupFinishedViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        guard let gateways = gateways else { return 1 }
        return gateways.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: String(describing: GatewayCollectionCell.self), for: indexPath) as! GatewayCollectionCell
        cell.gateway = self.gateways?[indexPath.row]
        cell.backgroundColor = .tableViewBackground
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let itemWidth = min((UIScreen.main.bounds.width * 0.85), 400)
        return CGSize(width: itemWidth, height: 150)
    }
}
