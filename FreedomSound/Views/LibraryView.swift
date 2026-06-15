//
//  LibraryView.swift
//  FreedomSound
//
//  Created by Gaëtan Boyals on 16/04/2026.
//

import SwiftUI

struct RowHighlightButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
        // Changes color dynamically based on configuration.isPressed
            .background(configuration.isPressed ? Color.gray.opacity(0.2) : Color.clear)
    }
}

struct LibraryView: View {
    @State private var showingFolderPicker = false
    @State private var path = NavigationPath()
    @EnvironmentObject var manager: FolderAccessManager
    @EnvironmentObject var router: Router
    @State private var search = "Search"
    
    @State private var items = ["All Songs", "Playlists"]
    
    var body: some View {
        //        VStack(spacing: 0) {
        //
        //            NavigationStack(path: $path) {
        //                List {
        //                    Button {
        //                        path.append(AppScreen.viewtester)
        //                    }
        //                    label: {
        //                        Text("All Songs")
        //                    }
        //                    .navigationDestination(for: AppScreen.self) { _ in
        //                        SongListView(
        //                            title: "All Songs",
        //                            songs: manager.musicFiles,
        //                            onBack: { router.goToHome() }
        //                        ) // Destination
        //                    }
        //                    .navigationTitle("Library")
        //                }
        //                .listStyle(.plain)
        //                .sheet(isPresented: $showingFolderPicker) {
        //                    FolderPicker { url in
        //                        manager.savePickedFolder(url)
        //                        manager.scanFolder()
        //                        showingFolderPicker = false
        //                    }
        //                }
        //                  Button {
        //                      path.append(AppScreen.viewtester)
        //                  } label: {
        //                    Text("ViewTester") // Source
        //                  }
        //                  .navigationDestination(for: AppScreen.self) { _ in
        //                      SongListView(
        //                          title: "All Songs",
        //                          songs: manager.musicFiles,
        //                          onBack: { router.goToHome() }
        //                      ) // Destination
        //                  }
        //                }
        //            Text("Your library")
        //                .font(.title)
        //                .frame(maxWidth: .infinity, alignment: .center)
        //                .padding()
        //
        //            List {
        //                Button {
        //                    router.goToViewTester()
        //                }
        //                label: {
        //                    HStack(spacing: 12) {
        //                        Text("All Songs")
        //                        Spacer()
        //                        Image(systemName: "chevron.right")
        //                            .font(.caption)
        //                            .foregroundStyle(.secondary)
        //                    }
        //                }
        //                .contentShape(Rectangle())
        //
        //                RowButtonTest(minHeight: 34) {
        //                    router.goToViewTester()
        //                } content: {
        //                    HStack(spacing: 12) {
        //                        Text("All Songs")
        //                        Spacer()
        //                        Image(systemName: "chevron.right")
        //                            .font(.caption)
        //                            .foregroundStyle(.secondary)
        //                    }
        //                }
        //                .contentShape(Rectangle())
        //
        //                RowButtonTest(minHeight: 34) {
        //                    router.goToPlaylists()
        //                } content: {
        //                    HStack(spacing: 12) {
        //                        Text("Playlists")
        //                        Spacer()
        //                        Image(systemName: "chevron.right")
        //                            .font(.caption)
        //                            .foregroundStyle(.secondary)
        //                    }
        //                }
        //                .contentShape(Rectangle())
        //            }
        //            .listStyle(.plain)
        //            .sheet(isPresented: $showingFolderPicker) {
        //                FolderPicker { url in
        //                    manager.savePickedFolder(url)
        //                    manager.scanFolder()
        //                    showingFolderPicker = false
        //                }
        //            }
        //        }
        NavigationStack(path: $path) {
            VStack(spacing: 0) {
                
                List(items, id: \.self) { item in
                    NavigationLink(item, value: item)
                }
                .navigationDestination(for: String.self) { item in
                    switch item {
                    case "All Songs":
                        SongListView(
                            title: "All Songs",
                            songs: manager.musicFiles,
                            onBack: { router.goToHome() })
                    case "Playlists":
                        PlaylistsView()
                    default:
                        Text("Unknown Destination")
                    }
                }
                .listStyle(.plain)
            }
            .navigationTitle("Library")
        }
    }
}

#Preview {
    LibraryView()
}
