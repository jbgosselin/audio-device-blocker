//
//  PreferencesPanelView.swift
//  Audio Device Blocker
//
//  Created by Jean-Baptiste Gosselin on 2023-09-18.
//

import SwiftUI

struct PreferencesPanelView: View {
    let direction: AudioStreamDirection
    @Binding var blocklist: SavedAudioDeviceList
    @Binding var fallbacks: SavedAudioDeviceList
    @State private var availableDevices: Array<AudioDevice>
    @State private var selectedFallback: SavedAudioDevice?
    @State private var selectedBlocklist: SavedAudioDevice?
    @State private var selectedAvailable: AudioDevice?

    init(
        direction: AudioStreamDirection,
        blocklist: Binding<SavedAudioDeviceList>,
        fallbacks: Binding<SavedAudioDeviceList>
    ) {
        self.direction = direction
        self._blocklist = blocklist
        self._fallbacks = fallbacks
        self.availableDevices = listAudioDevices(direction: direction) ?? Array<AudioDevice>()
    }
    
    var body: some View {
        VStack {
            HStack {
                Text("Available devices")
                Spacer()
                Menu("Actions") {
                    Button {
                        self.availableDevices = listAudioDevices(direction: self.direction) ?? self.availableDevices
                    } label: {
                        Label("Refresh", systemImage: "arrow.clockwise")
                    }
                    Divider()
                    Group {
                        Button("Set as fallback") {
                            guard let selected = self.selectedAvailable else {
                                return
                            }
                            self.fallbacks.addDevice(selected)
                        }
                        .help("Add to fallbacks")
                   
                       Button("Block") {
                           guard let selected = self.selectedAvailable else {
                               return
                           }
                           self.blocklist.addDevice(selected)
                       }
                       .help("Add to blocklist")
                    }
                    .disabled({
                        guard let selected = self.selectedAvailable else {
                            return true
                        }
                        return self.blocklist.hasDevice(selected) || self.fallbacks.hasDevice(selected)
                    }())
                }
                .fixedSize()
            }
            List(self.availableDevices, id: \.id, selection: self.$selectedAvailable) { dev in
                let stack = HStack {
                    Text(dev.name)
                    Spacer()
                    Text("[\(dev.deviceUID)]").fontWeight(.thin)
                }
                if self.blocklist.hasDevice(dev) || self.fallbacks.hasDevice(dev) {
                    stack.foregroundColor(.secondary)
                } else {
                    stack.tag(dev)
                }
            }
            
            Divider()

            HStack {
                Text("Blocklist")
                Spacer()
                Button("Remove") {
                    guard let selected = self.selectedBlocklist else {
                        return
                    }
                    self.blocklist.removeDeviceByID(selected.deviceUID)
                }
                .help("Remove from blocklist")
                .disabled(self.selectedBlocklist == nil)
            }
            List(self.blocklist, id: \.deviceUID, selection: self.$selectedBlocklist) { dev in
                HStack {
                    Text(dev.name)
                    Spacer()
                    Text("[\(dev.deviceUID)]").fontWeight(.thin)
                }
                .tag(dev)
            }
            
            Divider()
            
            HStack {
                Text("Fallbacks")
                Spacer()
                Text("Can be reordered, device priority from top to bottom").fontWeight(.thin)
                Button("Remove") {
                    guard let selected = self.selectedFallback else {
                        return
                    }
                    self.fallbacks.removeDeviceByID(selected.deviceUID)
                }
                .help("Remove from fallbacks")
                .disabled(self.selectedFallback == nil)
            }
            List(selection: self.$selectedFallback) {
                ForEach(self.fallbacks, id: \.deviceUID) { dev in
                    HStack {
                        Text(dev.name)
                        Spacer()
                        Text("[\(dev.deviceUID)]").fontWeight(.thin)
                    }
                    .tag(dev)
                }
                .onMove(perform: { idx, offset in
                    self.fallbacks.move(fromOffsets: idx, toOffset: offset)
                })
            }
        }.scenePadding()
    }
}

struct PreferencesPanelView_Previews: PreviewProvider {
    static var previews: some View {
        @State var blocklist = [
            SavedAudioDevice(deviceUID: "test-id-blocklisted", name: "Test Device")
        ]
        @State var fallbacks = [
            SavedAudioDevice(deviceUID: "test-id-fallback", name: "Test Device"),
            SavedAudioDevice(deviceUID: "BuiltInSpeakerDevice", name: "Test Built In")
        ]
        PreferencesPanelView(
            direction: .output,
            blocklist: $blocklist,
            fallbacks: $fallbacks
        )
    }
}
