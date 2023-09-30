//
//  GeneralPreferencesPanelView.swift
//  AudioDeviceBlocker
//
//  Created by Jean-Baptiste Gosselin on 2023-09-29.
//

import SwiftUI

struct GeneralPreferencesPanelView: View {
    @AppStorage("startAtLogin") var startAtLogin = false
    @AppStorage("notifyOnDeviceBlocked") var notifyOnDeviceBlocked = true

    var body: some View {
        Form {
                Toggle("Start at Login", isOn: $startAtLogin)
                    .onChange(of: startAtLogin) {
                        if $0 {
                            AudioDeviceBlockerApp.registerStartAtLogin()
                        } else {
                            AudioDeviceBlockerApp.unregisterStartAtLogin()
                        }
                    }

                Toggle("Get notified when a device is blocked", isOn: $notifyOnDeviceBlocked)
                    .onChange(of: notifyOnDeviceBlocked) {
                        if $0 {
                            AudioDeviceBlockerApp.requestNotification()
                        }
                    }
            }
        .toggleStyle(.switch)
        .frame(width: 375, height: 100)
    }
}

#Preview {
    GeneralPreferencesPanelView()
}
