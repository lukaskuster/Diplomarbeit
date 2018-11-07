//
//  WebRTCTestViewController.swift
//  SIMplePhone
//
//  Created by Lukas Kuster on 22.10.18.
//  Copyright © 2018 Lukas Kuster. All rights reserved.
//

import UIKit
import SIMplePhoneKit
import WebRTC

class WebRTCTestViewController: UIViewController, SignalingClientDelegate, RTCClientDelegate {    
    @IBOutlet weak var usernameField: UITextField!
    @IBOutlet weak var passwordField: UITextField!
    @IBOutlet weak var logField: UITextView!

    var signaling: SignalingClient?
    var rtc: RTCClient?
    
    var sdpOfferString: String = ""
    
//    let iceServers = [RTCIceServer(urlStrings: <#T##[String]#>, username: <#T##String?#>, credential: <#T##String?#>)]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.usernameField.text = "quentin@wendegass.com"
        self.passwordField.text = "test123"
        
        self.setupRTC()
    }
    
    func setupRTC() {
        let ice = [RTCIceServer(urlStrings: ["stun.l.google.com:19302"])]
        self.rtc = RTCClient(iceServers: ice)
        self.rtc?.delegate = self
    }
    
    @IBAction func clickAnswer(_ sender: Any) {
        let username = self.usernameField.text!
        let password = self.passwordField.text!
        
        self.signaling = SignalingClient(username: username, password: password, type: .answer)
        self.signaling?.delegate = self
        self.signaling?.connect()
    }
    
    @IBAction func clickOffer(_ sender: Any) {
        let username = self.usernameField.text!
        let password = self.passwordField.text!
        
        self.signaling = SignalingClient(username: username, password: password, type: .answer)
        self.signaling?.delegate = self
        self.signaling?.connect()
        self.rtc?.makeOffer()
        
//        self.signaling = SignalingClient(username: username, password: password, type: .offer)
//        self.signaling?.delegate = self
//        self.signaling?.connect()
//
//        self.signaling?.sendOffer(withSdp: "test")
    }
    
    func signalingClient(client: SignalingClient, didReceiveOfferWithSdp sdp: String) {
        self.lprint("Received Offer: \(sdp)")
        
        self.rtc?.startConnection()
        self.rtc?.createAnswerForOfferReceived(withRemoteSDP: sdp)
        
    }
    
    func signalingClient(client: SignalingClient, didAuthenticateOnServer authenticated: Bool, error: SignalingClientError?) {
        if authenticated {
            self.lprint("Authenticated on Server...")
        }else{
            self.lprint("Auth-Error: \(error!)")
        }
    }
    
    func rtcClient(client: RTCClient, startCallWithSdp sdp: String) {
        self.signaling?.respondToOffer(withLocalSdp: sdp)
    }
    
    func rtcClient(client: RTCClient, didGenerateIceCandidates iceCandidates: [RTCIceCandidate]) {
//        self.lprint("didGenerateIceCandidate")
        print("didGenerateIceCandidate")
        debugPrint(iceCandidates)
//        print(iceCandidate)
    }
    
    func rtcClient(client: RTCClient, didReceiveError error: Error) {
//        self.lprint("didReceiveError")
        print("didReceiveError")
        print(error)
    }
    
    func rtcClient(client: RTCClient, didChangeState state: RTCClientState) {
        print(state)
        DispatchQueue.main.async {
            self.lprint("RTCClientState: \(state)")
        }
    }
    
    func rtcClient(client: RTCClient, didChangeConnectionState connectionState: RTCIceConnectionState) {
        print(connectionState)
        var state = ""
        switch connectionState {
        case .checking:
            state = "checking"
        case .new:
            state = "new"
        case .connected:
            state = "connected"
        case .completed:
            state = "completed"
        case .failed:
            state = "failed"
        case .disconnected:
            state = "disconnected"
            self.rtc?.disconnect()
        case .closed:
            state = "closed"
        case .count:
            state = "count"
        }
        DispatchQueue.main.async {
            self.lprint("RTCIceConnectionState: \(state)")
        }
    }
    

    
    func lprint(_ object: String) {
        if self.logField.text == "Log" {
            self.logField.text = ""
        }
        self.logField.text = "\(object)\n"+self.logField.text
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
