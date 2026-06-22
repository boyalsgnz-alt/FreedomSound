//
//  AudioPlayer.swift
//  FreedomSound
//
//  Created by Gaëtan Boyals on 12/04/2026.
//

import SwiftUI
import MediaPlayer
import AVFoundation
import Combine

enum RepeatMode {
    case off
    case all
    case one

    mutating func next() {
        switch self {
        case .off:
            self = .all
        case .all:
            self = .one
        case .one:
            self = .off
        }
    }

    var iconName: String {
        switch self {
        case .off, .all:
            return "repeat"
        case .one:
            return "repeat.1"
        }
    }

    var color: Color {
        switch self {
        case .off:
            return .white
        case .all, .one:
            return .green
        }
    }
}

class AudioEngine: NSObject, ObservableObject, AVAudioPlayerDelegate {
    var player: AVAudioPlayer?
    @Published var isPlaying = false
    @Published var currentTime: Double = 0
    @Published var duration: Double = 0
    @Published var isScrubbing: Bool = false
    @Published private(set) var currentlyPlayingTrack: Track? = nil
    
    var onTrackFinished: (() -> Void)?
    
    private var progressTask: Task<Void, Never>?
    private var artworkTask: Task<Void, Never>?
    
    private var isAudioSessionConfigured: Bool = false
    
    init(playbackQueue: PlaybackQueuee) {
        super.init()
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleInterruption),
            name: AVAudioSession.interruptionNotification,
            object: AVAudioSession.sharedInstance()
        )
    }
    
    private func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to set audio session category: \(error)")
        }
    }
    
    @objc
    func handleInterruption(notification: Notification) {
        guard
            let userInfo = notification.userInfo,
            let interruptionTypeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
            let interruptionType = AVAudioSession.InterruptionType(rawValue: interruptionTypeValue)
        else {
            return
        }

        switch interruptionType {
        case .began:
            pause()
        case .ended:
            let optionsValue = userInfo[AVAudioSessionInterruptionOptionKey] as? UInt ?? 0
            let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue)
            if options.contains(.shouldResume) {
                resume()
            }
        @unknown default:
            break
        }
    }
    
    func seek(to time: TimeInterval) {
        guard let player else { return }

        let clampedTime = max(0, min(time, player.duration))
        player.currentTime = clampedTime
        currentTime = clampedTime
        duration = player.duration
    }
    
    func play(track: Track?) {
        do {
            if !isAudioSessionConfigured {
                setupAudioSession()
                isAudioSessionConfigured = true
            }
            guard let track else { return }
            let newPlayer = try AVAudioPlayer(contentsOf: track.url)
            newPlayer.delegate = self
            newPlayer.prepareToPlay()
            
            guard newPlayer.play() else {
                return
            }
            currentlyPlayingTrack = track
            player = newPlayer
            currentTime = newPlayer.currentTime
            duration = newPlayer.duration
            isPlaying = true
            startProgressTimer()
        } catch {
            print(error)
        }
    }
    
    private func startProgressTimer() {
        stopProgressTimer()
        progressTask = Task { @MainActor [weak self] in
            while !Task.isCancelled {
                guard let self else { return }

                if let player = self.player, !self.isScrubbing {
                    self.currentTime = player.currentTime
                    self.duration = player.duration
                }

                try? await Task.sleep(for: .milliseconds(500))
            }
        }
    }

    private func stopProgressTimer() {
        progressTask?.cancel()
        progressTask = nil
    }
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        stopProgressTimer()
        isPlaying = false
        onTrackFinished?()
//        guard flag else { return }
//
//        if let nextFile = queue.nextFile(autoAdvance: true) {
//            play(file: nextFile, updateQueueSelection: false)
//        } else {
//            finishPlayback()
//        }
    }
    
    private func finishPlayback() {
        player?.currentTime = 0
        currentTime = 0
        duration = player?.duration ?? 0
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
    }
    
    func pause() {
        guard let player else { return }
        player.pause()
        isPlaying = false
    }
    
    func resume() {
        guard let player else { return }
        guard player.play() else { return }
        isPlaying = true
    }
    
}
