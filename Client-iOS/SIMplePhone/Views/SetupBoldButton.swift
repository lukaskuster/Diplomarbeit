//
//  SetupBoldButton.swift
//  SIMplePhone
//
//  Created by Lukas Kuster on 12.11.18.
//  Copyright © 2018 Lukas Kuster. All rights reserved.
//

import UIKit

class SetupBoldButton: UIButton {
    override func awakeFromNib() {
        super.awakeFromNib()
        
        self.layer.cornerRadius = 8.0
        self.clipsToBounds = true
    }
}
