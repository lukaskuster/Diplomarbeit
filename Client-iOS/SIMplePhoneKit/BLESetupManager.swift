//
//  BLESetupManager.swift
//  SIMplePhoneKit
//
//  Created by Lukas Kuster on 01.02.19.
//  Copyright © 2019 Lukas Kuster. All rights reserved.
//

import Foundation
import SwiftyBluetooth

public class SPNetwork: NSObject {
    public var ssid = ""
    public var rssi: Int
    public var requiresPassword: Bool
    
    public init(ssid: String, rssi: Int, requiresPassword: Bool) {
        self.ssid = ssid
        self.rssi = rssi
        self.requiresPassword = requiresPassword
    }
}

public class BLESetupManager: NSObject {
    private var gatewayPeripheral: Peripheral?
    
    private let wifiServiceUUID = "ff51b30e-d7e2-4d93-8842-a7c4a57dfb08"
    private let ssidCharacteristicUUID = "ff51b30e-d7e2-4d93-8842-a7c4a57dfb09"
    private let wpaCharacteristicUUID = "ff51b30e-d7e2-4d93-8842-a7c4a57dfb0a"
    
    public enum BLESetupError: Error {
        case noGatewayToSetupFound
        case moreThanOneGatewayToSetup
        case missingWPAKey
    }
    
    public override init() {
        super.init()
    }
    
    public func getAvailableNetworks(completion: @escaping ([SPNetwork]?, Error?) -> Void) {
        self.getGateway { gateway, error in
            if let error = error {
                completion(nil, error)
            }
            guard let gateway = gateway else {
                completion(nil, BLESetupError.noGatewayToSetupFound)
                return
            }
            self.gatewayPeripheral = gateway
            
            self.connect(to: gateway, completion: { error in
                if let error = error {
                    completion(nil, error)
                }
                
                let data = "Quentin stinkt!".data(using: .utf8)!
                self.write(service: self.wifiServiceUUID, characteristic: self.wpaCharacteristicUUID, data: data, gateway: gateway, completion: { error in
                    if let error = error {
                        completion(nil, error)
                    }
                    
                    self.disconnect(from: gateway, completion: { error in
                        completion(nil, error)
                    })
                })
                
                
            })
            
        }
    }
    
    public func connect(to network: SPNetwork, password wpa: String?, completion: @escaping (Error?) -> Void) {
        guard let gateway = self.gatewayPeripheral else {
            completion(BLESetupError.noGatewayToSetupFound)
            return
        }
        
        let ssidData = network.ssid.data(using: .utf8)!
        self.write(service: self.wifiServiceUUID, characteristic: self.ssidCharacteristicUUID, data: ssidData, gateway: gateway) { error in
            if let error = error {
                completion(error)
            }
            
            if network.requiresPassword {
                if let wpa = wpa {
                    let wpaData = wpa.data(using: .utf8)!
                    self.write(service: self.wifiServiceUUID, characteristic: self.wpaCharacteristicUUID, data: wpaData, gateway: gateway, completion: completion)
                }else{
                    completion(BLESetupError.missingWPAKey)
                }
            }else{
                completion(nil)
            }
        }
    }
    
    private func getGateway(completion: @escaping (Peripheral?, Error?) -> Void) {
        var discoveredGateway: Peripheral?
        SwiftyBluetooth.scanForPeripherals(timeoutAfter: 10) { scanResult in
            switch scanResult {
            case .scanStarted:
                print("scanning ble devices nearby started")
            case .scanResult(let peripheral, _, _):
                if peripheral.name == "raspberrypi" {
                    print("found device \(peripheral.identifier)")
                    discoveredGateway = peripheral
                    SwiftyBluetooth.stopScan()
                }
            case .scanStopped(let error):
                if let error = error {
                    completion(nil, error)
                }
                if let gateway = discoveredGateway {
                    completion(gateway, nil)
                }else{
                    completion(nil, BLESetupError.noGatewayToSetupFound)
                }
            }
        }
    }
    
    private func connect(to gateway: Peripheral, completion: @escaping (Error?) -> Void) {
        gateway.connect(withTimeout: 10) { result in
            switch result {
            case .success:
                completion(nil)
            case .failure(let error):
                completion(error)
            }
        }
    }
    
    private func write(service: CBUUIDConvertible, characteristic: CBUUIDConvertible, data: Data, gateway: Peripheral, completion: @escaping (Error?) -> Void) {
        gateway.writeValue(ofCharacWithUUID: characteristic, fromServiceWithUUID: service, value: data) { result in
            switch result {
            case .success:
                completion(nil)
            case .failure(let error):
                completion(error)
            }
        }
    }
    
    private func disconnect(from gateway: Peripheral, completion: @escaping (Error?) -> Void) {
        gateway.disconnect { result in
            switch result {
            case .success:
                completion(nil)
            case .failure(let error):
                completion(error)
            }
        }
    }
    
}
