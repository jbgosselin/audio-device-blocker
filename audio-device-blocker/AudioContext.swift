//
//  AudioContext.swift
//  Audio Device Blocker
//
//  Created by Jean-Baptiste Gosselin on 2023-09-18.
//

import SwiftUI
import CoreAudio
import UserNotifications

final class AudioContext: NSObject, NSApplicationDelegate, ObservableObject {
    @AppStorage(StorageKey.outputBlocklist.rawValue) private var outputBlocklist = [SavedAudioDevice]()
    @AppStorage(StorageKey.inputBlocklist.rawValue) private var inputBlocklist = [SavedAudioDevice]()
    @AppStorage(StorageKey.outputFallbacks.rawValue) private var outputFallbacks = [SavedAudioDevice]()
    @AppStorage(StorageKey.inputFallbacks.rawValue) private var inputFallbacks = [SavedAudioDevice]()
    
    private var mainOutputDevice: AudioDevice?
    private var mainInputDevice: AudioDevice?
    @Published var availableDevices: [AudioDevice] = []
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        self.registerAudioCallbacks()
        self.fetchAvailableDevices()
        self.fetchMainOutputDevice()
        self.fetchMainInputDevice()
        
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { success, error in
            if let error = error {
                print(error.localizedDescription)
                return
            }
            print("Notification authorized \(success)")
        }
    }
    
    private func registerAudioCallbacks() {
        let selectors = [
            kAudioHardwarePropertyDevices,
            kAudioHardwarePropertyDefaultOutputDevice,
            kAudioHardwarePropertyDefaultInputDevice,
        ]
        
        for selector in selectors {
            // audioPropertyAddress describes what property we want to observe changes and be called back
            var audioPropertyAddress = AudioObjectPropertyAddress(
                mSelector: selector,
                mScope: kAudioObjectPropertyScopeGlobal,
                mElement: kAudioObjectPropertyElementMain
            )
            let rawSelfPtr = unsafeBitCast(self, to: UnsafeMutableRawPointer.self)
            let result = AudioObjectAddPropertyListener(
                AudioObjectID(kAudioObjectSystemObject),
                &audioPropertyAddress,
                { inObjectID, inNumberAddresses, inAddresses, context in
                    let inAddressesBuffer = UnsafeBufferPointer(start: inAddresses, count: Int(inNumberAddresses))
                    unsafeBitCast(context, to: AudioContext.self).coreAudioPropertyCallback(
                        inObjectID: inObjectID,
                        inAddresses: inAddressesBuffer
                    )
                    return 0
                },
                rawSelfPtr
            )
            
            if result != kAudioHardwareNoError {
                print("Error registering CoreAudio callback for selector \(selector): \(result)")
            }
        }
    }
    
    func coreAudioPropertyCallback<A: Sequence<AudioObjectPropertyAddress>>(inObjectID: AudioObjectID, inAddresses: A) {
        DispatchQueue.main.sync {
            for property in inAddresses {
                switch property.mSelector {
                case kAudioHardwarePropertyDefaultInputDevice:
                    print("Main Audio Input Device changed")
                    self.fetchMainInputDevice()
                case kAudioHardwarePropertyDefaultOutputDevice:
                    print("Main Audio Output Device changed")
                    self.fetchMainOutputDevice()
                case kAudioHardwarePropertyDevices:
                    print("Audio Device Changed")
                    self.fetchAvailableDevices()
                default:
                    print("Unknown selector \(property)")
                }
            }
        }
    }
    
    func fetchAvailableDevices() {
        self.availableDevices = listAudioDevices() ?? self.availableDevices
        dump(self.availableDevices)
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
        
        // If we had a device before and it is available
        if let previousDevice = self.mainOutputDevice, availableDevices.withDirection(.output).contains(previousDevice) {
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
            guard let connectedDevice = availableDevices.withDirection(.output).first(where: { $0.deviceUID == dev.deviceUID }) else {
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
        
        // If we had a device before and it is available
        if let previousDevice = self.mainInputDevice, availableDevices.withDirection(.input).contains(previousDevice) {
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
            guard let connectedDevice = availableDevices.withDirection(.input).first(where: { $0.deviceUID == dev.deviceUID }) else {
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
        notificationContent.subtitle = device.name
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let req = UNNotificationRequest(identifier: UUID().uuidString, content: notificationContent, trigger: trigger)
        UNUserNotificationCenter.current().add(req)
    }
}
