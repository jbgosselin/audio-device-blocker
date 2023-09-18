//
//  SavedAudioDeviceList.swift
//  Audio Device Blocklist
//
//  Created by Jean-Baptiste Gosselin on 2023-09-18.
//

import Foundation

struct SavedAudioDevice: Codable, Identifiable {
    let id: String
    let name: String
}

typealias SavedAudioDeviceList = Array<SavedAudioDevice>

extension Array: RawRepresentable where Element: Codable {
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


extension SavedAudioDeviceList {
    func hasDevice(audioDevice: AudioDevice) -> Bool {
        self.contains { $0.id == audioDevice.deviceUID }
    }
    
    mutating func addDevice(audioDevice: AudioDevice) {
        if self.hasDevice(audioDevice: audioDevice) {
            return
        }
        self.append(SavedAudioDevice(id: audioDevice.deviceUID, name: audioDevice.name))
    }
    
    mutating func removeDeviceByID(id: String) {
        if let idx = self.firstIndex(where: { $0.id == id }) {
            self.remove(at: idx)
        }
    }
    
    mutating func moveBefore(id: String) {
        guard let idx = self.firstIndex(where: { $0.id == id }), idx > 0 else {
            return
        }
        self.swapAt(idx, idx-1)
    }
    
    mutating func moveAfter(id: String) {
        guard let idx = self.firstIndex(where: { $0.id == id }), idx < (self.count-1) else {
            return
        }
        self.swapAt(idx, idx+1)
    }
}
