//
//  AudioContext.swift
//  Audio Device Blocklist
//
//  Created by Jean-Baptiste Gosselin on 2023-09-18.
//

import SwiftUI
import CoreAudio
import UserNotifications

class AudioContext {
    @AppStorage(StorageKey.outputBlocklist.rawValue) private var outputBlocklist = SavedAudioDeviceList()
    @AppStorage(StorageKey.inputBlocklist.rawValue) private var inputBlocklist = SavedAudioDeviceList()
    @AppStorage(StorageKey.outputFallbacks.rawValue) private var outputFallbacks = SavedAudioDeviceList()
    @AppStorage(StorageKey.inputFallbacks.rawValue) private var inputFallbacks = SavedAudioDeviceList()
    private var mainOutputDevice: AudioDevice?
    private var mainInputDevice: AudioDevice?
    
    func coreAudioPropertyCallback(inObjectID: AudioObjectID, inNumberAddresses: UInt32, inAddresses: UnsafePointer<AudioObjectPropertyAddress>) {
        for n in 0..<inNumberAddresses {
            let property = inAddresses.advanced(by: Int(n)).pointee
            switch property.mSelector {
            case kAudioHardwarePropertyDefaultInputDevice:
                print("Main Audio Input Device changed")
                self.fetchMainInputDevice()
            case kAudioHardwarePropertyDefaultOutputDevice:
                print("Main Audio Output Device changed")
                self.fetchMainOutputDevice()
            default:
                print("Unknown selector \(property)")
            }
        }
    }
    
    func fetchMainOutputDevice() {
        guard let device = fetchSpecificDevice(mSelector: kAudioHardwarePropertyDefaultOutputDevice) else {
            print("Failed to retrieve default output device")
            return
        }
        
        print("New Default Output Device")
        dump(device)
        
        // Check if device is blocklisted, otherwise nothing to do
        if !self.outputBlocklist.hasDevice(device) {
            self.mainOutputDevice = device
            return
        }
        
        print("Reverting new output device because in blocklist")

        guard let availableDevices = listAudioDevices(direction: .output) else {
            print("Can't retrieve available output devices")
            return
        }
        
        // If we had a device before and it is available
        if let previousDevice = self.mainOutputDevice, availableDevices.contains(where: { $0.id == previousDevice.id }) == true {
            self.mainOutputDevice = device
            if setDefaultDevice(mSelector: kAudioHardwarePropertyDefaultOutputDevice, audioObjectID: previousDevice.id) {
                print("    successfully reverted previous output device")
                self.notifyUser(device)
                return
            } else {
                print("    error reverting to previous output device")
            }
        }
        
        self.mainOutputDevice = device
        
        // Otherwise, find the best fallback
        
        for dev in self.outputFallbacks {
            guard let connectedDevice = availableDevices.first(where: { $0.deviceUID == dev.deviceUID }) else {
                continue
            }
            if setDefaultDevice(mSelector: kAudioHardwarePropertyDefaultOutputDevice, audioObjectID: connectedDevice.id) {
                print("    successfully reverted to fallback output device")
                self.notifyUser(device)
                return
            } else {
                print("    error reverting to fallback output device")
            }
        }
        
        print("Failed to revert output device")
    }
    
    func fetchMainInputDevice() {
        guard let device = fetchSpecificDevice(mSelector: kAudioHardwarePropertyDefaultInputDevice) else {
            print("Failed to retrieve default input device")
            return
        }
        
        print("New Default Input Device")
        dump(device)
        
        // First check if device is blocklisted, otherwise nothing to do
        if !self.inputBlocklist.hasDevice(device) {
            self.mainInputDevice = device
            return
        }
        
        print("Reverting new input device because in blocklist")
        
        guard let availableDevices = listAudioDevices(direction: .input) else {
            print("Can't retrieve available input devices")
            return
        }
        
        // If we had a device before and it is available
        if let previousDevice = self.mainInputDevice, availableDevices.contains(where: { $0.id == previousDevice.id }) == true {
            self.mainInputDevice = device
            if setDefaultDevice(mSelector: kAudioHardwarePropertyDefaultInputDevice, audioObjectID: previousDevice.id) {
                print("    successfully reverted previous input device")
                self.notifyUser(device)
                return
            } else {
                print("    error reverting to previous input device")
            }
        }
        
        self.mainInputDevice = device
        
        // Otherwise, find the best fallback
        
        for dev in self.inputFallbacks {
            guard let connectedDevice = availableDevices.first(where: { $0.deviceUID == dev.deviceUID }) else {
                continue
            }
            if setDefaultDevice(mSelector: kAudioHardwarePropertyDefaultInputDevice, audioObjectID: connectedDevice.id) {
                print("    successfully reverted to fallback input device")
                self.notifyUser(device)
                return
            } else {
                print("    error reverting to fallback input device")
            }
        }
        
        print("Failed to revert input device")
    }
    
    func notifyUser(_ device: AudioDevice) {
        let notificationContent = UNMutableNotificationContent()
        notificationContent.title = "Blocked device"
        notificationContent.subtitle = "\(device.name)"
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 0, repeats: false)
        let req = UNNotificationRequest(identifier: UUID().uuidString, content: notificationContent, trigger: trigger)
        UNUserNotificationCenter.current().add(req)
    }
}
