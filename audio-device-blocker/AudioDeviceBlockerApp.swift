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
    @StateObject private var audioContext = AudioContext.prepopulate()

    static let persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "AudioDeviceBlocker")
        container.loadPersistentStores { description, error in
            if let error = error {
                fatalError("Unable to load persistent stores: \(error)")
            }
        }
        return container
    }()

    init() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { success, error in
            if let error = error {
                print(error.localizedDescription)
                return
            }
            print("Notification authorized? \(success)")
        }
    }
    
    var body: some Scene {
        MenuBarExtra("Audio Device Blocker", systemImage: "speaker.slash.circle") {
            MenuBarView()
        }
        Settings {
            PreferencesWindowView(audioContext: audioContext)
                .environment(\.managedObjectContext, AudioDeviceBlockerApp.persistentContainer.viewContext)
        }
    }
}
