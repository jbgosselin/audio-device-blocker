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
            Button("Settings") {
                NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: self)
            }
            Divider()
            Link("About", destination: URL(string: "https://github.com/jbgosselin/audio-device-blocker")!)
            Button("Quit") {
                NSApplication.shared.terminate(self)
            }
        }.scenePadding()
    }
}

struct MenuBarView_Previews: PreviewProvider {
    static var previews: some View {
        MenuBarView()
    }
}
