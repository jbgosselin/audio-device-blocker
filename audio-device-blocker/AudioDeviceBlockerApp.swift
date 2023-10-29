//
//  AudioDeviceBlockerApp.swift
//  Audio Device Blocker
//
//  Created by Jean-Baptiste Gosselin on 2023-09-10.
//

import SwiftUI
import CoreAudio
import UserNotifications
import ServiceManagement

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

    public static func requestNotification() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { success, error in
            if let error = error {
                print(error.localizedDescription)
                return
            }
            print("Notification authorized? \(success)")
        }
    }

    public static func registerStartAtLogin() {
        #if DEBUG
        print("DEBUG: Would registerStartAtLogin")
        #else
        do {
            try SMAppService.mainApp.register()
        } catch {
            debugPrint("Cannot register to run at login \(error)")
        }
        #endif
    }

    public static func unregisterStartAtLogin() {
        #if DEBUG
            print("DEBUG: Would unregisterStartAtLogin")
        #else
        do {
            try SMAppService.mainApp.unregister()
        } catch {
            debugPrint("Cannot un-register to run at login \(error)")
        }
        #endif
    }
    
    var body: some Scene {
        MenuBarExtra("Audio Device Blocker", image: "MenuBarIcon") {
            MenuBarView()
        }
        Settings {
            PreferencesWindowView(audioContext: audioContext)
                .environment(\.managedObjectContext, AudioDeviceBlockerApp.persistentContainer.viewContext)
        }
    }
}
