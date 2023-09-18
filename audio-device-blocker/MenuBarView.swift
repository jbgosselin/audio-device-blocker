//
//  MenuBarView.swift
//  Audio Device Blocker
//
//  Created by Jean-Baptiste Gosselin on 2023-09-17.
//

import SwiftUI

struct MenuBarView: View {
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        VStack {
            Text("Audio Device Blocker").foregroundColor(.secondary)
            Divider()
            Button("Preferences") {
                openWindow(id: "preferences")
            }
            Divider()
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
