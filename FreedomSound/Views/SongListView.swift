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
        playlist.trackFileNames.compactMap { fileName in
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
                ScrollViewReader { proxy in
                    List() {
                        ForEach(filteredSongs) { file in
                            Button {
                                let filteredTracks = playlist.trackFileNames.compactMap { fileName in
                                    libraryStore.tracks.first { $0.fileName == fileName }
                                }
                                playbackMgr.setNewPlaylist(playlist: playlist, tracks: filteredTracks)
                                playbackMgr.setCurrentTrack(track: file)
                            } label: {
                                MusicRowView(file: file)
                            }.id(file.id)
                        }
                        .listRowSeparator(.hidden)
                        .listRowInsets(EdgeInsets())
                    }
                    .listRowSpacing(16)
                    .listStyle(.plain)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 0)
                    .safeAreaInset(edge: .bottom) {
                        Color.clear.frame(height: floatingPlayerHeight)
                    }
                    .navigationTitle(playlist.name)
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            Button {
                                withAnimation {
                                    if let first = filteredSongs.first {
                                        proxy.scrollTo(first.id, anchor: .top)
                                    }
                                }
                            } label: {
                                Image(systemName: "arrow.up")
                            }
                        }
                    }
                }
            }
        }
        .searchable(text: $query)
        .task(id: query) {
            guard !query.isEmpty else {
                debouncedQuery = ""
                return
            }
            do {
                try await Task.sleep(for: .milliseconds(1000))
                debouncedQuery = query
            } catch {
            }
        }
        .onChange(of: debouncedQuery) { _, newValue in
            if newValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                filteredSongs = tracks
            } else {
                filteredSongs = tracks.filter {
                    $0.title.localizedCaseInsensitiveContains(newValue) ||
                    $0.artist.localizedCaseInsensitiveContains(newValue)
                }
            }
        }
        .onAppear {
            filteredSongs = tracks
        }
    }
}

/* #Preview {
 SongListView(title: "Songs", songs: [])
 } */
