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
struct AudioDeviceBlockerAppMain {
    static func main() {
        if #available(macOS 13, *) {
            return AudioDeviceBlockerApp13.main()
        } else {
            return AudioDeviceBlockerAppOld.main()
        }
    }
}

class AudioDeviceBlockerApp {
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
        if #available(macOS 13.0, *) {
            do {
                try SMAppService.mainApp.register()
            } catch {
                debugPrint("Cannot register to run at login \(error)")
            }
        } else {
            if let bundleID = Bundle.main.bundleIdentifier {
                if !SMLoginItemSetEnabled(bundleID as CFString, true) {
                    print("Cannot register to run at login")
                }
            } else {
                print("Cannot retrieve bundleIdentifier")
            }
        }
        #endif
    }

    public static func unregisterStartAtLogin() {
        #if DEBUG
            print("DEBUG: Would unregisterStartAtLogin")
        #else
        if #available(macOS 13.0, *) {
            do {
                try SMAppService.mainApp.unregister()
            } catch {
                debugPrint("Cannot un-register to run at login \(error)")
            }
        } else {
            if let bundleID = Bundle.main.bundleIdentifier {
                if !SMLoginItemSetEnabled(bundleID as CFString, false) {
                    print("Cannot un-register to run at login")
                }
            } else {
                print("Cannot retrieve bundleIdentifier")
            }
        }
        #endif
    }
}

@available(macOS 13, *)
final class AudioDeviceBlockerApp13: AudioDeviceBlockerApp, App {
    @StateObject private var audioContext = AudioContext.prepopulate()

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

final class AudioDeviceBlockerAppOld: AudioDeviceBlockerApp, App {
    @StateObject private var audioContext = AudioContext.prepopulate()

    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate: AppDelegate

    var body: some Scene {
        Settings {
            PreferencesWindowView(audioContext: audioContext)
                .environment(\.managedObjectContext, AudioDeviceBlockerApp.persistentContainer.viewContext)
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    private var menuBar: OldMenuBar?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // MenuBarExtra is only available on macOS 13 and up, so spawning a menu item the old way
        if #unavailable(macOS 13) {
            self.menuBar = OldMenuBar.shared
            self.menuBar?.setup()
        }
    }
}
