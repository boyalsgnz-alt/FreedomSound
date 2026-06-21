//
//  LibraryView.swift
//  FreedomSound
//
//  Created by Gaëtan Boyals on 16/04/2026.
//

import SwiftUI

struct LibraryView: View {
    @State private var showingFolderPicker = false
    @State private var navPath = NavigationPath()
    @EnvironmentObject var manager: FolderAccessManager
    @EnvironmentObject var libraryStore: LibraryStore
    @EnvironmentObject var playbackMgr: PlaybackQueuee
    
    @State private var items = ["All Songs", "Playlists"]
    
    var body: some View {
        NavigationStack(path: $navPath) {
            VStack(spacing: 0) {
                
                List(items, id: \.self) { item in
                    NavigationLink(item, value: item)
                }
                .navigationDestination(for: String.self) { item in
                    switch item {
                    case "All Songs":
                        SongListView(
                            title: "All Songs")
                        .onAppear() {
                            playbackMgr.setAllSongs(tracks: libraryStore.tracks)
                        }
                    case "Playlists":
                        PlaylistsView(navPath: $navPath)
                    default:
                        Text("Unknown Destination")
                    }
                }
                .listStyle(.plain)
            }
        }
    }
}

#Preview {
    LibraryView()
}
