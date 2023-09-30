//
//  PreferencesWindowView.swift
//  Audio Device Blocker
//
//  Created by Jean-Baptiste Gosselin on 2023-09-17.
//

import SwiftUI

struct PreferencesWindowView: View {
    @Environment(\.managedObjectContext) var moc
    
    @ObservedObject var audioContext: AudioContext

    private enum Tabs: Hashable {
        case general, outputs, inputs
    }

    var body: some View {
        TabView {
            GeneralPreferencesPanelView()
                .tabItem {
                    Label("General", systemImage: "gear")
                }
                .tag(Tabs.general)

            PreferencesPanelView<OutputFallbackDevice>(
                direction: .output,
                audioContext: audioContext
            )
            .environment(\.managedObjectContext, moc)
            .tabItem {
                Label("Output blocklist", systemImage: "speaker")
            }
            .tag(Tabs.outputs)

            PreferencesPanelView<InputFallbackDevice>(
                direction: .input,
                audioContext: audioContext
            )
            .environment(\.managedObjectContext, moc)
            .tabItem{
                Label("Input Blocklist", systemImage: "mic")
            }
            .tag(Tabs.inputs)
        }
        .scenePadding()
    }
}

struct PreferencesWindowView_Previews: PreviewProvider {
    static var previews: some View {
        let audioContext = AudioContext()
        let _ = audioContext.fetchAvailableDevices()
        PreferencesWindowView(audioContext: audioContext)
            .environment(\.managedObjectContext, AudioDeviceBlockerApp.persistentContainer.viewContext)
    }
}
