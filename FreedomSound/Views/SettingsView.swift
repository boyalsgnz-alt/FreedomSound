//
//  SettingsView.swift
//  FreedomSound
//
//  Created by Gaëtan Boyals on 16/04/2026.
//

import SwiftUI
import AVFoundation
import MediaPlayer

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
            Grid(horizontalSpacing: 30, verticalSpacing: 30) {
                GridRow {
                    CountdownView()
                        .glassEffect(.regular.tint(Color(.sRGB, red: 215/255, green: 222/255, blue: 224/255, opacity: 0.5)).interactive(), in: .rect(cornerRadius: 16.0))
                        .aspectRatio(1, contentMode: .fit)
                    // .clipShape(RoundedRectangle(cornerRadius: 10))
                    
                    RoundedRectangle(cornerRadius: 16)
                        .glassEffect(.regular.tint(Color.clear).interactive(), in: .rect(cornerRadius: 16.0))
                        .aspectRatio(1, contentMode: .fit)
                }
                
                GridRow {
                    Rectangle().fill(Color.blue)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .aspectRatio(1, contentMode: .fit)
                    
                    Rectangle().background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.blue)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .aspectRatio(1, contentMode: .fit)
                }
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
            Button {
                showingFolderPicker.toggle()
            } label: {
                Label("Choose Folder", systemImage: "folder.badge.gearshape")
            }
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
