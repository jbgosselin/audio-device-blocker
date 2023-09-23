//
//  PreferencesWindowView.swift
//  Audio Device Blocker
//
//  Created by Jean-Baptiste Gosselin on 2023-09-17.
//

import SwiftUI

enum StorageKey: String {
    case outputBlocklist = "outputBlocklist"
    case inputBlocklist = "inputBlocklist"
    case outputFallbacks = "outputFallbacks"
    case inputFallbacks = "inputFallbacks"
}

struct PreferencesWindowView: View {
    @AppStorage(StorageKey.outputBlocklist.rawValue) private var outputBlocklist = [SavedAudioDevice]()
    @AppStorage(StorageKey.inputBlocklist.rawValue) private var inputBlocklist = [SavedAudioDevice]()
    @AppStorage(StorageKey.outputFallbacks.rawValue) private var outputFallbacks = [SavedAudioDevice]()
    @AppStorage(StorageKey.inputFallbacks.rawValue) private var inputFallbacks = [SavedAudioDevice]()
    
    @StateObject var audioContext: AudioContext = AudioContext.main

    var body: some View {
        TabView {
            PreferencesPanelView(
                direction: .output,
                blocklist: $outputBlocklist,
                fallbacks: $outputFallbacks,
                audioContext: audioContext
            )
            .tabItem {
                Label("Output blocklist", systemImage: "speaker")
            }
            PreferencesPanelView(
                direction: .input,
                blocklist: $inputBlocklist,
                fallbacks: $inputFallbacks,
                audioContext: audioContext
            )
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
