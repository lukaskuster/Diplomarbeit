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
        do {
            let oldSdp = self.sdp
            let regex = try NSRegularExpression(pattern: "((a=fmtp:111 minptime=10;useinbandfec=1|a=rtcp-fb:111 transport-cc|a=rtpmap:(?!8 PCMA))([^\n]*))(\n*)", options: [.caseInsensitive, .dotMatchesLineSeparators])
            let range = NSMakeRange(0, oldSdp.count)
            let modSdp = regex.stringByReplacingMatches(in: oldSdp, options: [], range: range, withTemplate: "")
            return RTCSessionDescription(type: self.type, sdp: modSdp)
        } catch {
            return self
        }
    }
}
