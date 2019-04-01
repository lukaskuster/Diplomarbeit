//
//  CNContact+AttributedFullName.swift
//  SIMplePhone
//
//  Created by Lukas Kuster on 04.03.19.
//  Copyright © 2019 Lukas Kuster. All rights reserved.
//

import UIKit
import Contacts

extension CNContact {
    public func attributedFullName(fullyBold: Bool = false) -> NSAttributedString {
        
        var displayName = ""
        var nonBoldRange = NSRange(location: 0, length: 0)
        if self.givenName != "" || self.familyName != "" {
            if self.givenName != "" && self.familyName != "" {
                displayName = self.givenName+" "+self.familyName
                nonBoldRange = NSRange(location: 0, length: self.givenName.count)
            }else if self.givenName != "" {
                displayName = self.givenName
            }else{
                displayName = self.familyName
            }
        }else{
            if self.organizationName != "" {
                displayName = self.organizationName
            }
        }
        
        let string = NSMutableAttributedString(string: displayName, attributes: [.font: UIFont.boldSystemFont(ofSize: 17), .foregroundColor: UIColor.black])
        if !fullyBold {
            string.setAttributes([.font: UIFont.systemFont(ofSize: 17)], range: nonBoldRange)
        }
        
        return string
    }
}
