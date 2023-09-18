//
//  AudioDeviceBlocklistApp.swift
//  Audio Device Blocklist
//
//  Created by Jean-Baptiste Gosselin on 2023-09-10.
//

import SwiftUI
import CoreAudio
import UserNotifications

@main
final class AudioDeviceBlocklistApp: App {
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
            
            let result = AudioObjectAddPropertyListener(
                AudioObjectID(kAudioObjectSystemObject),
                &audioPropertyAddress,
                { inObjectID, inNumberAddresses, inAddresses, context in
                    context?.load(as: AudioContext.self).coreAudioPropertyCallback(
                        inObjectID: inObjectID,
                        inNumberAddresses: inNumberAddresses,
                        inAddresses: inAddresses
                    )
                    return 0
                },
                &self.audioContext
            )
            
            if result != kAudioHardwareNoError {
                print("Error registering CoreAudio callback for selector \(selector): \(result)")
            }
        }
    }
    
    var body: some Scene {
        MenuBarExtra("Audio Device Blocklist", systemImage: "star") {
            MenuBarView()
        }
        Window("Preferences", id: "preferences") {
            PreferencesWindowView()
        }
    }
}
