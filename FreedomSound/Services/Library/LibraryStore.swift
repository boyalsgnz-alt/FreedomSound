//
//  LibraryStore.swift
//  FreedomSound
//
//  Created by Gaëtan Boyals on 19/06/2026.
//

import Combine

class LibraryStore: ObservableObject {
    @Published var tracks: [Track]
    @Published var playlists: [Playlist] 
    
    init() {
        self.tracks = []
        self.playlists = []
    }
}
