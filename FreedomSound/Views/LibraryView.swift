//
//  LibraryView.swift
//  FreedomSound
//
//  Created by Gaëtan Boyals on 16/04/2026.
//

import SwiftUI

struct LibraryView: View {
    @State private var showingFolderPicker = false
    @State private var path = NavigationPath()
    @EnvironmentObject var manager: FolderAccessManager
    @EnvironmentObject var router: Router
    
    @State private var items = ["All Songs", "Playlists"]
    
    var body: some View {
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
        }
    }
}

#Preview {
    LibraryView()
}
