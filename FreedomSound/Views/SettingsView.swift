//
//  SettingsView.swift
//  FreedomSound
//
//  Created by Gaëtan Boyals on 16/04/2026.
//

import SwiftUI
import AVFoundation
import MediaPlayer

struct SettingsView: View {
    @EnvironmentObject var manager: FolderAccessManager
    @State private var showingFolderPicker = false
    
    var body: some View {
        VStack {
            CountdownView()
            Text("Settings View")
            Spacer()
            InfinityLoader()
            Spacer()
            Button {
                showingFolderPicker.toggle()
            } label: {
                Label("Choose Folder", systemImage: "folder.badge.gearshape")
            }
        }
        .sheet(isPresented: $showingFolderPicker) {
            FolderPicker { url in
                manager.savePickedFolder(url)
                manager.scanFolder()
                showingFolderPicker = false
            }
        }
    }
}

#Preview {
    SettingsView()
}
