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
    private var colorSelector: ColorSelectorView?
    private var didChangeColor = false
    public var color: UIColor {
        didSet {
            self.didChangeColor = true
            self.dataSource.sections[0].rows[0].accessory = .view(smallColorView())
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = "Color Selector"
        
        self.tableView.rowHeight = 50
        self.tableView.alwaysBounceVertical = false
        
        self.dataSource = DataSource(tableViewDelegate: self)
        self.colorSelector = ColorSelectorView(color: self.color, parent: self)
        
        self.dataSource.sections = [
            Section(rows: [
                Row(text: "Current color", accessory: .view(smallColorView()))
                ]),
            Section(header: "Select a color", footer: Section.Extremity.autoLayoutView(self.colorSelector!)),
            Section(rows: [
                Row(text: "Random color", selection: {
                    self.colorSelector?.setRandomColor()
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
    
    func smallColorView() -> UIView {
        let view = UIView(frame: CGRect(x: 0, y: 0, width: 27, height: 27))
        view.backgroundColor = self.color
        view.layer.cornerRadius = view.frame.width/2
        return view
    }
    
    init(color: UIColor?) {
        self.color = color ?? .lightGray
        super.init(style: .grouped)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class ColorSelectorView: UIView {
    private var parent: SettingsGatewayColorViewController?
    private var colorPicker: ChromaColorPicker?
    private var color: UIColor {
        didSet {
            self.parent?.color = color
            self.colorPicker?.adjustToColor(color)
        }
    }
    
    init(color: UIColor?, parent: SettingsGatewayColorViewController?) {
        self.color = color ?? .lightGray
        self.parent = parent
        super.init(frame: .zero)
        self.backgroundColor = .white
        
        layoutMargins = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        self.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor).isActive = true
        self.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor).isActive = true
        self.topAnchor.constraint(equalTo: layoutMarginsGuide.topAnchor).isActive = true
        self.heightAnchor.constraint(equalToConstant: 325).isActive = true
    }
    
    override func layoutSubviews() {
        self.addBorder(side: .top, thickness: 0.25, color: .cellSeperatorGray)
        self.addBorder(side: .bottom, thickness: 0.25, color: .cellSeperatorGray)
        
        self.colorPicker?.removeFromSuperview()
        self.colorPicker = ChromaColorPicker(frame: CGRect(x: (self.frame.width-300)/2, y: 12.5, width: 300, height: 300))
        if let colorPicker = self.colorPicker {
            colorPicker.adjustToColor(self.color)
            colorPicker.padding = 5
            colorPicker.stroke = 10
            colorPicker.hexLabel.textColor = .darkGray
            colorPicker.delegate = self
            colorPicker.layout()
            addSubview(colorPicker)
        }
    }
    
    public func setRandomColor() {
        self.color = .random
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension SettingsGatewayColorViewController: UITableViewDelegate {
    
}

extension ColorSelectorView: ChromaColorPickerDelegate {
    func colorPickerDidChooseColor(_ colorPicker: ChromaColorPicker, color: UIColor) {
        self.color = color
    }
}
