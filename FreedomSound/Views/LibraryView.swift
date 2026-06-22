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
    @EnvironmentObject var libraryStore: LibraryStore
    @EnvironmentObject var playbackMgr: PlaybackQueue
    
    @State private var items = ["All Songs", "Playlists"]
    
    var body: some View {
        NavigationStack(path: $navPath) {
            VStack {
                Text("Library")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                List(items, id: \.self) { item in
                    NavigationLink(item, value: item)
                        .listRowSeparator(.hidden)
                }
                .listStyle(.plain)
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
            }
        }
    }
}

#Preview {
    LibraryView()
}
