//
//  MyCoreAudio.swift
//  Audio Device Blocker
//
//  Created by Jean-Baptiste Gosselin on 2023-09-17.
//

import CoreAudio

func fetchAudioProperty<T>(audioObjectID: AudioObjectID, mSelector: AudioObjectPropertySelector) -> T? {
    // audioPropertyAddress describes what property we want to query
    var audioPropertyAddress = AudioObjectPropertyAddress(
        mSelector: mSelector,
        mScope: kAudioObjectPropertyScopeGlobal,
        mElement: kAudioObjectPropertyElementMain
    )
    var dataSize = UInt32(MemoryLayout<T>.size)
    
    let (dataResult, value) = withUnsafeTemporaryAllocation(of: T.self, capacity: 1) { ptr in
        let dataResult = AudioObjectGetPropertyData(
            audioObjectID,
            &audioPropertyAddress,
            0, nil,
            &dataSize, ptr.baseAddress!
        )
        return (dataResult, ptr[0])
    }

    if dataResult != kAudioHardwareNoError {
        print("Error occured calling AudioObjectGetPropertyData for \(audioObjectID) \(mSelector): \(dataResult)")
        return nil
    }
    
    return value
}

func fetchAudioArrayProperty<T>(audioObjectID: AudioObjectID, mSelector: AudioObjectPropertySelector) -> [T]? {
    // audioPropertyAddress describes what property we want to query
    var audioPropertyAddress = AudioObjectPropertyAddress(
        mSelector: mSelector,
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
        print("Error occured calling AudioObjectGetPropertyDataSize for kAudioDevicePropertyStreams \(audioObjectID) \(mSelector): \(dataSizeResult)")
        return nil
    }
    
    let elementCount = Int(dataSize) / MemoryLayout<T>.size
    if elementCount <= 0 {
        return []
    }
    
    let (dataResult, values) = withUnsafeTemporaryAllocation(of: T.self, capacity: elementCount) { ptr in
        let dataResult = AudioObjectGetPropertyData(
            audioObjectID,
            &audioPropertyAddress,
            0, nil,
            &dataSize, ptr.baseAddress!
        )
        return (dataResult, Array(ptr))
    }
    
    if dataResult != kAudioHardwareNoError {
        print("Error occured calling AudioObjectGetPropertyData for kAudioDevicePropertyStreams \(audioObjectID) \(mSelector): \(dataResult)")
        return nil
    }
        
    return values
}

func setAudioProperty<T>(audioObjectID: AudioObjectID, mSelector: AudioObjectPropertySelector, value: T) -> Bool {
    // audioPropertyAddress describes what property we want to query
    var audioPropertyAddress = AudioObjectPropertyAddress(
        mSelector: mSelector,
        mScope: kAudioObjectPropertyScopeGlobal,
        mElement: kAudioObjectPropertyElementMain
    )
    let dataSize = UInt32(MemoryLayout<AudioObjectID>.size)
    
    let dataResult = withUnsafePointer(to: value) { ptr in
        return AudioObjectSetPropertyData(
            audioObjectID,
            &audioPropertyAddress,
            0, nil,
            dataSize, ptr
        )
    }

    if dataResult != kAudioHardwareNoError {
        print("Error occured calling AudioObjectSetPropertyData for \(audioObjectID) \(mSelector): \(dataResult)")
        return false
    }
    
    return true
}

enum AudioStreamDirection: UInt32 {
    case output = 0
    case input = 1
    
    var kAudioHardwarePropertyDefaultDevice: AudioObjectPropertySelector {
        switch self {
        case .input:
            kAudioHardwarePropertyDefaultInputDevice
        case .output:
            kAudioHardwarePropertyDefaultOutputDevice
        }
    }
}

extension AudioStreamDirection: CustomStringConvertible {
    var description: String {
        switch self {
        case .input:
            "INPUT"
        case .output:
            "OUTPUT"
        }
    }
}

struct AudioStream: Hashable {
    let audioStreamID: AudioStreamID
    let direction: AudioStreamDirection
    
    init?(audioStreamID: AudioStreamID) {
        self.audioStreamID = audioStreamID
                
        guard let direction = fetchAudioProperty(
            audioObjectID: audioStreamID,
            mSelector: kAudioStreamPropertyDirection
        ).flatMap({ AudioStreamDirection(rawValue: $0) }) else {
            return nil
        }
        self.direction = direction
    }
}

struct AudioDevice: Hashable {
    let id: AudioObjectID
    let name: String
    let deviceUID: String
    let audioStreams: [AudioStream]
    
    init?(audioObjectID: AudioObjectID) {
        self.id = audioObjectID
        guard let name: CFString = fetchAudioProperty(
            audioObjectID: audioObjectID,
            mSelector: kAudioDevicePropertyDeviceNameCFString
        ) else {
            return nil
        }
        self.name = name as String
        
        guard let deviceUID: CFString = fetchAudioProperty(
            audioObjectID: audioObjectID,
            mSelector: kAudioDevicePropertyDeviceUID
        ) else {
            return nil
        }
        self.deviceUID = deviceUID as String
        
        guard let audioStreamsIDs: [AudioStreamID] = fetchAudioArrayProperty(
            audioObjectID: audioObjectID,
            mSelector: kAudioDevicePropertyStreams
        ) else {
            return nil
        }
        self.audioStreams = audioStreamsIDs.compactMap { AudioStream(audioStreamID: $0) }
    }
    
    func isDirection(_ direction: AudioStreamDirection) -> Bool {
        self.audioStreams.contains { $0.direction == direction }
    }
}

func listAudioDevices() -> [AudioDevice]? {
    guard let audioDevicesIDs: [AudioDeviceID] = fetchAudioArrayProperty(
        audioObjectID: AudioObjectID(kAudioObjectSystemObject),
        mSelector: kAudioHardwarePropertyDevices
    ) else {
        return nil
    }
    return audioDevicesIDs.compactMap { AudioDevice(audioObjectID: $0) }
}

func fetchSpecificDevice(mSelector: AudioObjectPropertySelector) -> AudioDevice? {
    guard let audioDeviceID: AudioDeviceID = fetchAudioProperty(
        audioObjectID: AudioObjectID(kAudioObjectSystemObject),
        mSelector: mSelector
    ) else {
        return nil
    }
    return AudioDevice(audioObjectID: audioDeviceID)
}

func setDefaultDevice(mSelector: AudioObjectPropertySelector, audioObjectID: AudioObjectID) -> Bool {
    return setAudioProperty(
        audioObjectID: AudioObjectID(kAudioObjectSystemObject),
        mSelector: mSelector,
        value: audioObjectID
    )
}

extension [AudioDevice] {
    func withDirection(_ direction: AudioStreamDirection) -> [AudioDevice] {
        Array(self.withDirectionLazy(direction))
    }
    
    func withDirectionLazy(_ direction: AudioStreamDirection) -> LazyFilterSequence<[AudioDevice]> {
        self.lazy.filter { $0.isDirection(direction) }
    }
}
