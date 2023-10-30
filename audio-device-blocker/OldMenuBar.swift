//
//  OldMenuBar.swift
//  AudioDeviceBlocker
//
//  Created by Jean-Baptiste Gosselin on 2023-10-29.
//

import SwiftUI

class OldMenuBar {
    static let shared = OldMenuBar()

    private lazy var statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

    private lazy var menu: NSMenu = {
        let menu = NSMenu()

        let appNameItem = NSMenuItem(title: "Audio Device Blocker", action: nil, keyEquivalent: "")
        appNameItem.isEnabled = false

        let openSettingsItem = NSMenuItem(title: "Settings…", action: #selector(openSettings), keyEquivalent: "")

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
        NSApp.sendAction(Selector(("showPreferencesWindow:")), to: nil, from: self)
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
