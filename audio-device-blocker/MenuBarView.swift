//
//  MenuBarView.swift
//  Audio Device Blocker
//
//  Created by Jean-Baptiste Gosselin on 2023-09-17.
//

import SwiftUI

struct MenuBarView: View {
    var body: some View {
        VStack {
            Text("Audio Device Blocker").foregroundColor(.secondary)
            Divider()
            if #available(macOS 14.0, *) {
                SettingsLink()
            } else {
                Button("Settings...") {
                    NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: self)
                }
            }
            Divider()
            Button("About") {
                NSApplication.shared.orderFrontStandardAboutPanel(self)
            }
            Button("Quit") {
                NSApplication.shared.terminate(self)
            }
        }
    }
}

#Preview {
    MenuBarView()
}
