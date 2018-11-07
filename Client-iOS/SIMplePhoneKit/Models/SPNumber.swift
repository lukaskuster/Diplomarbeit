//
//  SPNumber.swift
//  SIMplePhoneKit
//
//  Created by Lukas Kuster on 31.10.18.
//  Copyright © 2018 Lukas Kuster. All rights reserved.
//

import Foundation
import Contacts
import ContactsUI
import PhoneNumberKit

public class SPNumber: NSObject {
    @objc public dynamic var phoneNumber = ""
    public var contact: CNContact? {
        return self.hasContact()
    }
    
    public convenience init(withNumber phoneNumber: String) {
        self.init()
        self.phoneNumber = phoneNumber
    }
}

extension SPNumber {
    public func prettyPhoneNumber() -> String {
        do {
            let phonenumberkit = PhoneNumberKit()
            let number = try phonenumberkit.parse(self.phoneNumber)
            return phonenumberkit.format(number, toType: .international, withPrefix: true)
        } catch {
            return ""
        }
    }
    private func hasContact() -> CNContact? {
        do {
            let keys = [CNContactViewController.descriptorForRequiredKeys()]
            let phoneNumber = CNPhoneNumber(stringValue: self.phoneNumber)
            let predicate = CNContact.predicateForContacts(matching: phoneNumber)
            let contactStore = CNContactStore()
            let contacts = try contactStore.unifiedContacts(matching: predicate, keysToFetch: keys)
            
            return contacts.first
        } catch let error as NSError {
            print(error.localizedDescription)
        }
        return nil
    }
}
