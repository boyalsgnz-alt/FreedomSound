//
//  PlaybackQueue.swift
//  FreedomSound
//
//  Created by Gaëtan Boyals on 18/06/2026.
//

import Combine
import Foundation

final class PlaybackQueuee: ObservableObject {
    @Published var playlistTracks: [Track]?
    @Published var playlistTracksShuffled: [Track]?
    @Published var currentPlaylist: Playlist?
    @Published var currentTrack: Track?
    @Published var isShuffled: Bool
    @Published var repeatMode: RepeatMode
    @Published var currentIndex: Int = 0
    
    init() {
        self.currentPlaylist = nil
        self.playlistTracks = []
        self.playlistTracksShuffled = []
        self.isShuffled = false
        self.repeatMode = RepeatMode.off
    }
    
    func setNewPlaylist(playlist: Playlist, tracks: [Track]) {
        playlistTracks = tracks
        currentPlaylist = playlist
    }
    
    var activePlaylist: [Track]? {
        isShuffled ? playlistTracksShuffled : playlistTracks
    }
    
    func enableShuffle() {
        var remaining = playlistTracks!.filter { $0 != currentTrack! }
        remaining.shuffle()
        playlistTracksShuffled = [currentTrack!] + remaining
    }
    
    func shiftRepeatMode() {
        self.repeatMode.next()
    }
    
    func playSong(track: Track) {
        currentIndex = playlistTracks!.firstIndex(of: track)!
        currentTrack = playlistTracks![currentIndex]
    }
    
    func nextTrack() {
        
    }
    
    func prevTrack() {
        
    }
    
    func searchTracks(query: String) -> [Track] {
        if query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return playlistTracks!
        }
        
        return playlistTracks!.filter {
            $0.title.localizedCaseInsensitiveContains(query) ||
            $0.artist.localizedCaseInsensitiveContains(query)
        }
    }
    
}
