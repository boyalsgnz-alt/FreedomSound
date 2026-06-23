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
    @State private var floatingPlayerHeight: CGFloat = 0
    
    @EnvironmentObject var libraryStore: LibraryStore
    @EnvironmentObject var playbackMgr: PlaybackQueue
    
    @State private var items = ["All Songs", "Playlists"]
    
    private func allSongsPlaylist() -> Playlist {
        Playlist(
            id: "allsongs",
            name: "All Songs",
            sourceURL: nil,
            trackFileNames: libraryStore.tracks.map { $0.fileName }
        )
    }
    
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
                        SongListView(floatingPlayerHeight: $floatingPlayerHeight, playlist: allSongsPlaylist())
                    case "Playlists":
                        PlaylistsView(navPath: $navPath, floatingPlayerHeight: $floatingPlayerHeight)
                    default:
                        Text("Unknown Destination")
                    }
                }
            }
        }
        .overlay(alignment: .bottom) {
            if playbackMgr.currentTrack != nil {
                FloatingPlayerView()
                    .padding(.horizontal, 8)
                    .padding(.vertical, 8)
                    .onGeometryChange(for: CGFloat.self) { geo in
                        geo.size.height
                    } action: { height in
                        floatingPlayerHeight = height
                    }
            }
        }
    }
}

#Preview {
    LibraryView()
}
