//
//  SIMplePhoneKitTests.swift
//  SIMplePhoneKitTests
//
//  Created by Lukas Kuster on 04.04.19.
//  Copyright © 2019 Lukas Kuster. All rights reserved.
//

import XCTest
import SIMplePhoneKit

class SIMplePhoneKitTests: XCTestCase {

    let testCredentials = (username: "mail@lukaskuster.com",
                           password: "test123",
                           environment: SPManager.SPKeychainEnvironment.local)
    
    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    func testRegisterAccount() {
        let account = SPAccount(givenName: "Lukas",
                                familyName: "Kuster",
                                username: "testuser@lukaskuster.com",
                                password: "test123")
        SPManager.shared.registerNewAccount(account, keychainEnvironment: .local) { (success, error) in
            if let error = error {
                if let desc = error.errorDescription {
                    XCTFail(desc)
                }else{
                    XCTFail()
                }
            }
            
            SPManager.shared.deleteAccount { error in
                if let error = error {
                    if let desc = error.errorDescription {
                        XCTFail(desc)
                    }else{
                        XCTFail()
                    }
                }
            }
        }
    }
    
    func testDeleteAccount() {
        SPManager.shared.loginUser(username: testCredentials.username,
                                   password: testCredentials.password,
                                   keychainEnvironment: testCredentials.environment) { (success, error) in
            if let error = error {
                if let desc = error.errorDescription {
                    XCTFail(desc)
                }else{
                    XCTFail()
                }
            }
                                    
            SPManager.shared.deleteAccount { error in
                if let error = error {
                    if let desc = error.errorDescription {
                        XCTFail(desc)
                    }else{
                        XCTFail()
                    }
                }
            }
        }
    }
    
    func testLogin() {
        SPManager.shared.loginUser(username: testCredentials.username,
                                   password: testCredentials.password,
                                   keychainEnvironment: testCredentials.environment) { (success, error) in
            if let error = error {
                if let desc = error.errorDescription {
                    XCTFail(desc)
                }else{
                    XCTFail()
                }
            }
        }
    }
    
    

}
