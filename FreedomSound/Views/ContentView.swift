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
        VStack(spacing: 2) {
            Button {
                router.go(to: screen)
            } label: {
                Image(systemName: router.currentScreen == screen ? "\(screen.iconName).fill" : screen.iconName)
                    .font(.system(size: 21, weight: .medium))
                    .foregroundStyle(router.currentScreen == screen ? .white : .gray)
                    .frame(maxWidth: .infinity, minHeight: 24)
            }
            .buttonStyle(.plain)

            Text(label)
                .font(.system(size: 10, weight: router.currentScreen == screen ? .medium : .light))
                .foregroundStyle(router.currentScreen == screen ? .white : .gray)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
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
            .id(router.currentScreen)
            .transition(
                .asymmetric(
                    insertion: .move(edge: router.transitionDirection.insertionEdge),
                    removal: .move(edge: router.transitionDirection.removalEdge)
                )
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .clipped()
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
            .padding(.top, 5)
            .padding(.bottom, 3)
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
