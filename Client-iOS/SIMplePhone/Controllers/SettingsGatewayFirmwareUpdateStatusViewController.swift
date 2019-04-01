//
//  SettingsGatewayFirmwareUpdateStatusViewController.swift
//  SIMplePhone
//
//  Created by Lukas Kuster on 10.01.19.
//  Copyright © 2019 Lukas Kuster. All rights reserved.
//

import UIKit
import SIMplePhoneKit

class SettingsGatewayFirmwareUpdateStatusViewController: UIViewController {
    private let gateway: SPGateway?
    private let newVersion: String
    
    lazy var gatewayNameLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .boldSystemFont(ofSize: 25.0)
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()
    
    lazy var updateNameLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .boldSystemFont(ofSize: 18.0)
        label.textAlignment = .center
        label.numberOfLines = 0
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
    
    lazy var progressBarView: RoundedUIProgressView = {
        let progressView = RoundedUIProgressView(progressViewStyle: .bar)
        progressView.translatesAutoresizingMaskIntoConstraints = false
        progressView.center = view.center
        progressView.trackTintColor = .lightGray
        progressView.tintColor = self.gateway?.color ?? .blue
        return progressView
    }()
    
    lazy var activityIndicatorView: UIActivityIndicatorView = {
        let activityIndicator = UIActivityIndicatorView(style: .gray)
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        activityIndicator.startAnimating()
        return activityIndicator
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view = UIView()
        view.backgroundColor = .tableViewBackground
        
        view.addSubview(gatewayNameLabel)
        view.addSubview(updateNameLabel)
        view.addSubview(gatewayIconBackgroundView)
        view.addSubview(gatewayIconView)
        view.addSubview(progressBarView)
        view.addSubview(activityIndicatorView)
        
        self.fillData()
        self.layout()
        
        self.fetchProgress()
    }
    
    func fetchProgress() {
        DispatchQueue.global(qos: .userInteractive).async {
            var progress: Float = 0.0
            while progress <= 1.0 {
                sleep(1)
                progress += 0.2
                DispatchQueue.main.async {
                    self.progressBarView.setProgress(progress, animated: true)
                    if progress == 1.0 {
                        self.dismiss(animated: true, completion: nil)
                    }
                }
            }
        }
    }
    
    func layout() {
        gatewayIconBackgroundView.bottomAnchor.constraint(equalTo: gatewayNameLabel.topAnchor, constant: -15).isActive = true
        gatewayIconBackgroundView.centerXAnchor.constraint(equalTo: view.layoutMarginsGuide.centerXAnchor).isActive = true
        gatewayIconBackgroundView.widthAnchor.constraint(equalToConstant: 140).isActive = true
        gatewayIconBackgroundView.heightAnchor.constraint(equalToConstant: 140).isActive = true
        gatewayIconView.centerXAnchor.constraint(equalTo: gatewayIconBackgroundView.centerXAnchor).isActive = true
        gatewayIconView.centerYAnchor.constraint(equalTo: gatewayIconBackgroundView.centerYAnchor).isActive = true
        gatewayIconView.widthAnchor.constraint(equalTo: gatewayIconBackgroundView.widthAnchor, multiplier: 0.72).isActive = true
        gatewayIconView.heightAnchor.constraint(equalTo: gatewayIconView.widthAnchor, multiplier: 0.68).isActive = true
        
        gatewayNameLabel.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor, constant: 15).isActive = true
        gatewayNameLabel.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor, constant: -15).isActive = true
        gatewayNameLabel.bottomAnchor.constraint(equalTo: updateNameLabel.topAnchor, constant: -5).isActive = true
        
        updateNameLabel.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor, constant: 15).isActive = true
        updateNameLabel.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor, constant: -15).isActive = true
        updateNameLabel.centerYAnchor.constraint(equalTo: view.layoutMarginsGuide.centerYAnchor, constant: 10).isActive = true
        
        progressBarView.centerXAnchor.constraint(equalTo: view.layoutMarginsGuide.centerXAnchor).isActive = true
        progressBarView.widthAnchor.constraint(equalTo: view.layoutMarginsGuide.widthAnchor, multiplier: 0.75).isActive = true
        progressBarView.heightAnchor.constraint(equalToConstant: 2.5).isActive = true
        progressBarView.topAnchor.constraint(equalTo: updateNameLabel.bottomAnchor, constant: 50).isActive = true
        
        activityIndicatorView.topAnchor.constraint(equalTo: progressBarView.bottomAnchor, constant: 20).isActive = true
        activityIndicatorView.centerXAnchor.constraint(equalTo: view.layoutMarginsGuide.centerXAnchor).isActive = true
        activityIndicatorView.widthAnchor.constraint(equalToConstant: 40).isActive = true
        activityIndicatorView.heightAnchor.constraint(equalToConstant: 40).isActive = true
    }
    
    func fillData() {
        if let gateway = gateway {
            gatewayNameLabel.text = gateway.name ?? "Gateway"
            updateNameLabel.text = "Update to Firmware Version \(newVersion)"
            gatewayIconBackgroundView.backgroundColor = gateway.color ?? .lightGray
        }
    }
    
    init(gateway: SPGateway?, to newVersion: String) {
        self.gateway = gateway
        self.newVersion = newVersion
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class RoundedUIProgressView: UIProgressView {
    override func layoutSubviews() {
        super.layoutSubviews()
        subviews.forEach { subview in
            subview.layer.masksToBounds = true
            subview.layer.cornerRadius = 1.25
        }
    }
}
