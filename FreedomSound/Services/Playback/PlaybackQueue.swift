//
//  PlaybackQueue.swift
//  FreedomSound
//
//  Created by Gaëtan Boyals on 18/06/2026.
//

import Combine
import Foundation

final class PlaybackQueue: ObservableObject {
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
        playlistTracksShuffled = playlistTracks.shuffled()
        currentIndex = 0
    }
    
    var activePlaylist: [Track] {
        return isShuffled ? playlistTracksShuffled : playlistTracks
    }
    
    func enableShuffle() {
        isShuffled.toggle()
        if (!isShuffled) {
            currentIndex = playlistTracks.firstIndex(of: currentTrack!)!
        } else {
            currentIndex = playlistTracksShuffled.firstIndex(of: currentTrack!)!
        }
        print("currentIndex is \(currentIndex)")
    }
    
    func shiftRepeatMode() {
        self.repeatMode.next()
    }
    
    func setCurrentTrack(track: Track) {
        currentIndex = activePlaylist.firstIndex(of: track)!
        currentTrack = activePlaylist[currentIndex]
    }
    
    func nextTrack() {
        print("playlist is \(currentPlaylist!.name), with count of \(currentPlaylist!.trackFileNames.count) tracks")
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
}
