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
    @AppStorage(StorageKey.outputBlocklist.rawValue) private var outputBlocklist = SavedAudioDeviceList()
    @AppStorage(StorageKey.inputBlocklist.rawValue) private var inputBlocklist = SavedAudioDeviceList()
    @AppStorage(StorageKey.outputFallbacks.rawValue) private var outputFallbacks = SavedAudioDeviceList()
    @AppStorage(StorageKey.inputFallbacks.rawValue) private var inputFallbacks = SavedAudioDeviceList()

    var body: some View {
        TabView {
            PreferencesPanelView(
                direction: .output,
                blocklist: $outputBlocklist,
                fallbacks: $outputFallbacks
            ).tabItem {
                Label("Output blocklist", systemImage: "speaker")
            }
            PreferencesPanelView(
                direction: .input,
                blocklist: $inputBlocklist,
                fallbacks: $inputFallbacks
            ).tabItem{
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
