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
    @State private var showSearch = false
    @State var query: String = ""
    @Binding var floatingPlayerHeight: CGFloat
    
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
                            playbackMgr.setCurrentTrack(track: file)
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
                .safeAreaInset(edge: .bottom) {
                    Color.clear.frame(height: floatingPlayerHeight)
                }
                .navigationTitle(playbackMgr.currentPlaylist!.name)
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
}

/* #Preview {
 SongListView(title: "Songs", songs: [])
 } */
