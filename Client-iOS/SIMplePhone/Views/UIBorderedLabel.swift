//
//  UIBorderedLabel.swift
//  SIMplePhone
//
//  Created by Lukas Kuster on 04.03.19.
//  Copyright © 2019 Lukas Kuster. All rights reserved.
//

import UIKit

class UIBorderedLabel: UILabel {
    override func layoutSubviews() {
        super.layoutSubviews()
        self.textColor = .white
        self.font = UIFont.systemFont(ofSize: 12.5)
        self.layer.cornerRadius = 5
        self.layer.borderColor = UIColor.clear.cgColor
        self.layer.borderWidth = 0
        self.layer.masksToBounds = true
    }
    
    override func drawText(in rect: CGRect) {
        let insets: UIEdgeInsets = UIEdgeInsets(top: 2.5, left: 5, bottom: 2.5, right: 5)
        self.setNeedsLayout()
        return super.drawText(in: rect.inset(by: insets))
    }
    
    override var intrinsicContentSize: CGSize {
        get {
            var contentSize = super.intrinsicContentSize
            contentSize.height += 5
            contentSize.width += 10
            return contentSize
        }
    }
}
