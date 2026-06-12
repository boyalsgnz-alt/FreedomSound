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
    @EnvironmentObject var audioPlayer: AudioPlayer

    @State var search: String = ""
    let title: String
    let songs: [MusicFile]
    let onBack: () -> Void

    private var filteredSongs: [MusicFile] {
        manager.searchSongs(in: songs, text: search)
    }

    var body: some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Button {
                        onBack()
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.title3)
                            .frame(width: 36, height: 36)
                            .background {
                                Circle()
                                    .fill(.gray.opacity(0.2))
                            }
                            .foregroundStyle(.gray)
                    }

                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundStyle(.gray)

                        TextField("Search...", text: $search)
                            .autocorrectionDisabled(true)
                            .textInputAutocapitalization(.never)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(.gray.opacity(0.2))
                    )
                }

                Text(title)
                    .font(.headline)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
            .padding()

            if songs.isEmpty {
                Spacer()
                Text("No song found")
                    .foregroundStyle(.secondary)
                Spacer()
            } else {
                List(filteredSongs) { file in
                    MusicRowView(file: file)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            audioPlayer.setNewQueue(playlist: songs)
                            audioPlayer.play(file: file)
                        }
                        .listRowSeparator(.hidden)
                        .listRowInsets(EdgeInsets())

                }
                .listRowSpacing(16)
                .listStyle(.plain)
                .padding(.horizontal, 12)
            }
        }
        .overlay(alignment: .bottom) {
            if audioPlayer.currentFile != nil {
                FloatingPlayerView()
                    .padding(.horizontal, 8)
            }
        }
    }
}

#Preview {
    SongListView(title: "Songs", songs: [], onBack: {})
}
