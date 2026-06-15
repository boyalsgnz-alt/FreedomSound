//
//  ContentView.swift
//  FreedomSound
//
//  Created by Gaëtan Boyals on 05/04/2026.
//

import SwiftUI
import AVFoundation
import MediaPlayer

struct ContentView: View {
    @EnvironmentObject var manager: FolderAccessManager
    @EnvironmentObject var audioPlayer: AudioPlayer
    @EnvironmentObject var router: Router
    @State private var showingFolderPicker = false
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            LibraryView()
                .tabItem {
                    Label("Library", systemImage: "music.note.house")
                }
                .tag(0)
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape")
                }
                .tag(1)
        }
        .frame(maxWidth: .infinity)
        .tint(.orange)
        .toolbarBackground(.black.opacity(0.95), for: .tabBar)
        .toolbarBackground(.visible, for: .tabBar)
    }
}

/* #Preview {
 ContentView()
 } */
