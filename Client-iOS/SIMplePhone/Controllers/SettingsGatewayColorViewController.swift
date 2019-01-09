//
//  SettingsGatewayColorViewController.swift
//  SIMplePhone
//
//  Created by Lukas Kuster on 08.01.19.
//  Copyright © 2019 Lukas Kuster. All rights reserved.
//

import UIKit
import Static
import ChromaColorPicker

protocol SettingsGatewayColorViewControllerDelegate {
    func gatewayColorDidChange(to: UIColor)
}

class SettingsGatewayColorViewController: TableViewController {
    public var delegate: SettingsGatewayColorViewControllerDelegate?
    private var colorPicker: ChromaColorPicker?
    private var didChangeColor = false
    private var color: UIColor {
        didSet {
            self.didChangeColor = true
            let colorView: UIView = {
                let view = UIView(frame: CGRect(x: 0, y: 0, width: 27, height: 27))
                view.backgroundColor = color
                view.layer.cornerRadius = view.frame.width/2
                return view
            }()
            self.dataSource.sections[0].rows[0].accessory = .view(colorView)
            self.colorPicker?.adjustToColor(color)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = "Color Selector"
        
        self.tableView.rowHeight = 50
        
        self.dataSource = DataSource(tableViewDelegate: self)
        
        let screenWidth = UIScreen.main.bounds.width
        
        let colorSelectorView = UIView(frame: CGRect(x: 0.0, y: 0.0, width: screenWidth, height: 325.0))
        colorSelectorView.backgroundColor = .white
        let iosGray = UIColor(red:0.78, green:0.78, blue:0.80, alpha:1.0)
        colorSelectorView.addBorder(side: .top, thickness: 0.25, color: iosGray)
        colorSelectorView.addBorder(side: .bottom, thickness: 0.25, color: iosGray)
        
        self.colorPicker = ChromaColorPicker(frame: CGRect(x: (screenWidth-300)/2, y: 12.5, width: 300, height: 300))
        if let colorPicker = self.colorPicker {
            colorPicker.adjustToColor(color)
            colorPicker.padding = 5
            colorPicker.stroke = 10
            colorPicker.hexLabel.textColor = .darkGray
            colorPicker.delegate = self
            colorSelectorView.addSubview(colorPicker)
            colorPicker.layout()
        }
        
        let colorView: UIView = {
            let view = UIView(frame: CGRect(x: 0, y: 0, width: 27, height: 27))
            view.backgroundColor = color
            view.layer.cornerRadius = view.frame.width/2
            return view
        }()
        
        self.dataSource.sections = [
            Section(rows: [
                Row(text: "Current color", accessory: .view(colorView))
                ]),
            Section(header: "Select a color", footer: Section.Extremity.view(colorSelectorView)),
            Section(rows: [
                Row(text: "Random color", selection: {
                    self.color = .random
                }, cellClass: ButtonCell.self)
                ])
        ]
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.navigationController?.navigationBar.prefersLargeTitles = false
        self.navigationController?.navigationItem.largeTitleDisplayMode = .never
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        if self.didChangeColor {
            self.delegate?.gatewayColorDidChange(to: self.color)
        }
    }
    
    init(color: UIColor?) {
        self.color = color ?? .lightGray
        super.init(style: .grouped)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension SettingsGatewayColorViewController: UITableViewDelegate {
    
}

extension SettingsGatewayColorViewController: ChromaColorPickerDelegate {
    func colorPickerDidChooseColor(_ colorPicker: ChromaColorPicker, color: UIColor) {
        self.color = color
    }
}

extension UIColor {
    static var random: UIColor {
        return UIColor(red: .random(in: 0...1),
                       green: .random(in: 0...1),
                       blue: .random(in: 0...1),
                       alpha: 1.0)
    }
}
