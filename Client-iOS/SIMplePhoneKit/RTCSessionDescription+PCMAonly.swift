//
//  RTCSessionDescription+PCMAonly.swift
//  SIMplePhoneKit
//
//  Created by Lukas Kuster on 14.01.19.
//  Copyright © 2019 Lukas Kuster. All rights reserved.
//

import Foundation
import WebRTC

extension RTCSessionDescription {
    /**
     Workaround for missing RTCRtpTransceiver.setCodecPreferences() in WebRTC.framework
     */
    public var PCMAonly: RTCSessionDescription {
        let regex = try! NSRegularExpression(pattern: "a=rtpmap:(?!8 PCMA)(.*)\n", options: NSRegularExpression.Options.caseInsensitive)
        let range = NSMakeRange(0, self.sdp.count)
        let modSdp = regex.stringByReplacingMatches(in: self.sdp, options: [], range: range, withTemplate: "")
        return RTCSessionDescription(type: self.type, sdp: modSdp)
    }
}
