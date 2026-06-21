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
    @EnvironmentObject var manager: FolderAccessManager
    @EnvironmentObject var playbackMgr: PlaybackQueuee
    @EnvironmentObject var audioPlayer: AudioPlayer
    @State private var showSearch = false
    
    @State var query: String = ""
    let title: String
    let songs: [Track]
    
    private var filteredSongs: [Track] {
        playbackMgr.searchTracks(query: query)
    }
    
    var body: some View {
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
                            RowButton(minHeight: 30) {
                                playbackMgr.playSong(track: file)
                                //audioPlayer.setNewQueue(playlist: songs)
                                // audioPlayer.play(file: file)
                            } content: {
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
                .searchable(text: $query)
                .overlay(alignment: .bottom) {
                    if playbackMgr.currentTrack != nil {
                        FloatingPlayerView()
                            .padding(.horizontal, 8)
                            .padding(.vertical, 8)
                    }
                }
                .navigationTitle(title)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            withAnimation {
                                if let first = songs.first {
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
}

#Preview {
    SongListView(title: "Songs", songs: [])
}
