//
//  SavedFallbackDevice.swift
//  AudioDeviceBlocker
//
//  Created by Jean-Baptiste Gosselin on 2023-09-23.
//

import CoreData

protocol SavedFallbackDevice: NSManagedObject {
    var name: String? { get set }
    var deviceUID: String? { get set }
    var idx: Int64 { get set }
}

extension Collection where Element: SavedFallbackDevice {
    func hasDevice(_ audioDevice: AudioDevice) -> Bool {
        self.contains { $0.deviceUID == audioDevice.deviceUID }
    }
}

extension InputFallbackDevice: SavedFallbackDevice {}

extension OutputFallbackDevice: SavedFallbackDevice {}
