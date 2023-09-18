//
//  MyAudioCore.swift
//  Audio Device Blocklist
//
//  Created by Jean-Baptiste Gosselin on 2023-09-17.
//

import CoreAudio

func fetchAudioUInt32Property(audioObjectID: AudioObjectID, mSelector: AudioObjectPropertySelector, mScope: AudioObjectPropertyScope) -> UInt32? {
    var audioPropertyAddress = AudioObjectPropertyAddress(
        mSelector: mSelector,
        mScope: mScope,
        mElement: kAudioObjectPropertyElementMain
    )
    
    var property: UInt32 = 0
    var dataSize = UInt32(MemoryLayout<UInt32>.size)
    
    let dataResult = AudioObjectGetPropertyData(
        audioObjectID,
        &audioPropertyAddress,
        0, nil,
        &dataSize, &property
    )
    if dataResult != kAudioHardwareNoError {
        print("Error occured calling AudioObjectGetPropertyData for \(audioObjectID) \(mSelector) \(mScope): \(dataResult)")
        return nil
    }
    
    return property
}

func fetchAudioStringProperty(audioObjectID: AudioObjectID, mSelector: AudioObjectPropertySelector, mScope: AudioObjectPropertyScope) -> String? {
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
        print("Error occured calling AudioObjectGetPropertyDataSize for \(audioObjectID) \(mSelector) \(mScope): \(dataSizeResult)")
        return nil
    }
    
    var stringBuffer: Unmanaged<CFString>?
    
    let dataResult = AudioObjectGetPropertyData(
        audioObjectID,
        &audioPropertyAddress,
        0, nil,
        &dataSize, &stringBuffer
    )
    if dataResult != kAudioHardwareNoError {
        print("Error occured calling AudioObjectGetPropertyData for \(audioObjectID) \(mSelector) \(mScope): \(dataResult)")
        return nil
    }
    
    return stringBuffer?.takeRetainedValue() as? String
}

enum AudioStreamDirection: UInt32 {
    case output = 0
    case input = 1
}

class AudioStream {
    let audioStreamID: AudioStreamID
    let direction: AudioStreamDirection
    
    init?(audioStreamID: AudioStreamID) {
        self.audioStreamID = audioStreamID
                
        guard let direction = fetchAudioUInt32Property(audioObjectID: audioStreamID, mSelector: kAudioStreamPropertyDirection, mScope: kAudioObjectPropertyScopeGlobal).flatMap({ AudioStreamDirection(rawValue: $0) }) else {
            return nil
        }
        self.direction = direction
    }
}

class AudioDevice: Identifiable {
    let id: AudioObjectID
    let name: String
    let deviceUID: String
    let audioStreams: Array<AudioStream>
    
    init?(audioObjectID: AudioObjectID) {
        self.id = audioObjectID
        guard let name = fetchAudioStringProperty(audioObjectID: audioObjectID, mSelector: kAudioDevicePropertyDeviceNameCFString, mScope: kAudioObjectPropertyScopeGlobal) else {
            return nil
        }
        self.name = name
        
        guard let deviceUID = fetchAudioStringProperty(audioObjectID: audioObjectID, mSelector: kAudioDevicePropertyDeviceUID, mScope: kAudioObjectPropertyScopeGlobal) else {
            return nil
        }
        self.deviceUID = deviceUID
        
        guard let audioStreams = listAudioStreams(audioObjectID: audioObjectID) else {
            return nil
        }
        self.audioStreams = audioStreams
    }
    
    func isDirection(direction: AudioStreamDirection) -> Bool {
        self.audioStreams.contains { $0.direction == direction }
    }
}

