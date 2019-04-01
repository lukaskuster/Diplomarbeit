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

/// Object representing a wireless network
public class SPNetwork: NSObject {
    /// SSID (name) of the network
    public var ssid = ""
    /// Signal strength of the network (RSSI)
    public var rssi: Int
    /// Boolean indicating whether the network is password-protected or not
    public var requiresPassword: Bool
    
    /// SPNetwork Initializer
    ///
    /// - Parameters:
    ///   - ssid: SSID (name) of the network
    ///   - rssi: Signal strength of the network (RSSI)
    ///   - requiresPassword: Boolean indicating whether the network is password-protected or not
    public init(ssid: String, rssi: Int, requiresPassword: Bool) {
        self.ssid = ssid
        self.rssi = rssi
        self.requiresPassword = requiresPassword
    }
}

/// Delegate Protocol of the BLESetupManager
public protocol BLESetupManagerDelegate {
    /// The gateway changed its network connection status.
    ///
    /// - Parameters:
    ///   - manager: Instance of the BLESetupManager used
    ///   - status: New connection status
    ///   - network: The network it is connecting to/is connected to/tried to connect to
    func blesetup(manager: BLESetupManager,
                  didChangeConnectionStatus status: BLESetupManager.Status,
                  with network: SPNetwork)
    /// The client did receive an error while setting up the gateway
    ///
    /// - Parameters:
    ///   - manager: Instance of the BLESetupManager used
    ///   - error: Error that occurred
    func blesetup(manager: BLESetupManager, didReceiveError error: Error)
}

/// Manager used to setup a gateway via Bluetooth LE
public class BLESetupManager: NSObject {
    /// Reference to the class that implemented the delegate protocol
    public var delegate: BLESetupManagerDelegate?
    private var gatewayPeripheral: Peripheral? {
        didSet {
            self.registerStatusListener(for: gatewayPeripheral!)
        }
    }
    private var currentNetwork: SPNetwork?
    
    private let wifiServiceUUID = "ff51b30e-d7e2-4d93-8842-a7c4a57dfb08"
    private let networkCharacteristicUUID = "ff51b30e-d7e2-4d93-8842-a7c4a57dfb09"
    
    /// Enum representing errors that occur while setting up the gateway
    public enum SetupError: Error {
        /// No Gateway found to set up
        case noGatewayToSetupFound
        /// More than one gateway is available to set up
        case moreThanOneGatewayToSetup
        /// Missing the required WPA Key, e.g. wifi password
        case missingWPAKey
        /// Error while parsing a response
        case parsingError
        /// No data available from the gateway
        case noDataFromGateway
        /// No wireless network available to connect to
        case noNetworkToConnectTo
    }
    
    /// Enum representing the state of gateway setup
    public enum Status {
        /// The gateway started connecting to the wireless network
        case connecting
        /// The passed WPA passkey was wrong
        case wrongPSK
        /// The gateway is now connected to the network and registered with the users account
        /// - Parameters:
        ///   - imei: The IMEI of the newly registered SPGateway
        case connected(imei: String)
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
    
    /// Returns all the available networks nearby the gateway
    ///
    /// - Parameter completion: Completion handler that returns all the SPNetwors (if there are any) or an error
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
    
    /// Connects the gateway to the provided SPNetwork
    ///
    /// - Parameters:
    ///   - network: The SPNetwork to which the gateway should be connected
    ///   - psk: The WPA passkey of the network (if required)
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
    
    /// Initiates the search for nearby gateways
    ///
    /// - Parameter completion: Completion handler (returns an error, if there is one)
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
