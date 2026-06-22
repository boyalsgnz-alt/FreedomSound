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
        audioEngine.$currentlyPlayingTrack
            .dropFirst()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                Task {
                    await self?.updateLockScreenInfo()
                }
            }
            .store(in: &cancellables)
        
        // Met à jour le lock screen quand play/pause change
        audioEngine.$isPlaying
            .dropFirst()
            .sink { [weak self] _ in
                Task {
                    await self?.updateLockScreenInfo()
                }
            }
            .store(in: &cancellables)
        
        audioEngine.$currentTime
            .dropFirst()
            .sink { [weak self] _ in
                guard let self else { return }
                var info = MPNowPlayingInfoCenter.default().nowPlayingInfo ?? [:]
                info[MPNowPlayingInfoPropertyElapsedPlaybackTime] = self.audioEngine.player?.currentTime
                info[MPNowPlayingInfoPropertyPlaybackRate] = self.audioEngine.player?.isPlaying == true ? 1.0 : 0.0
                MPNowPlayingInfoCenter.default().nowPlayingInfo = info
            }
            .store(in: &cancellables)
    }
    
    private func updateLockScreenInfo() async {
        guard let currentFile = playbackQueue.currentTrack, let player = audioEngine.player else { return }
        
        let artwork = await ArtworkLoader.shared.loadArtwork(for: currentFile.url, fullSize: false).value
        
        var info: [String: Any] = [
            MPMediaItemPropertyTitle: currentFile.title,
            MPMediaItemPropertyArtist: currentFile.artist,
            MPNowPlayingInfoPropertyElapsedPlaybackTime: player.currentTime,
            MPMediaItemPropertyPlaybackDuration: player.duration,
            MPNowPlayingInfoPropertyPlaybackRate: player.isPlaying ? 1.0 : 0.0
        ]
        
        info[MPMediaItemPropertyArtwork] = MPMediaItemArtwork(boundsSize: artwork!.size) { _ in artwork! }
        
        MPNowPlayingInfoCenter.default().nowPlayingInfo = info
    }
    
    private func setupRemoteTransportControls() {
        let queue = playbackQueue
        let engine = audioEngine
        let commandCenter = MPRemoteCommandCenter.shared()
        
        commandCenter.playCommand.addTarget { _ in
            engine.resume()
            return .success
        }
        
        commandCenter.pauseCommand.addTarget { _ in
            engine.pause()
            return .success
        }
        
        commandCenter.nextTrackCommand.addTarget { _ in
            queue.nextTrack()
            return .success
        }
        
        commandCenter.previousTrackCommand.addTarget { _ in
            queue.prevTrack(currentTime: self.audioEngine.currentTime)
            return .success
        }
        
        commandCenter.changePlaybackPositionCommand.addTarget { event in
            guard
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
