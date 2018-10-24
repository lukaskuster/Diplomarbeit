//
//  AVCaptureState.swift
//  SIMplePhoneKit
//
//  Created by Lukas Kuster on 23.10.18.
//  Copyright © 2018 Lukas Kuster. All rights reserved.
//

import Foundation
import AVFoundation

class AVCaptureState {
    static var isAudioDisabled: Bool {
        let status = AVCaptureDevice.authorizationStatus(for: AVMediaType.audio)
        return status == .restricted || status == .denied
    }
}
