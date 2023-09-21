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
struct AudioDeviceBlockerApp: App {
    @NSApplicationDelegateAdaptor(AudioContext.self) var audioContext
    
    var body: some Scene {
        MenuBarExtra("Audio Device Blocker", systemImage: "speaker.slash.circle") {
            MenuBarView()
        }
        Settings {
            PreferencesWindowView().environmentObject(audioContext)
        }
    }
}
