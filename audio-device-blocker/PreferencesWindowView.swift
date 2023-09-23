//
//  PreferencesWindowView.swift
//  Audio Device Blocker
//
//  Created by Jean-Baptiste Gosselin on 2023-09-17.
//

import SwiftUI

struct PreferencesWindowView: View {
    @Environment(\.managedObjectContext) var moc
    
    @StateObject var audioContext: AudioContext = AudioContext.main

    var body: some View {
        TabView {
            PreferencesPanelView<OutputFallbackDevice>(
                direction: .output,
                audioContext: audioContext
            )
            .environment(\.managedObjectContext, moc)
            .tabItem {
                Label("Output blocklist", systemImage: "speaker")
            }
            
            PreferencesPanelView<InputFallbackDevice>(
                direction: .input,
                audioContext: audioContext
            )
            .environment(\.managedObjectContext, moc)
            .tabItem{
                Label("Input Blocklist", systemImage: "mic")
            }
        }.scenePadding()

    }
}

struct PreferencesWindowView_Previews: PreviewProvider {
    static var previews: some View {
        PreferencesWindowView()
    }
}
