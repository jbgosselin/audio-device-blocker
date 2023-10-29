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

    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate: AppDelegate

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
    
    var body: some Scene {
        Settings {
            PreferencesWindowView(audioContext: audioContext)
                .environment(\.managedObjectContext, AudioDeviceBlockerApp.persistentContainer.viewContext)
        }
    }
}

class MenuBar {
    static let shared = MenuBar()

    private lazy var statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

    private lazy var menu: NSMenu = {
        let menu = NSMenu()

        let appNameItem = NSMenuItem(title: "Audio Device Blocker", action: nil, keyEquivalent: "")
        appNameItem.isEnabled = false

        let openSettingsItem = {
            if #available(macOS 14.0, *) {
                let testItem = NSMenuItem()
                testItem.view = NSHostingView(rootView: SettingsLink())
                return testItem
            } else {
                return NSMenuItem(title: "Settings…", action: #selector(openSettings), keyEquivalent: "")
            }
        }()

        let aboutItem = NSMenuItem(title: "About", action: #selector(openAbout), keyEquivalent: "")

        let quitItem = NSMenuItem(title: "Quit", action: #selector(quit), keyEquivalent: "")

        menu.items = [
            appNameItem,
            .separator(),
            openSettingsItem,
            .separator(),
            aboutItem,
            quitItem
        ]

        menu.items.forEach { $0.target = self }

        return menu
    }()

    @objc private func quit() {
        NSApplication.shared.terminate(self)
    }

    @objc private func openAbout() {
        NSApplication.shared.orderFrontStandardAboutPanel(self)
    }

    @objc private func openSettings() {
        if #available(macOS 13.0, *) {
            NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: self)
        } else {
            NSApp.sendAction(Selector(("showPreferencesWindow:")), to: nil, from: self)
        }
    }

    init() {
        if let button = statusItem.button {
            button.image = NSImage(named: "MenuBarIcon")
//            button.action = #selector(statusItemAction(sender:))
            button.target = self
        }
    }

    func setup() {
        statusItem.menu = menu

        self.statusItem.isVisible = true
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    private var menuBar: MenuBar?

    func applicationDidFinishLaunching(_ notification: Notification) {
        print("Hello world !")

        self.menuBar = MenuBar.shared
        self.menuBar?.setup()
    }
}
