//
//  PlaylistsView.swift
//  FreedomSound
//
//  Created by Gaëtan Boyals on 18/04/2026.
//

import SwiftUI

struct AppleRowButtonStyle: ButtonStyle {
    
    @State private var didTriggerHaptic = false
    
    func makeBody(configuration: Configuration) -> some View {
        
        configuration.label
            .contentShape(Rectangle())
            .background {
                Rectangle()
                    .fill(.primary.opacity(configuration.isPressed ? 0.08 : 0))
                    .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
            }
            .onChange(of: configuration.isPressed) { _, isPressed in
                if isPressed {
                    didTriggerHaptic = false
                } else if !didTriggerHaptic {
                    let generator = UIImpactFeedbackGenerator(style: .light)
                    generator.impactOccurred()
                    didTriggerHaptic = true
                }
            }
    }
}

struct RowButtonTest<Content: View>: View {
    let minHeight: CGFloat
    let action: () -> Void
    @ViewBuilder let content: () -> Content
    
    var body: some View {
        Button(action: action) {
            content()
                .frame(maxWidth: .infinity, minHeight: minHeight, alignment: .leading)
        }
        .buttonStyle(AppleRowButtonStyle())
    }
}

struct PlaylistsView: View {
    @EnvironmentObject var manager: FolderAccessManager
    @EnvironmentObject var libraryStore: LibraryStore
    @EnvironmentObject var playbackMgr: PlaybackQueuee
    @Binding var navPath: NavigationPath
    
    var body: some View {
        VStack(spacing: 0) {
            if libraryStore.playlists.isEmpty {
                Text("No playlists found")
                    .foregroundStyle(.secondary)
            } else {
                List(libraryStore.playlists, id: \.id) { playlist in
                    RowButtonTest(minHeight: 20) {
                        let tracks = libraryStore.tracks.filter {
                            playlist.trackFileNames.contains($0.fileName)
                        }
                        playbackMgr.setNewPlaylist(playlist: playlist, tracks: tracks)
                        // manager.selectPlaylist(playlist)
                        navPath.append(playlist)
                    } content: {
                        HStack {
                            Text(playlist.name)
                                .lineLimit(1)
                            
                            Spacer()
                            
                            Text("\(playlist.trackFileNames.count)")
                                .foregroundStyle(.secondary)
                            
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .listRowSeparator(.hidden)
                }
                .listStyle(.plain)
                .navigationDestination(for: Playlist.self) { item in
                    SongListView(
                        title: item.name)
                }
                .navigationTitle("Playlists")
            }
        }
    }
}

//#Preview {
//    PlaylistsView()
//}
