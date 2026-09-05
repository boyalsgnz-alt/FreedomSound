//
//  SongListView.swift
//  FreedomSound
//
//  Created by Gaëtan Boyals on 16/04/2026.
//

import SwiftUI
import AVFoundation
import MediaPlayer

struct SongListView: View {
    @EnvironmentObject var playbackMgr: PlaybackQueue
    @EnvironmentObject var libraryStore: LibraryStore
    
    @State private var showSearch = false
    @State private var query: String = ""
    @State private var debouncedQuery: String = ""
    @Binding var floatingPlayerHeight: CGFloat
    @State private var filteredSongs: [Track] = []
    
    let playlist: Playlist
    
    var tracks: [Track] {
        // The synthetic "All Songs" playlist has no sourceURL and its trackFileNames are only
        // a snapshot taken when it was navigated to — always mirror the live library instead.
        guard playlist.sourceURL != nil else {
            return libraryStore.tracks
        }
        return playlist.trackFileNames.compactMap { fileName in
            libraryStore.tracks.first { $0.fileName == fileName }
        }
    }
    
    var body: some View {
        Group {
            if filteredSongs.isEmpty {
                VStack(spacing: 0) {
                    Spacer()
                    Text("No song found")
                        .foregroundStyle(.secondary)
                    Spacer()
                }
            } else {
                SongListContent(
                    filteredSongs: filteredSongs,
                    playlist: playlist,
                    libraryStore: libraryStore,
                    onSelect: { file in
                        playbackMgr.setNewPlaylist(playlist: playlist, tracks: tracks)
                        playbackMgr.setCurrentTrack(track: file)
                    }
                )
            }
        }
        .searchable(text: $query)
        .task(id: query) {
            guard !query.isEmpty else {
                debouncedQuery = ""
                return
            }
            do {
                try await Task.sleep(for: .milliseconds(400))
                debouncedQuery = query
            } catch {
            }
        }
        .onChange(of: debouncedQuery) { _, _ in
            applyFilter()
        }
        .onChange(of: libraryStore.tracks) { _, _ in
            applyFilter()
        }
        .onAppear {
            applyFilter()
        }
    }

    private func applyFilter() {
        let trimmedQuery = debouncedQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedQuery.isEmpty {
            filteredSongs = tracks
        } else {
            filteredSongs = tracks.filter {
                $0.title.localizedCaseInsensitiveContains(trimmedQuery) ||
                $0.artist.localizedCaseInsensitiveContains(trimmedQuery)
            }
        }
    }
}

/* #Preview {
 SongListView(title: "Songs", songs: [])
 } */
