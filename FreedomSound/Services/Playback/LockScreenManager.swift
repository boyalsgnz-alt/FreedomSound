//
//  LockScreenManager.swift
//  FreedomSound
//
//  Created by Gaëtan Boyals on 20/06/2026.
//

import MediaPlayer
import Combine

class LockScreenManager {
    private let playbackQueue: PlaybackQueuee
    private let audioEngine: AudioEngine
    private var cancellables = Set<AnyCancellable>()

    init(playbackQueue: PlaybackQueuee, audioEngine: AudioEngine) {
        self.playbackQueue = playbackQueue
        self.audioEngine = audioEngine
        setupRemoteTransportControls()
        observeChanges()
    }

    private func observeChanges() {
        // Met à jour le lock screen quand le track change
        playbackQueue.$currentTrack
            .sink { [weak self] _ in self?.updateLockScreenInfo() }
            .store(in: &cancellables)

        // Met à jour le lock screen quand play/pause change
        audioEngine.$isPlaying
            .sink { [weak self] _ in self?.updateLockScreenInfo() }
            .store(in: &cancellables)
        
        audioEngine.$currentTime
            .sink { [weak self] _ in self?.updateLockScreenInfo() }
            .store(in: &cancellables)
    }
    
    private func updateLockScreenInfo() {
        guard let currentFile = playbackQueue.currentTrack, let player = audioEngine.player else { return }

        var info: [String: Any] = [
            MPMediaItemPropertyTitle: currentFile.title,
            MPMediaItemPropertyArtist: currentFile.artist,
            MPNowPlayingInfoPropertyElapsedPlaybackTime: player.currentTime,
            MPMediaItemPropertyPlaybackDuration: player.duration,
            MPNowPlayingInfoPropertyPlaybackRate: player.isPlaying ? 1.0 : 0.0
        ]

//        if let artwork = currentArtworkLarge ?? currentArtworkSmall {
//            info[MPMediaItemPropertyArtwork] = MPMediaItemArtwork(boundsSize: artwork.size) { _ in artwork }
//        }

        MPNowPlayingInfoCenter.default().nowPlayingInfo = info
    }

    private func setupRemoteTransportControls() {
        let queue = playbackQueue
        let engine = audioEngine
        let commandCenter = MPRemoteCommandCenter.shared()

        commandCenter.playCommand.addTarget { [weak self] _ in
            guard let self else { return .commandFailed }
            engine.resume()
            return .success
        }

        commandCenter.pauseCommand.addTarget { [weak self] _ in
            guard let self else { return .commandFailed }
            engine.pause()
            return .success
        }

        commandCenter.nextTrackCommand.addTarget { [weak self] _ in
            guard let self else { return .commandFailed }
            queue.nextTrack()
            return .success
        }

        commandCenter.previousTrackCommand.addTarget { [weak self] _ in
            guard let self else { return .commandFailed }
            queue.prevTrack()
            return .success
        }

        commandCenter.changePlaybackPositionCommand.addTarget { [weak self] event in
            guard
                let self,
                let event = event as? MPChangePlaybackPositionCommandEvent
            else {
                return .commandFailed
            }

            engine.seek(to: event.positionTime)
            return .success
        }

        commandCenter.playCommand.isEnabled = true
        commandCenter.pauseCommand.isEnabled = true
        commandCenter.nextTrackCommand.isEnabled = true
        commandCenter.previousTrackCommand.isEnabled = true
        commandCenter.changePlaybackPositionCommand.isEnabled = true
    }
}
