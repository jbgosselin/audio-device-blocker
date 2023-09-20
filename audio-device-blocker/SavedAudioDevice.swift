//
//  SavedAudioDevice.swift
//  Audio Device Blocker
//
//  Created by Jean-Baptiste Gosselin on 2023-09-18.
//

import Foundation

struct SavedAudioDevice: Codable, Hashable {
    let deviceUID: String
    let name: String
}

extension [SavedAudioDevice]: RawRepresentable {
    public init?(rawValue: String) {
        guard let data = rawValue.data(using: .utf8),
              let result = try? JSONDecoder().decode([Element].self, from: data)
        else {
            return nil
        }
        self = result
    }

    public var rawValue: String {
        guard let data = try? JSONEncoder().encode(self),
              let result = String(data: data, encoding: .utf8)
        else {
            return "[]"
        }
        return result
    }
}


extension [SavedAudioDevice] {
    func hasDevice(_ audioDevice: AudioDevice) -> Bool {
        self.contains { $0.deviceUID == audioDevice.deviceUID }
    }
    
    mutating func addDevice(_ audioDevice: AudioDevice) {
        if self.hasDevice(audioDevice) {
            return
        }
        self.append(SavedAudioDevice(deviceUID: audioDevice.deviceUID, name: audioDevice.name))
    }
    
    mutating func removeDeviceByID(_ id: String) {
        self.removeAll { $0.deviceUID == id }
    }
}
