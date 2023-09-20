//
//  AudioDeviceBlockerApp.swift
//  Audio Device Blocker
//
//  Created by Jean-Baptiste Gosselin on 2023-09-10.
//

import SwiftUI
import CoreAudio
import UserNotifications

@main
final class AudioDeviceBlockerApp: App {
    private var audioContext: AudioContext
    
    required init() {
        self.audioContext = AudioContext()
        self.audioContext.fetchMainOutputDevice()
        self.audioContext.fetchMainInputDevice()
        self.registerAudioCallbacks()
        
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { success, error in
            if success {
//                permissionGranted = true
            } else if let error = error {
                print(error.localizedDescription)
            }
        }
    }
    
    private func registerAudioCallbacks() {
        let selectors = [
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
            
            let result = withUnsafeMutablePointer(to: &self.audioContext) { ptr in
                return AudioObjectAddPropertyListener(
                    AudioObjectID(kAudioObjectSystemObject),
                    &audioPropertyAddress,
                    { inObjectID, inNumberAddresses, inAddresses, context in
                        let inAddressesBuffer = UnsafeBufferPointer(start: inAddresses, count: Int(inNumberAddresses))
                        context?.load(as: AudioContext.self).coreAudioPropertyCallback(
                            inObjectID: inObjectID,
                            inAddresses: inAddressesBuffer
                        )
                        return 0
                    },
                    ptr
                )
            }
            
            if result != kAudioHardwareNoError {
                print("Error registering CoreAudio callback for selector \(selector): \(result)")
            }
        }
    }
    
    var body: some Scene {
        MenuBarExtra("Audio Device Blocker", systemImage: "speaker.slash.circle") {
            MenuBarView()
        }
        Window("Preferences", id: "preferences") {
            PreferencesWindowView()
        }
    }
}
