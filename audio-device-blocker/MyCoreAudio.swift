//
//  MyCoreAudio.swift
//  Audio Device Blocker
//
//  Created by Jean-Baptiste Gosselin on 2023-09-17.
//

import CoreAudio

func fetchAudioProperty<T>(audioObjectID: AudioObjectID, mSelector: AudioObjectPropertySelector, mScope: AudioObjectPropertyScope) -> T? {
    // audioPropertyAddress describes what property we want to query
    var audioPropertyAddress = AudioObjectPropertyAddress(
        mSelector: mSelector,
        mScope: mScope,
        mElement: kAudioObjectPropertyElementMain
    )

    var dataSize = UInt32(MemoryLayout<T>.size)
    let boundPtr = UnsafeMutablePointer<T>.allocate(capacity: 1)
    defer { boundPtr.deallocate() }
    
    let dataResult = AudioObjectGetPropertyData(
        audioObjectID,
        &audioPropertyAddress,
        0, nil,
        &dataSize, boundPtr
    )
    if dataResult != kAudioHardwareNoError {
        print("Error occured calling AudioObjectGetPropertyData for \(audioObjectID) \(mSelector) \(mScope): \(dataResult)")
        return nil
    }
    
    return boundPtr.pointee
}

func fetchAudioArrayProperty<T>(audioObjectID: AudioObjectID, mSelector: AudioObjectPropertySelector, mScope: AudioObjectPropertyScope) -> Array<T>? {
    // audioPropertyAddress describes what property we want to query
    var audioPropertyAddress = AudioObjectPropertyAddress(
        mSelector: mSelector,
        mScope: mScope,
        mElement: kAudioObjectPropertyElementMain
    )
    
    var dataSize: UInt32 = 0
    
    let dataSizeResult = AudioObjectGetPropertyDataSize(
        audioObjectID,
        &audioPropertyAddress,
        0, nil,
        &dataSize
    )
    if dataSizeResult != kAudioHardwareNoError {
        print("Error occured calling AudioObjectGetPropertyDataSize for kAudioDevicePropertyStreams \(audioObjectID) \(mSelector) \(mScope): \(dataSizeResult)")
        return nil
    }
    
    let elementCount = Int(dataSize) / MemoryLayout<T>.size
    if elementCount <= 0 {
        return Array()
    }
    
    let boundPtr = UnsafeMutablePointer<T>.allocate(capacity: elementCount)
    defer { boundPtr.deallocate() }
    
    let dataResult = AudioObjectGetPropertyData(
        audioObjectID,
        &audioPropertyAddress,
        0, nil,
        &dataSize, boundPtr
    )
    if dataResult != kAudioHardwareNoError {
        print("Error occured calling AudioObjectGetPropertyData for kAudioDevicePropertyStreams \(audioObjectID) \(mSelector) \(mScope): \(dataResult)")
        return nil
    }
        
    return Array(UnsafeBufferPointer(start: boundPtr, count: elementCount))
}

enum AudioStreamDirection: UInt32 {
    case output = 0
    case input = 1
}

struct AudioStream: Hashable {
    let audioStreamID: AudioStreamID
    let direction: AudioStreamDirection
    
    init?(audioStreamID: AudioStreamID) {
        self.audioStreamID = audioStreamID
                
        guard let direction = fetchAudioProperty(audioObjectID: audioStreamID, mSelector: kAudioStreamPropertyDirection, mScope: kAudioObjectPropertyScopeGlobal).flatMap({ AudioStreamDirection(rawValue: $0) }) else {
            return nil
        }
        self.direction = direction
    }
}

struct AudioDevice: Hashable {
    let id: AudioObjectID
    let name: String
    let deviceUID: String
    let audioStreams: Array<AudioStream>
    
    init?(audioObjectID: AudioObjectID) {
        self.id = audioObjectID
        guard let name: CFString = fetchAudioProperty(audioObjectID: audioObjectID, mSelector: kAudioDevicePropertyDeviceNameCFString, mScope: kAudioObjectPropertyScopeGlobal) else {
            return nil
        }
        self.name = name as String
        
        guard let deviceUID: CFString = fetchAudioProperty(audioObjectID: audioObjectID, mSelector: kAudioDevicePropertyDeviceUID, mScope: kAudioObjectPropertyScopeGlobal) else {
            return nil
        }
        self.deviceUID = deviceUID as String
        
        guard let audioStreamsIDs: Array<AudioStreamID> = fetchAudioArrayProperty(audioObjectID: audioObjectID, mSelector: kAudioDevicePropertyStreams, mScope: kAudioObjectPropertyScopeGlobal) else {
            return nil
        }
        self.audioStreams = audioStreamsIDs.compactMap { AudioStream(audioStreamID: $0) }
    }
    
    func isDirection(direction: AudioStreamDirection) -> Bool {
        self.audioStreams.contains { $0.direction == direction }
    }
}

func listAudioDevices(direction: AudioStreamDirection) -> Array<AudioDevice>? {
    return listAudioDevices()?.filter { $0.isDirection(direction: direction) }
}

func listAudioDevices() -> Array<AudioDevice>? {
    guard let audioDevicesIDs: Array<AudioDeviceID> = fetchAudioArrayProperty(
        audioObjectID: AudioObjectID(kAudioObjectSystemObject),
        mSelector: kAudioHardwarePropertyDevices,
        mScope: kAudioObjectPropertyScopeGlobal
    ) else {
        return nil
    }
    return audioDevicesIDs.compactMap { AudioDevice(audioObjectID: $0) }
}

func fetchSpecificDevice(mSelector: AudioObjectPropertySelector) -> AudioDevice? {
    guard let audioDeviceID: AudioDeviceID = fetchAudioProperty(
        audioObjectID: AudioObjectID(kAudioObjectSystemObject),
        mSelector: mSelector,
        mScope: kAudioObjectPropertyScopeGlobal
    ) else {
        return nil
    }
    return AudioDevice(audioObjectID: audioDeviceID)
}

func setDefaultDevice(mSelector: AudioObjectPropertySelector, audioObjectID: AudioObjectID) -> Bool {
    // audioPropertyAddress describes what property we want to query
    var audioPropertyAddress = AudioObjectPropertyAddress(
        mSelector: mSelector,
        mScope: kAudioObjectPropertyScopeGlobal,
        mElement: kAudioObjectPropertyElementMain
    )
    
    let dataSize = UInt32(MemoryLayout<AudioObjectID>.size)
    var objectID = audioObjectID
    
    let dataResult = AudioObjectSetPropertyData(
        AudioObjectID(kAudioObjectSystemObject),
        &audioPropertyAddress,
        0, nil,
        dataSize, &objectID
    )
    
    if dataResult != kAudioHardwareNoError {
        print("Error occured calling AudioObjectSetPropertyData for \(mSelector) \(audioObjectID): \(dataResult)")
        return false
    }
    
    return true
}
