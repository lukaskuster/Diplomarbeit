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

/// Data object representing a phone number
public class SPNumber: NSObject {
    /// The string representation of the phone call
    @objc public dynamic var phoneNumber = ""
    /// The associated CNContact on the users phone (if there is one)
    @objc public var contact: CNContact? {
        return self.hasContact()
    }
    
    /// Initializes a SPNumber object
    ///
    /// - Parameter phoneNumber: A string representation of the phone call
    public convenience init(withNumber phoneNumber: String) {
        self.init()
        self.phoneNumber = phoneNumber
    }
}

extension SPNumber {
    /// Returns a prettified version of the stored phone number
    ///
    /// - Returns: Prettified version of the phone number
    @objc public func prettyPhoneNumber() -> String {
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
    /// Checks whether a number is equal to another one
    ///
    /// - Parameter phoneNumberString: A string of the other phone number to cross-check
    /// - Returns: Boolean, whether the number is equal or not
    public func isEqual(to phoneNumberString: String) -> Bool {
        do {
            let phonenumberkit = PhoneNumberKit()
            let number = try phonenumberkit.parse(self.phoneNumber)
            let compareNumber = try phonenumberkit.parse(phoneNumberString)
            let formattedNumber = phonenumberkit.format(number, toType: .international, withPrefix: true)
            let formattedCompareNumber = phonenumberkit.format(compareNumber, toType: .international, withPrefix: true)
            if formattedNumber == formattedCompareNumber {
                return true
            }else{
                return false
            }
        } catch {
            return false
        }
    }
}
