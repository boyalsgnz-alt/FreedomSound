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
    
   @ViewBuilder
    func navButton(label: String, screen: AppScreen) -> some View {
        VStack {
            Button {
                router.currentScreen = screen
                print("Button clicked!!")
            } label: {
                Image(systemName: router.currentScreen == screen ? "\(screen.iconName).fill" : screen.iconName)
                    .font(.system(size: 24, weight: .medium))
                    .foregroundStyle(router.currentScreen == screen ? .white : .gray)
                    .frame(maxWidth: .infinity)
            }

            Text(label)
                .font(.system(size: 11, weight: router.currentScreen == screen ? .medium : .light))
                .foregroundStyle(router.currentScreen == screen ? .white : .gray)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            Group {
                switch router.currentScreen {
                case .home:
                    LibraryView()
                case .playlists:
                    PlaylistsView()
                case .playlistSongs:
                    SongListView(
                        title: manager.currentPlaylistName,
                        songs: manager.currentPlaylist,
                        onBack: { router.goToPlaylists() }
                    )
                case .settings:
                    SettingsView()
                case .viewtester:
                    SongListView(
                        title: "All Songs",
                        songs: manager.musicFiles,
                        onBack: { router.goToHome() }
                    )
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .onAppear {
            if manager.selectedFolderURL != nil && manager.musicFiles.isEmpty {
                print("scanFolder begins")
                manager.scanFolder()
                print("scanFolder ends")
            }
        }
        .safeAreaInset(edge: .bottom) {
            HStack {
                navButton(label: "Library", screen: .home)
                navButton(label: "Settings", screen: .settings)
                navButton(label: "Tester", screen: .viewtester)
            }
            .padding(.top, 8)
            .background(
                    Color.black.opacity(0.90)
                        .ignoresSafeArea(edges: .bottom)
                )
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
    }
}

/* #Preview {
 ContentView()
 } */
