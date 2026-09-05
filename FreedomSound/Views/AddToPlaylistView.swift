//
//  AddToPlaylistView.swift
//  FreedomSound
//
//  Created by Gaëtan Boyals on 03/09/2026.
//

import SwiftUI

struct AddToPlaylistView: View {
    let track: Track

    @EnvironmentObject var libraryStore: LibraryStore
    @EnvironmentObject var libraryCoordinator: LibraryCoordinator
    @Environment(\.dismiss) private var dismiss

    @State private var newPlaylistName = ""
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            List {
                Section("New Playlist") {
                    HStack {
                        TextField("Playlist name", text: $newPlaylistName)
                        Button("Create") {
                            createNewPlaylist()
                        }
                        .disabled(newPlaylistName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                }

                if !libraryStore.playlists.isEmpty {
                    Section("Add to Existing") {
                        ForEach(libraryStore.playlists) { playlist in
                            Button {
                                addToExisting(playlist)
                            } label: {
                                HStack {
                                    Text(playlist.name)
                                    Spacer()
                                    Text("\(playlist.trackFileNames.count)")
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .foregroundStyle(.primary)
                        }
                    }
                }
            }
            .navigationTitle(track.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .alert(
                "Couldn't add song",
                isPresented: Binding(
                    get: { errorMessage != nil },
                    set: { if !$0 { errorMessage = nil } }
                )
            ) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage ?? "")
            }
        }
    }

    private func addToExisting(_ playlist: Playlist) {
        do {
            try libraryCoordinator.addTrack(track, to: playlist)
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func createNewPlaylist() {
        do {
            try libraryCoordinator.addTrack(track, toNewPlaylistNamed: newPlaylistName)
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
