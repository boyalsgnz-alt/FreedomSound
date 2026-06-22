//
//  PlaybackQueue.swift
//  FreedomSound
//
//  Created by Gaëtan Boyals on 18/06/2026.
//

import Combine
import Foundation

final class PlaybackQueuee: ObservableObject {
    @Published var playlistTracks: [Track]
    @Published var playlistTracksShuffled: [Track]
    @Published var currentPlaylist: Playlist?
    @Published var currentTrack: Track?
    @Published var isShuffled: Bool
    @Published var repeatMode: RepeatMode
    private var currentIndex: Int = 0
    
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
    
    func setAllSongs(tracks: [Track]) {
        guard !tracks.isEmpty else { return }
            let playlist = Playlist(
                id: "allsongs",
                name: "All Songs",
                sourceURL: nil,
                trackFileNames: tracks.map { $0.fileName }
            )
            setNewPlaylist(playlist: playlist, tracks: tracks)
    }
    
    var activePlaylist: [Track] {
        isShuffled ? playlistTracksShuffled : playlistTracks
    }
    
    func enableShuffle() {
        if (!isShuffled) {
            var remaining = playlistTracks.filter { $0 != currentTrack! }
            remaining.shuffle()
            playlistTracksShuffled = [currentTrack!] + remaining
            currentIndex = 0
        }
        isShuffled.toggle()
    }
    
    func shiftRepeatMode() {
        self.repeatMode.next()
    }
    
    func setCurrentTrack(track: Track) {
        currentIndex = playlistTracks.firstIndex(of: track)!
        currentTrack = playlistTracks[currentIndex]
    }
    
    func nextTrack() {
        switch repeatMode {
        case .one:
            currentTrack = currentTrack
        case .all:
            if currentIndex + 1 >= activePlaylist.count {
                currentIndex = 0
                currentTrack = activePlaylist[0]
            } else {
                currentIndex = currentIndex + 1
                currentTrack = activePlaylist[currentIndex]
            }
        case .off:
            if currentIndex + 1 < activePlaylist.count {
                currentIndex = currentIndex + 1
                currentTrack = activePlaylist[currentIndex]
            }
        }
    }
    
    func prevTrack(currentTime: TimeInterval) {
        if currentTime >= 2 {
            currentTrack = currentTrack
        } else {
            switch repeatMode {
            case .one:
                currentTrack = currentTrack
            case .all:
                if currentIndex - 1 < 0 {
                    currentIndex = activePlaylist.count - 1
                    currentTrack = activePlaylist[currentIndex]
                } else {
                    currentIndex = currentIndex - 1
                    currentTrack = activePlaylist[currentIndex]
                }
            case .off:
                if currentIndex - 1 >= 0 {
                    currentIndex = currentIndex - 1
                    currentTrack = activePlaylist[currentIndex]
                }
            }
        }
    }
    
    func searchTracks(query: String) -> [Track] {
        if query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return playlistTracks
        }
        
        return playlistTracks.filter {
            $0.title.localizedCaseInsensitiveContains(query) ||
            $0.artist.localizedCaseInsensitiveContains(query)
        }
    }
    
}
