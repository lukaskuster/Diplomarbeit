//
//  RoundedImageView.swift
//  SIMplePhone
//
//  Created by Lukas Kuster on 07.03.19.
//  Copyright © 2019 Lukas Kuster. All rights reserved.
//

import UIKit

class RoundedImageView: UIImageView {
    override init(frame: CGRect) {
        super.init(frame: frame)
        clipsToBounds = true
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        clipsToBounds = true
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        layer.cornerRadius = bounds.height / 2
    }
}
