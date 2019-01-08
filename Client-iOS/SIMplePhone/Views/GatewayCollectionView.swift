//
//  GatewayCollectionView.swift
//  SIMplePhone
//
//  Created by Lukas Kuster on 11.12.18.
//  Copyright © 2018 Lukas Kuster. All rights reserved.
//

import UIKit
import SIMplePhoneKit

public protocol GatewayCollectionDelegate {
    func gatewayCollection(didSelectGateway gateway: SPGateway)
    func gatewayCollection(requestsGatewaySetup bool: Bool)
}

class GatewayCollectionView: UIView, UICollectionViewDataSource, UICollectionViewDelegate, UIScrollViewDelegate {
    
    public var delegate: GatewayCollectionDelegate?
    
    private var gateways: [SPGateway]?
    var collectionView: UICollectionView?
    var pageControl = UIPageControl()
    
    let collectionMargin = CGFloat(30)
    let itemSpacing = CGFloat(10)
    
    var itemWidth = CGFloat(0)
    
    init() {
        super.init(frame: .zero)
        self.setupCollectionView()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupCollectionView() {
        self.heightAnchor.constraint(equalToConstant: 165).isActive = true
        itemWidth = min((UIScreen.main.bounds.width * 0.85), 400)
        let layout = UICollectionViewFlowLayout()
        layout.sectionInset = UIEdgeInsets(top: 15, left: 10, bottom: 0, right: 10)
        layout.itemSize = CGSize(width: itemWidth, height: 150)
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = 10.0
        
        self.collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        self.collectionView?.showsVerticalScrollIndicator = false
        self.collectionView?.showsHorizontalScrollIndicator = false
        
        self.collectionView?.decelerationRate = .fast
        self.collectionView?.dataSource = self
        self.collectionView?.delegate = self
        self.collectionView?.register(GatewayCollectionCell.self, forCellWithReuseIdentifier: String(describing: GatewayCollectionCell.self))
        self.collectionView?.register(AddNewGatewayCell.self, forCellWithReuseIdentifier: String(describing: AddNewGatewayCell.self))
        
        self.addSubview(self.collectionView!)
        self.collectionView?.translatesAutoresizingMaskIntoConstraints = false
        self.collectionView?.leftAnchor.constraint(equalTo: self.leftAnchor).isActive = true
        self.collectionView?.topAnchor.constraint(equalTo: self.topAnchor).isActive = true
        self.collectionView?.rightAnchor.constraint(equalTo: self.rightAnchor).isActive = true
        self.collectionView?.bottomAnchor.constraint(equalTo: self.bottomAnchor).isActive = true
        
        self.loadGateways { (error) in
            if let error = error {
                print("error while loading gateways \(error)")
            }
        }
        self.backgroundColor = .clear
        self.collectionView?.backgroundColor = .clear
    }
    
    func loadGateways(completion: @escaping (_ error: Error?) -> Void) {
        SPManager.shared.getAllGateways { (success, gateways, error) in
            if success {
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
    
    func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        
        let pageWidth = Float(itemWidth + itemSpacing)
        let targetXContentOffset = Float(targetContentOffset.pointee.x)
        let contentWidth = Float(collectionView!.contentSize.width  )
        var newPage = Float(self.pageControl.currentPage)
        
        if velocity.x == 0 {
            newPage = floor( (targetXContentOffset - Float(pageWidth) / 2) / Float(pageWidth)) + 1.0
        }else{
            newPage = Float(velocity.x > 0 ? self.pageControl.currentPage + 1 : self.pageControl.currentPage - 1)
            if newPage < 0 {
                newPage = 0
            }
            if (newPage > contentWidth / pageWidth) {
                newPage = ceil(contentWidth / pageWidth) - 1.0
            }
        }
        
        self.pageControl.currentPage = Int(newPage)
        let point = CGPoint (x: CGFloat(newPage * pageWidth), y: targetContentOffset.pointee.y)
        targetContentOffset.pointee = point
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let items = (self.gateways?.count ?? 0)+1
        self.pageControl.numberOfPages = items
        return items
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if indexPath.row+1 > self.gateways?.count ?? 0 {
            // Add new cell
            let cell = self.collectionView?.dequeueReusableCell(withReuseIdentifier: String(describing: AddNewGatewayCell.self), for: indexPath) as! AddNewGatewayCell
            return cell
        }else{
            let cell = self.collectionView?.dequeueReusableCell(withReuseIdentifier: String(describing: GatewayCollectionCell.self), for: indexPath) as! GatewayCollectionCell
            cell.gateway = gateways?[indexPath.row]
            return cell
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if indexPath.row+1 > self.gateways?.count ?? 0 {
            self.delegate?.gatewayCollection(requestsGatewaySetup: true)
        }else{
            if let gateway = gateways?[indexPath.row] {
                self.delegate?.gatewayCollection(didSelectGateway: gateway)
            }
        }
    }
}

class GatewayCollectionCell: UICollectionViewCell {
    var gateway: SPGateway? {
        didSet {
            self.fillData()
        }
    }
    
    lazy var gatewayNameLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.numberOfLines = 1
        return label
    }()
    
    lazy var carrierNameLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.numberOfLines = 1
        return label
    }()
    
    lazy var phoneNumberLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.numberOfLines = 1
        return label
    }()
    
    lazy var gatewayIconView: UIImageView = {
        let image = UIImageView(image: #imageLiteral(resourceName: "gateway-icon"))
        image.translatesAutoresizingMaskIntoConstraints = false
        return image
    }()
    
    lazy var gatewayIconBackgroundView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = UIColor.lightGray
        view.layer.cornerRadius = 10.0
        return view
    }()
    
    lazy var signalStrengthView: SignalStrengthIndicatorView = {
        let view = SignalStrengthIndicatorView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.prepareCell()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func prepareCell() {
        self.backgroundColor = .white
        self.layer.cornerRadius = 10.0
        self.addSubview(gatewayIconBackgroundView)
        self.addSubview(gatewayIconView)
        self.addSubview(gatewayNameLabel)
        self.addSubview(phoneNumberLabel)
        self.addSubview(carrierNameLabel)
        self.addSubview(signalStrengthView)
        self.layoutCell()
    }
    
    func layoutCell() {
        gatewayIconBackgroundView.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor, constant: 10).isActive = true
        gatewayIconBackgroundView.centerYAnchor.constraint(equalTo: layoutMarginsGuide.centerYAnchor).isActive = true
        gatewayIconBackgroundView.widthAnchor.constraint(equalToConstant: 70).isActive = true
        gatewayIconBackgroundView.heightAnchor.constraint(equalToConstant: 70).isActive = true
        gatewayIconView.centerXAnchor.constraint(equalTo: gatewayIconBackgroundView.centerXAnchor).isActive = true
        gatewayIconView.centerYAnchor.constraint(equalTo: gatewayIconBackgroundView.centerYAnchor).isActive = true
        gatewayIconView.widthAnchor.constraint(equalTo: gatewayIconBackgroundView.widthAnchor, multiplier: 0.72).isActive = true
        gatewayIconView.heightAnchor.constraint(equalTo: gatewayIconView.widthAnchor, multiplier: 0.68).isActive = true
        
        gatewayNameLabel.leadingAnchor.constraint(equalTo: gatewayIconBackgroundView.trailingAnchor, constant: 10).isActive = true
        gatewayNameLabel.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor, constant: 10).isActive = true
        gatewayNameLabel.topAnchor.constraint(equalTo: gatewayIconBackgroundView.topAnchor, constant: 5).isActive = true
        
        phoneNumberLabel.leadingAnchor.constraint(equalTo: gatewayIconBackgroundView.trailingAnchor, constant: 10).isActive = true
        phoneNumberLabel.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor, constant: 10).isActive = true
        phoneNumberLabel.topAnchor.constraint(equalTo: gatewayNameLabel.bottomAnchor).isActive = true
        
