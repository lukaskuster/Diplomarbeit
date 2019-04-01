//
//  SettingsGatewayNameViewController.swift
//  SIMplePhone
//
//  Created by Lukas Kuster on 09.01.19.
//  Copyright © 2019 Lukas Kuster. All rights reserved.
//

import UIKit
import Static
protocol SettingsGatewayNameViewControllerDelegate {
    func gatewayNameDidChange(to: String)
}

class SettingsGatewayNameViewController: TableViewController {
    public var delegate: SettingsGatewayNameViewControllerDelegate?
    public var name: String
    public var didChangeName = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = "Name"
        self.tableView.rowHeight = 50
        self.tableView.alwaysBounceVertical = false
        
        self.dataSource = DataSource(tableViewDelegate: self)
        
        self.dataSource.sections = [
            Section(footer: Section.Extremity.autoLayoutView(TextFieldView(name: self.name, parent: self)))
        ]
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.navigationController?.navigationBar.prefersLargeTitles = false
        self.navigationController?.navigationItem.largeTitleDisplayMode = .never
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        if self.didChangeName {
            self.delegate?.gatewayNameDidChange(to: self.name)
        }
    }
    
    init(name: String?) {
        self.name = name ?? "Gateway"
        super.init(style: .grouped)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class TextFieldView: UIView {
    private var parent: SettingsGatewayNameViewController?
    lazy var textField: UITextField = {
        let textField = UITextField()
        textField.font = UIFont.systemFont(ofSize: 17)
        textField.keyboardType = .default
        textField.returnKeyType = .done
        textField.clearButtonMode = .always
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.delegate = self
        textField.addTarget(self, action: #selector(self.textFieldDidChange(_:)),
                            for: .editingChanged)
        return textField
    }()
    
    @objc func textFieldDidChange(_ textField: UITextField) {
        if let newText = textField.text {
            parent?.name = newText
            parent?.didChangeName = true
        }
    }
    
    init(name: String?, parent: SettingsGatewayNameViewController?) {
        self.parent = parent
        super.init(frame: .zero)
        self.backgroundColor = .white
        
        layoutMargins = UIEdgeInsets(top: 0, left: 15, bottom: 0, right: 10)
        addSubview(textField)
        textField.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor).isActive = true
        textField.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor).isActive = true
        textField.topAnchor.constraint(equalTo: layoutMarginsGuide.topAnchor).isActive = true
        textField.heightAnchor.constraint(equalToConstant: 50).isActive = true
        textField.bottomAnchor.constraint(equalTo: layoutMarginsGuide.bottomAnchor).isActive = true
        if let name = name {
            textField.text = name
        }else{
            textField.placeholder = "Gateway"
        }
        textField.becomeFirstResponder()
    }
    
    override func layoutSubviews() {
        self.addBorder(side: .top, thickness: 0.25, color: .cellSeperatorGray)
        self.addBorder(side: .bottom, thickness: 0.25, color: .cellSeperatorGray)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension SettingsGatewayNameViewController: UITableViewDelegate {
    
}

extension TextFieldView: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        parent?.navigationController?.popViewController(animated: true)
        return true
    }
}
