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
    init() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { success, error in
            if let error = error {
                print(error.localizedDescription)
                return
            }
            print("Notification authorized? \(success)")
        }

        // Create the singleton and start listening to audio events.
        let _ = AudioContext.main
    }
    
    var body: some Scene {
        MenuBarExtra("Audio Device Blocker", systemImage: "speaker.slash.circle") {
            MenuBarView()
        }
        Settings {
            PreferencesWindowView()
        }
    }
}
