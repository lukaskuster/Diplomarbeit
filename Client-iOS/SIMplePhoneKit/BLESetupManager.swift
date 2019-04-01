//
//  BLESetupManager.swift
//  SIMplePhoneKit
//
//  Created by Lukas Kuster on 01.02.19.
//  Copyright © 2019 Lukas Kuster. All rights reserved.
//

import Foundation
import SwiftyBluetooth
import SwiftyJSON
import CoreBluetooth

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

public protocol BLESetupManagerDelegate {
    func blesetup(manager: BLESetupManager,
                  didChangeConnectionStatus status: BLESetupManager.Status,
                  with network: SPNetwork)
    func blesetup(manager: BLESetupManager, didReceiveError error: Error)
}

public class BLESetupManager: NSObject {
    public var delegate: BLESetupManagerDelegate?
    private var gatewayPeripheral: Peripheral? {
        didSet {
            self.registerStatusListener(for: gatewayPeripheral!)
        }
    }
    private var currentNetwork: SPNetwork?
    
    private let wifiServiceUUID = "ff51b30e-d7e2-4d93-8842-a7c4a57dfb08"
    private let networkCharacteristicUUID = "ff51b30e-d7e2-4d93-8842-a7c4a57dfb09"
    
    public enum SetupError: Error {
        case noGatewayToSetupFound
        case moreThanOneGatewayToSetup
        case missingWPAKey
        case parsingError
        case noDataFromGateway
        case noNetworkToConnectTo
    }
    
    public enum Status {
        case connecting
        case wrongPSK
        case connected(imei: String)
    }
    
    public override init() {
        super.init()
    }
    
    deinit {
        self.gatewayPeripheral?.disconnect(completion: { result in
            switch result {
            case .success:
                break
            case .failure(let error):
                self.delegate?.blesetup(manager: self, didReceiveError: error)
            }
        })
    }
    
    public func getAvailableNetworks(completion: @escaping ([SPNetwork]?, Error?) -> Void) {
        guard let gateway = self.gatewayPeripheral else {
            completion(nil, SetupError.noGatewayToSetupFound)
            return
        }
        
        gateway.readValue(ofCharacWithUUID: self.networkCharacteristicUUID, fromServiceWithUUID: self.wifiServiceUUID) { result in
            if let data = result.value {
                do {
                    let json = try JSON(data: data)
                    if let array = json.array {
                        var availableNetworks = [SPNetwork]()
                        for item in array {
                            if let ssid = item["ssid"].string,
                               let rssi = item["rssi"].int,
                               let auth = item["auth"].bool {
                                availableNetworks.append(SPNetwork(ssid: ssid,
                                                                   rssi: rssi,
                                                                   requiresPassword: auth))
                            }
                        }
                        completion(availableNetworks, nil)
                    }else{
                        completion(nil, SetupError.parsingError)
                    }
                } catch {
                    completion(nil, SetupError.parsingError)
                }
            }else{
                completion(nil, SetupError.noDataFromGateway)
            }
        }
    }
    
    public func connect(to network: SPNetwork, password psk: String?) {
        guard let gateway = self.gatewayPeripheral else {
            self.delegate?.blesetup(manager: self, didReceiveError: SetupError.noGatewayToSetupFound)
            return
        }

        do {
            self.currentNetwork = network
            var data: [String: Any] = ["ssid": network.ssid]
            if let psk = psk {
                data["psk"] = psk
            }
            let json = JSON(data)
            let networkData = try json.rawData()
            
            self.write(service: self.wifiServiceUUID, characteristic: self.networkCharacteristicUUID, data: networkData, gateway: gateway) { error in
                if let error = error {
                    self.delegate?.blesetup(manager: self, didReceiveError: error)
                }
            }
        } catch {
            self.delegate?.blesetup(manager: self, didReceiveError: SetupError.parsingError)
        }
    }
    
    public func getGateway(completion: @escaping (Error?) -> Void) {
        SwiftyBluetooth.scanForPeripherals(timeoutAfter: 10) { scanResult in
            switch scanResult {
            case .scanStarted:
                print("scanning ble devices nearby started")
            case .scanResult(let peripheral, _, _):
                print(peripheral.name ?? "ble device w/o name")
                if peripheral.name == "Gateway" {
                    print("found device \(peripheral.identifier)")
                    self.gatewayPeripheral = peripheral
                    SwiftyBluetooth.stopScan()
                }
            case .scanStopped(let error):
                if let error = error {
                    completion(error)
                }
                if self.gatewayPeripheral != nil {
                    completion(nil)
                }else{
                    completion(SetupError.noGatewayToSetupFound)
                }
            }
        }
    }
    
    private func registerStatusListener(for peripheral: Peripheral) {
        NotificationCenter.default.addObserver(forName: Peripheral.PeripheralCharacteristicValueUpdate, object: peripheral, queue: nil) { notification in
            let charac = notification.userInfo!["characteristic"] as! CBCharacteristic
            if let error = notification.userInfo?["error"] as? SBError {
                self.delegate?.blesetup(manager: self, didReceiveError: error)
            }
            if let data = charac.value {
                do {
                    let json = try JSON(data: data)
                    switch charac.uuid.uuidString {
                    case self.networkCharacteristicUUID:
                        self.networkSetupStatusChanged(to: json)
                    default:
                        break
                    }
                } catch {
                    self.delegate?.blesetup(manager: self, didReceiveError: SetupError.parsingError)
                }
            }
        }
        
        peripheral.setNotifyValue(toEnabled: true, forCharacWithUUID: self.networkCharacteristicUUID, ofServiceWithUUID: self.wifiServiceUUID) { result in
            switch result {
            case .success(_):
                break
            case .failure(let error):
                self.delegate?.blesetup(manager: self, didReceiveError: error)
            }
        }
    }
    
    private func networkSetupStatusChanged(to json: JSON) {
        // To-Do: Add json status handling
        if let network = self.currentNetwork {
            self.delegate?.blesetup(manager: self, didChangeConnectionStatus: .connected(imei: "74257643756747"), with: network)
        }else{
            self.delegate?.blesetup(manager: self, didReceiveError: SetupError.noNetworkToConnectTo)
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