        signalStrengthView.leadingAnchor.constraint(equalTo: gatewayIconBackgroundView.trailingAnchor, constant: 10).isActive = true
        signalStrengthView.topAnchor.constraint(equalTo: phoneNumberLabel.bottomAnchor).isActive = true
        signalStrengthView.heightAnchor.constraint(equalToConstant: 20).isActive = true
        signalStrengthView.widthAnchor.constraint(equalToConstant: 25).isActive = true
        
        carrierNameLabel.leadingAnchor.constraint(equalTo: signalStrengthView.trailingAnchor, constant: 2.5).isActive = true
        carrierNameLabel.bottomAnchor.constraint(equalTo: signalStrengthView.bottomAnchor, constant: -3.75).isActive = true
        carrierNameLabel.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor, constant: 10).isActive = true
    }
    
    func fillData() {
        if let gateway = gateway {
            gatewayNameLabel.text = gateway.name ?? "Gateway"
            gatewayNameLabel.font = .boldSystemFont(ofSize: 18.0)
            phoneNumberLabel.text = gateway.phoneNumber != nil ? SPNumber(withNumber: gateway.phoneNumber!).prettyPhoneNumber() : "number unavailable"
            phoneNumberLabel.textColor = .lightGray
            phoneNumberLabel.font = .systemFont(ofSize: 16, weight: .medium)
            carrierNameLabel.text = gateway.carrier ?? "Carrier"
            carrierNameLabel.textColor = .lightGray
            carrierNameLabel.font = .systemFont(ofSize: 15, weight: .medium)
            signalStrengthView.strength = gateway.signalStrength ?? 0.0
            gatewayIconBackgroundView.backgroundColor = gateway.color ?? .lightGray
        }
    }
    
}

class AddNewGatewayCell: UICollectionViewCell {
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.prepareCell()
    }
    
    lazy var addIcon: UIImageView = {
        let image = UIImageView(image: #imageLiteral(resourceName: "add"))
        image.translatesAutoresizingMaskIntoConstraints = false
        return image
    }()
    
    lazy var addDescLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textColor = .white
        let text = NSMutableAttributedString(string: "Setup new gateway", attributes: [.font:UIFont.boldSystemFont(ofSize: 16.5)])
        label.attributedText = text
        return label
    }()
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func prepareCell() {
        self.backgroundColor = .darkGray
        self.layer.cornerRadius = 10.0
        
        layoutMargins = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        
        let contentView = UIView(frame: .zero)
        contentView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(contentView)
        contentView.addSubview(addIcon)
        contentView.addSubview(addDescLabel)
        addIcon.heightAnchor.constraint(equalTo: self.heightAnchor, multiplier: 0.45).isActive = true
        addIcon.widthAnchor.constraint(equalTo: addIcon.heightAnchor).isActive = true
        contentView.centerXAnchor.constraint(equalTo: self.centerXAnchor).isActive = true
        contentView.centerYAnchor.constraint(equalTo: self.centerYAnchor).isActive = true
        addDescLabel.topAnchor.constraint(equalTo: self.addIcon.bottomAnchor, constant: 2.5).isActive = true
        addIcon.topAnchor.constraint(equalTo: contentView.topAnchor).isActive = true
        addDescLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor).isActive = true
        addDescLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor).isActive = true
        addIcon.centerXAnchor.constraint(equalTo: contentView.centerXAnchor).isActive = true
    }
    
}
