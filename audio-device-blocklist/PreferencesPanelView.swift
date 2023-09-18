//
//  PreferencesPanelView.swift
//  Audio Device Blocklist
//
//  Created by Jean-Baptiste Gosselin on 2023-09-18.
//

import SwiftUI

struct PreferencesPanelView: View {
    let direction: AudioStreamDirection
    @Binding var blocklist: SavedAudioDeviceList
    @Binding var fallbacks: SavedAudioDeviceList
    @State private var availableDevices: Array<AudioDevice>

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
                Button {
                    self.availableDevices = listAudioDevices(direction: self.direction) ?? self.availableDevices
                } label: {
                    Label("Refresh", systemImage: "arrow.clockwise")
                }
            }
            List(self.availableDevices.filter {
                !self.blocklist.hasDevice(audioDevice: $0) && !self.fallbacks.hasDevice(audioDevice: $0)
            }) { dev in
                HStack {
                    Text("\(dev.name) (\(dev.deviceUID))")
                    
                    Spacer()
                    
                    Button {
                        self.fallbacks.addDevice(audioDevice: dev)
                    } label: {
                        Image(systemName: "checkmark.circle")
                    }.help("Add to fallbacks")
                    
                    Button {
                        self.blocklist.addDevice(audioDevice: dev)
                    } label: {
                        Image(systemName: "xmark.circle")
                    }.help("Add to blocklist")
                }
            }
            
            Divider()
                        
            Text("Blocklist")
            List(self.blocklist) { dev in
                HStack {
                    Text("\(dev.name) (\(dev.id))")
                    
                    Spacer()
                    
                    Button {
                        self.blocklist.removeDeviceByID(id: dev.id)
                    } label: {
                        Image(systemName: "minus.circle")
                    }.help("Remove from blocklist")
                }
            }
            
            Divider()
                        
            Text("Fallbacks")
            List(self.fallbacks) { dev in
                HStack {
                    Text("\(dev.name) (\(dev.id))")
                    
                    Spacer()
                                        
                    Button {
                        self.fallbacks.moveBefore(id: dev.id)
                    } label: {
                        Image(systemName: "chevron.up.circle")
                    }
                    .help("Increase priority")
                    .disabled(self.fallbacks.first?.id == dev.id)
                    
                    Button {
                        self.fallbacks.moveAfter(id: dev.id)
                    } label: {
                        Image(systemName: "chevron.down.circle")
                    }
                    .help("Reduce priority")
                    .disabled(self.fallbacks.last?.id == dev.id)
                    
                    Button {
                        self.fallbacks.removeDeviceByID(id: dev.id)
                    } label: {
                        Image(systemName: "minus.circle")
                    }.help("Remove from fallbacks")
                }
            }
        }.scenePadding()
    }
}

struct PreferencesPanelView_Previews: PreviewProvider {
    static var previews: some View {
        @State var blocklist = [
            SavedAudioDevice(id: "test-id-balcklisted", name: "Test Device")
        ]
        @State var fallbacks = [
            SavedAudioDevice(id: "test-id-fallback", name: "Test Device")
        ]
        PreferencesPanelView(
            direction: .output,
            blocklist: $blocklist,
            fallbacks: $fallbacks
        )
    }
}
