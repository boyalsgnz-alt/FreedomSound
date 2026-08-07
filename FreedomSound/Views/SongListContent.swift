//
//  SongListContent.swift
//  FreedomSound
//
//  Created by Gaëtan Boyals on 07/08/2026.
//

import SwiftUI
import AVFoundation

struct SongListContent: View {
    let filteredSongs: [Track]
    let playlist: Playlist
    let libraryStore: LibraryStore
    let onSelect: (Track) -> Void

    var body: some View {
        ScrollViewReader { proxy in
            List {
                ForEach(filteredSongs) { file in
                    Button {
                        onSelect(file)
                    } label: {
                        MusicRowView(file: file)
                    }
                    .id(file.id)
                }
                .listRowSeparator(.hidden)
                .listRowInsets(EdgeInsets())
            }
            .listRowSpacing(16)
            .listStyle(.plain)
            .padding(.horizontal, 12)
            .padding(.vertical, 0)
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