func listAudioStreams(audioObjectID: AudioObjectID) -> Array<AudioStream>? {
    // audioPropertyAddress describes what property we want to query
    var audioPropertyAddress = AudioObjectPropertyAddress(
        mSelector: kAudioDevicePropertyStreams,
        mScope: kAudioObjectPropertyScopeGlobal,
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
        print("Error occured calling AudioObjectGetPropertyDataSize for kAudioDevicePropertyStreams \(audioObjectID): \(dataSizeResult)")
        return nil
    }
    
    let streamCount = Int(dataSize) / MemoryLayout<AudioStreamID>.size
    if streamCount <= 0 {
        return Array()
    }
    
    let audioStreamsBuffer = UnsafeMutableRawPointer.allocate(byteCount: Int(dataSize), alignment: 0)
    
    let dataResult = AudioObjectGetPropertyData(
        audioObjectID,
        &audioPropertyAddress,
        0, nil,
        &dataSize, audioStreamsBuffer
    )
    if dataResult != kAudioHardwareNoError {
        print("Error occured calling AudioObjectGetPropertyData for kAudioDevicePropertyStreams \(audioObjectID): \(dataResult)")
        return nil
    }
    
    let audioStreamsIDs = Array(audioStreamsBuffer.withMemoryRebound(to: AudioStreamID.self, capacity: streamCount) {
        UnsafeBufferPointer(start: $0, count: streamCount)
    })
    
    return audioStreamsIDs.compactMap { AudioStream(audioStreamID: $0) }
}

func listAudioDevices(direction: AudioStreamDirection) -> Array<AudioDevice>? {
    return listAudioDevices()?.filter { $0.isDirection(direction: direction) }
}

func listAudioDevices() -> Array<AudioDevice>? {
    // audioPropertyAddress describes what property we want to query
    var audioPropertyAddress = AudioObjectPropertyAddress(
        mSelector: kAudioHardwarePropertyDevices,
        mScope: kAudioObjectPropertyScopeGlobal,
        mElement: kAudioObjectPropertyElementMain
    )
    
    var dataSize: UInt32 = 0
    
    let dataSizeResult = AudioObjectGetPropertyDataSize(
        AudioObjectID(kAudioObjectSystemObject),
        &audioPropertyAddress,
        0, nil,
        &dataSize
    )
    if dataSizeResult != kAudioHardwareNoError {
        print("Error occured calling AudioObjectGetPropertyDataSize for kAudioHardwarePropertyDevices: \(dataSizeResult)")
        return nil
    }
    
    let deviceCount = Int(dataSize) / MemoryLayout<AudioObjectID>.size
    if deviceCount <= 0 {
        return Array()
    }
    
    let audioDevicesBuffer = UnsafeMutableRawPointer.allocate(byteCount: Int(dataSize), alignment: 0)
    
    let dataResult = AudioObjectGetPropertyData(
        AudioObjectID(kAudioObjectSystemObject),
        &audioPropertyAddress,
        0, nil,
        &dataSize, audioDevicesBuffer
    )
    if dataResult != kAudioHardwareNoError {
        print("Error occured calling AudioObjectGetPropertyData for kAudioHardwarePropertyDevices: \(dataResult)")
        return nil
    }
    
    let audioDevicesIDs = Array(audioDevicesBuffer.withMemoryRebound(to: AudioDeviceID.self, capacity: deviceCount) {
        UnsafeBufferPointer(start: $0, count: deviceCount)
    })
    
    return audioDevicesIDs.compactMap { AudioDevice(audioObjectID: $0) }
}

func fetchSpecificDevice(mSelector: AudioObjectPropertySelector) -> AudioDevice? {
    // audioPropertyAddress describes what property we want to query
    var audioPropertyAddress = AudioObjectPropertyAddress(
        mSelector: mSelector,
        mScope: kAudioObjectPropertyScopeGlobal,
        mElement: kAudioObjectPropertyElementMain
    )
    
    var dataSize = UInt32(MemoryLayout<AudioDeviceID>.size)
    var audioDeviceID: AudioDeviceID = 0
    
    let dataResult = AudioObjectGetPropertyData(
        AudioObjectID(kAudioObjectSystemObject),
        &audioPropertyAddress,
        0, nil,
        &dataSize, &audioDeviceID
    )
    if dataResult != kAudioHardwareNoError {
        print("Error occured calling AudioObjectGetPropertyData for \(mSelector): \(dataResult)")
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
