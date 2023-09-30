//
//  PreferencesPanelView.swift
//  Audio Device Blocker
//
//  Created by Jean-Baptiste Gosselin on 2023-09-18.
//

import SwiftUI

struct PreferencesPanelView<FallbackDevice>: View where FallbackDevice: SavedFallbackDevice {
    @Environment(\.managedObjectContext) var moc

    @State private var selectedFallback: FallbackDevice?
    @State private var selectedBlocklist: BlockedDevice?
    @State private var selectedAvailable: AudioDevice?

    let direction: AudioStreamDirection

    @FetchRequest(sortDescriptors: [SortDescriptor(\.deviceUID)])
    private var allBlockedDevices: FetchedResults<BlockedDevice>

    @FetchRequest(sortDescriptors: [NSSortDescriptor(key: "idx", ascending: true)])
    private var fallbacks: FetchedResults<FallbackDevice>

    @ObservedObject var audioContext: AudioContext
    
    var availableDevices: [AudioDevice] {
        audioContext.availableDevices.withDirection(direction)
    }

    var blocklist: [BlockedDevice] {
        self.allBlockedDevices.filter { $0.direction == direction }
    }

    func appendFallbackDevice(_ device: AudioDevice) throws {
        let fallbackDevice = FallbackDevice.init(context: moc)
        fallbackDevice.deviceUID = device.deviceUID
        fallbackDevice.name = device.name
        fallbackDevice.idx = Int64(self.fallbacks.endIndex)
        try moc.save()
    }

    func removeFallbackDevice(_ device: SavedFallbackDevice) throws {
        moc.delete(device)
        try moc.save()
        for (idx, dev) in self.fallbacks.enumerated() {
            dev.idx = Int64(idx)
        }
        try moc.save()
    }

    func moveFallbacks(fromOffsets: IndexSet, toOffset: Int) throws {
        var tmp = Array(self.fallbacks)
        tmp.move(fromOffsets: fromOffsets, toOffset: toOffset)
        for (idx, dev) in tmp.enumerated().filter({ (idx, dev) in
            dev.idx != idx
        }) {
            dev.idx = Int64(idx)
        }
        try moc.save()
    }

    var body: some View {
        VStack {
            HStack {
                Text("Available devices")
                Spacer()
                Menu("Actions") {
                    Button("Set as fallback") {
                        guard let selected = self.selectedAvailable else {
                            return
                        }
                        do {
                            try self.appendFallbackDevice(selected)
                            self.selectedAvailable = nil
                        }
                        catch {
                            print("Failed to save new FallbackDevice: \(error)")
                        }
                    }
                    .help("Add to fallbacks")
               
                   Button("Block") {
                       guard let selected = self.selectedAvailable else {
                           return
                       }
                       do {
                           let blockedDevice = BlockedDevice.init(context: moc)
                           blockedDevice.direction = direction
                           blockedDevice.deviceUID = selected.deviceUID
                           blockedDevice.name = selected.name
                           try moc.save()
                       }
                       catch {
                           print("Failed to save new BlockedDevice: \(error)")
                       }
                       self.selectedAvailable = nil
                   }
                   .help("Add to blocklist")
                }
                .fixedSize()
                .disabled({
                    guard let selected = self.selectedAvailable else {
                        return true
                    }
                    return self.blocklist.hasDevice(selected) || self.fallbacks.hasDevice(selected)
                }())
            }
            List(availableDevices, id: \.id, selection: $selectedAvailable) { dev in
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
                    do {
                        moc.delete(selected)
                        try moc.save()
                        self.selectedBlocklist = nil
                    }
                    catch {
                        print("Failed to remove BlockedDevice: \(error)")
                    }
                }
                .help("Remove from blocklist")
                .disabled(self.selectedBlocklist == nil)
            }
            List(self.blocklist, id: \.deviceUID, selection: self.$selectedBlocklist) { dev in
                HStack {
                    Text(dev.name ?? "nil")
                    Spacer()
                    Text("[\(dev.deviceUID ?? "nil")]").fontWeight(.thin)
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
                    do {
                        try self.removeFallbackDevice(selected)
                        self.selectedFallback = nil
                    } catch {
                        print("Failed to remove FallbackDevice: \(error)")
                    }
                }
                .help("Remove from fallbacks")
                .disabled(self.selectedFallback == nil)
            }
            List(selection: self.$selectedFallback) {
                ForEach(self.fallbacks, id: \.deviceUID) { dev in
                    HStack {
                        Text(dev.name ?? "nil")
                        Spacer()
                        Text("[\(dev.deviceUID ?? "nil")]").fontWeight(.thin)
                        #if DEBUG
                        Text("{\(dev.idx)}").fontWeight(.ultraLight)
                        #endif
                    }
                    .tag(dev)
                }
                .onMove(perform: { idx, offset in
                    do {
                        try self.moveFallbacks(fromOffsets: idx, toOffset: offset)
                    } catch {
                        print("Failed to reorder FallbackDevice: \(error)")
                    }
                })
            }
        }
        .frame(minWidth: 500, minHeight: 500)
    }
}

#Preview {
//    @State var fallbacks = [
//        SavedAudioDevice(deviceUID: "test-id-fallback", name: "Test Device"),
//        SavedAudioDevice(deviceUID: "BuiltInSpeakerDevice", name: "Test Built In")
//    ]
    let audioContext = AudioContext()
    let _ = audioContext.fetchAvailableDevices()
    return PreferencesPanelView<OutputFallbackDevice>(
        direction: .output,
        audioContext: audioContext
    )
    .environment(\.managedObjectContext, AudioDeviceBlockerApp.persistentContainer.viewContext)
}
