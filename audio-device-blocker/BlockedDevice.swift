//
//  BlockedDevice.swift
//  AudioDeviceBlocker
//
//  Created by Jean-Baptiste Gosselin on 2023-09-23.
//

import Foundation

extension BlockedDevice {
    var direction: AudioStreamDirection {
        get { AudioStreamDirection(rawValue: UInt32(self.rawDirection))! }
        set { self.rawDirection = Int16(newValue.rawValue) }
    }
}

extension Collection where Element: BlockedDevice {
    func hasDevice(_ audioDevice: AudioDevice) -> Bool {
        self.contains { $0.deviceUID == audioDevice.deviceUID }
    }
}
