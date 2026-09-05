//
//  SettingsView.swift
//  FreedomSound
//
//  Created by Gaëtan Boyals on 16/04/2026.
//

import SwiftUI
import AVFoundation
import MediaPlayer

private struct FolderSquareView: View {
    let folderURL: URL?
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack {
                Image(systemName: folderURL != nil ? "checkmark.circle.fill" : "folder.badge.plus")
                    .font(.system(size: 35, weight: .semibold))
                    .frame(minWidth: 44, minHeight: 44)
                    .foregroundStyle(folderURL != nil ? Color(red: 33/255, green: 255/255, blue: 52/255) : .orange)
                Spacer()
                Text(folderURL != nil ? "Folder Selected" : "Select Folder")
                    .font(.system(size: 20, weight: .bold))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                Text(folderURL?.lastPathComponent ?? "Tap to choose")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .lineLimit(1)
            }
            .padding(12)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        }
        .buttonStyle(.plain)
    }
}

struct SettingsView: View {
    @EnvironmentObject var folderMgr: FolderManager
    @EnvironmentObject var libraryStore: LibraryStore
    @EnvironmentObject var libraryCoordinator: LibraryCoordinator
    @State private var showingFolderPicker = false
    @StateObject private var networkManager = NetworkManager()
    @State private var generatedPlaylistName = ""
    @State private var generationErrorMessage: String?

    var body: some View {
        VStack(){
            Text("Settings")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding(.bottom, 8)
            //            Spacer()
            //            InfinityLoader()
            //            Spacer()
            HStack(spacing: 30) {
                CountdownView()
                    .glassEffect(.regular.interactive(), in: .rect(cornerRadius: 16.0))
                    .aspectRatio(1, contentMode: .fit)

                FolderSquareView(folderURL: folderMgr.musicFolder) {
                    showingFolderPicker = true
                }
                .glassEffect(.regular.interactive(), in: .rect(cornerRadius: 16.0))
                .aspectRatio(1, contentMode: .fit)
            }
            .padding(8)

            VStack(spacing: 8) {
                TextField("Playlist name", text: $generatedPlaylistName)
                    .textFieldStyle(.roundedBorder)

                Button {
                    generatePlaylist()
                } label: {
                    if networkManager.isLoading {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                    } else {
                        Label("Generate Playlist", systemImage: "wand.and.stars")
                            .frame(maxWidth: .infinity)
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(networkManager.isLoading || generatedPlaylistName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .padding(.horizontal)

            Spacer()
        }
        .sheet(isPresented: $showingFolderPicker) {
            FolderPicker { url in
                folderMgr.savePickedFolder(url)
                showingFolderPicker = false
            }
        }
        .frame(maxWidth: .infinity)
        .alert(
            "Couldn't generate playlist",
            isPresented: Binding(
                get: { generationErrorMessage != nil },
                set: { if !$0 { generationErrorMessage = nil } }
            )
        ) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(generationErrorMessage ?? "")
        }
    }

    private func generatePlaylist() {
        let trimmedName = generatedPlaylistName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }

        Task {
            do {
                let fileNames = try await networkManager.generatePlaylist(named: trimmedName)
                let tracks = fileNames.compactMap { fileName in
                    libraryStore.tracks.first { $0.fileName == fileName }
                }
                guard !tracks.isEmpty else {
                    generationErrorMessage = "None of the generated songs were found in your library."
                    return
                }
                try libraryCoordinator.addTracks(tracks, toNewPlaylistNamed: trimmedName)
                generatedPlaylistName = ""
            } catch {
                generationErrorMessage = error.localizedDescription
            }
        }
    }
}

/* #Preview {
 SettingsView()
 }
 */
