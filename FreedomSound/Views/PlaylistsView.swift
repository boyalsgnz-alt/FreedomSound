//
//  PlaylistsView.swift
//  FreedomSound
//
//  Created by Gaëtan Boyals on 18/04/2026.
//

import SwiftUI

struct PlaylistsView: View {
    @EnvironmentObject var router: Router
    @EnvironmentObject var manager: FolderAccessManager
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button {
                    router.goToHome()
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
                Text("Playlists")
            }
            .padding()
            
            List() {
                if manager.playlists.isEmpty {
                    Text("No playlists found")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(manager.playlists) { playlist in
                        Button {
                            manager.selectPlaylist(playlist)
                            router.goToPlaylistSongs()
                        } label: {
                            HStack {
                                Text(playlist.name)
                                Spacer()
                                Text("\(playlist.trackFileNames.count)")
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }
}

#Preview {
    PlaylistsView()
}
