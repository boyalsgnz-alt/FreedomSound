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

@MainActor
final class PlaybackQueue {
    private let libraryProvider: () -> [MusicFile]
    private(set) var currentSongID: MusicFile.ID?
    private var history: [MusicFile.ID] = []
    private var shufflePath: [MusicFile.ID] = []
    private var shuffleIndex: Int?

    var isShuffleOn = false
    var repeatMode: RepeatMode = .off

    init(libraryProvider: @escaping () -> [MusicFile]) {
        self.libraryProvider = libraryProvider
    }

    var currentFile: MusicFile? {
        guard let currentSongID else { return nil }
        return libraryProvider().first(where: { $0.id == currentSongID })
    }

    func setShuffleEnabled(_ isEnabled: Bool) {
        isShuffleOn = isEnabled

        guard let currentSongID else {
            resetShufflePath()
            return
        }

        if isEnabled {
            if shufflePath.isEmpty {
                shufflePath = [currentSongID]
                shuffleIndex = 0
            } else if let existingIndex = shufflePath.firstIndex(of: currentSongID) {
                shuffleIndex = existingIndex
            } else {
                shufflePath = [currentSongID]
                shuffleIndex = 0
            }
        } else {
            resetShufflePath()
        }
    }

    func select(_ file: MusicFile) {
        pushCurrentSongIfNeeded(beforeSelecting: file)
        currentSongID = file.id

        if isShuffleOn {
            appendToShufflePath(fileID: file.id)
        } else {
            resetShufflePath()
        }
    }

    func nextFile(autoAdvance: Bool) -> MusicFile? {
        let files = libraryProvider()
        guard !files.isEmpty else { return nil }

        guard
            var currentSongID,
            let currentIndex = files.firstIndex(where: { $0.id == currentSongID })
        else {
            currentSongID = files[0].id
            return files[0]
        }

        let currentFile = files[currentIndex]

        if autoAdvance && repeatMode == .one {
            return currentFile
        }

        let nextFile: MusicFile?
        if isShuffleOn {
            nextFile = shuffledSuccessor(from: files, currentFile: currentFile)
        } else {
            nextFile = sequentialSuccessor(from: files, currentIndex: currentIndex, autoAdvance: autoAdvance)
        }

        guard let nextFile else { return nil }

        if nextFile.id != currentFile.id {
            history.append(currentFile.id)
            trimHistoryIfNeeded()
        }

        currentSongID = nextFile.id
        return nextFile
    }

    func previousFile(currentPlaybackTime: TimeInterval) -> MusicFile? {
        let files = libraryProvider()
        guard !files.isEmpty else { return nil }

        if currentPlaybackTime > 2 {
            return currentFile
        }

        if isShuffleOn {
            return shuffledPredecessor(from: files)
        }

        guard
            var currentSongID,
            let currentIndex = files.firstIndex(where: { $0.id == currentSongID })
        else {
            currentSongID = files[0].id
            return files[0]
        }

        if currentIndex > 0 {
            let previousFile = files[currentIndex - 1]
            currentSongID = previousFile.id
            return previousFile
        }

        if repeatMode == .all, let lastFile = files.last {
            currentSongID = lastFile.id
            return lastFile
        }

        return files[currentIndex]
    }

    func clear() {
        currentSongID = nil
        history.removeAll()
        resetShufflePath()
    }

    private func sequentialSuccessor(
        from files: [MusicFile],
        currentIndex: Int,
        autoAdvance: Bool
    ) -> MusicFile? {
        let nextIndex = currentIndex + 1

        if nextIndex < files.count {
            return files[nextIndex]
        }

        if autoAdvance {
            return repeatMode == .all ? files.first : nil
        }

        return files.first
    }

    private func randomSuccessor(from files: [MusicFile], currentFile: MusicFile) -> MusicFile? {
        guard files.count > 1 else { return currentFile }

        let candidates = files.filter { $0.id != currentFile.id }
        return candidates.randomElement() ?? currentFile
    }

    private func shuffledSuccessor(from files: [MusicFile], currentFile: MusicFile) -> MusicFile? {
        if let shuffleIndex, shuffleIndex + 1 < shufflePath.count {
            let nextSongID = shufflePath[shuffleIndex + 1]
            if let nextFile = files.first(where: { $0.id == nextSongID }) {
                self.shuffleIndex = shuffleIndex + 1
                currentSongID = nextFile.id
                return nextFile
            }
        }

        guard let randomNextFile = randomSuccessor(from: files, currentFile: currentFile) else {
            return currentFile
        }

        appendToShufflePath(fileID: randomNextFile.id)
        currentSongID = randomNextFile.id
        return randomNextFile
    }

    private func shuffledPredecessor(from files: [MusicFile]) -> MusicFile? {
        guard let shuffleIndex, shuffleIndex > 0 else {
            return currentFile
        }

        let previousSongID = shufflePath[shuffleIndex - 1]
        guard let previousFile = files.first(where: { $0.id == previousSongID }) else {
            return currentFile
        }

        self.shuffleIndex = shuffleIndex - 1
        currentSongID = previousFile.id
        return previousFile
    }

    private func pushCurrentSongIfNeeded(beforeSelecting file: MusicFile) {
        guard let currentSongID, currentSongID != file.id else { return }
        history.append(currentSongID)
        trimHistoryIfNeeded()
    }

    private func appendToShufflePath(fileID: MusicFile.ID) {
        if let shuffleIndex, shuffleIndex < shufflePath.count - 1 {
            shufflePath.removeSubrange((shuffleIndex + 1)..<shufflePath.count)
        }

        if shufflePath.last != fileID {
            shufflePath.append(fileID)
        }

        shuffleIndex = shufflePath.indices.last
    }

    private func resetShufflePath() {
        shufflePath.removeAll()
        shuffleIndex = nil
    }

    private func trimHistoryIfNeeded() {
        let maxHistoryCount = 100
        if history.count > maxHistoryCount {
            history.removeFirst(history.count - maxHistoryCount)
        }
    }
}

@MainActor
final class AudioPlayer: NSObject, ObservableObject, AVAudioPlayerDelegate {
    private var queue: PlaybackQueue
    private var player: AVAudioPlayer?
    private var progressTask: Task<Void, Never>?
    private var artworkTask: Task<Void, Never>?
    private var isAudioSessionConfigured = false

    @Published var isPlaying = false {
        didSet { updateLockScreenInfo() }
    }
    @Published var currentFile: MusicFile?
    @Published var isShuffleOn = false {
        didSet { queue.setShuffleEnabled(isShuffleOn) }
    }
    @Published var repeatMode: RepeatMode = .off {
        didSet { queue.repeatMode = repeatMode }
    }
    @Published var currentArtworkSmall: UIImage?
    @Published var currentArtworkLarge: UIImage?
    @Published var currentTime: Double = 0
    @Published var duration: Double = 0
    @Published var isScrubbing = false
    
    var currentQueueSongID: MusicFile.ID? {
        queue.currentSongID
    }

    init(folderAccessManager: FolderAccessManager) {
        self.queue = PlaybackQueue(libraryProvider: { folderAccessManager.musicFiles })
        super.init()
        setupRemoteTransportControls()

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleInterruption),
            name: AVAudioSession.interruptionNotification,
            object: AVAudioSession.sharedInstance()
        )
    }
    
    func setNewQueue(playlist: [MusicFile]) -> Void {
        self.queue = PlaybackQueue(libraryProvider: { playlist })
        self.queue.setShuffleEnabled(isShuffleOn)
        self.queue.repeatMode = repeatMode
    }

    func play(file: MusicFile, updateQueueSelection: Bool = true) {
        do {
            if !isAudioSessionConfigured {
                setupAudioSession()
                isAudioSessionConfigured = true
            }

            let newPlayer = try AVAudioPlayer(contentsOf: file.url)
            newPlayer.delegate = self
            newPlayer.prepareToPlay()

            guard newPlayer.play() else {
                print("play() failed")
                return
            }

            player = newPlayer
            if updateQueueSelection {
                queue.select(file)
            }
            currentFile = file
            currentTime = newPlayer.currentTime
            duration = newPlayer.duration
            isPlaying = true

            startArtworkLoad(for: file)
            startProgressTimer()
            updateLockScreenInfo()
        } catch {
            print("Error loading file: \(error)")
        }
    }

    func nextSong() {
        guard let nextFile = queue.nextFile(autoAdvance: false) else { return }
        play(file: nextFile, updateQueueSelection: false)
    }

    func prevSong() {
        guard let previousFile = queue.previousFile(currentPlaybackTime: player?.currentTime ?? 0) else { return }

        if previousFile.id == currentFile?.id {
            seek(to: 0)
            if !isPlaying {
                resume()
            }
            return
        }

        play(file: previousFile, updateQueueSelection: false)
    }

    func repeatClick() {
        repeatMode.next()
    }

    func pause() {
        guard let player else { return }
        player.pause()
        isPlaying = false
        stopProgressTimer()
    }

    func resume() {
        guard let player else { return }
        guard player.play() else { return }
        isPlaying = true
        startProgressTimer()
    }

    func togglePlayPause() {
        guard let player else { return }

        if player.isPlaying {
            pause()
        } else {
            resume()
        }
    }

    func seek(to time: TimeInterval) {
        guard let player else { return }

        let clampedTime = max(0, min(time, player.duration))
        player.currentTime = clampedTime
        currentTime = clampedTime
        duration = player.duration
        updateLockScreenInfo()
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

    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        stopProgressTimer()
        isPlaying = false

        guard flag else { return }

        if let nextFile = queue.nextFile(autoAdvance: true) {
            play(file: nextFile, updateQueueSelection: false)
        } else {
            finishPlayback()
        }
    }

    private func finishPlayback() {
        player?.currentTime = 0
        currentTime = 0
        duration = player?.duration ?? 0
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
    }

    private func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to set audio session category: \(error)")
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

    private func startArtworkLoad(for file: MusicFile) {
        artworkTask?.cancel()

        let cachedArtwork = ArtworkLoader.shared.cachedImage(for: file.url)
        currentArtworkSmall = cachedArtwork
        currentArtworkLarge = cachedArtwork

        artworkTask = Task { [weak self] in
            guard let self else { return }

            let smallArtwork = await ArtworkLoader.shared
                .loadArtwork(for: file.url, fullSize: false)
                .value

            guard !Task.isCancelled, self.currentFile?.id == file.id else { return }
            self.currentArtworkSmall = smallArtwork
            self.updateLockScreenInfo()

            let largeArtwork = await ArtworkLoader.shared
                .loadArtwork(for: file.url, fullSize: true)
                .value

            guard !Task.isCancelled, self.currentFile?.id == file.id else { return }
            self.currentArtworkLarge = largeArtwork
            self.updateLockScreenInfo()
        }
    }

    private func updateLockScreenInfo() {
        guard let currentFile, let player else { return }

        var info: [String: Any] = [
            MPMediaItemPropertyTitle: currentFile.title,
            MPMediaItemPropertyArtist: currentFile.artist,
            MPNowPlayingInfoPropertyElapsedPlaybackTime: player.currentTime,
            MPMediaItemPropertyPlaybackDuration: player.duration,
            MPNowPlayingInfoPropertyPlaybackRate: isPlaying ? 1.0 : 0.0
        ]

        if let artwork = currentArtworkLarge ?? currentArtworkSmall {
            info[MPMediaItemPropertyArtwork] = MPMediaItemArtwork(boundsSize: artwork.size) { _ in artwork }
        }

        MPNowPlayingInfoCenter.default().nowPlayingInfo = info
    }

    private func setupRemoteTransportControls() {
        let commandCenter = MPRemoteCommandCenter.shared()

        commandCenter.playCommand.addTarget { [weak self] _ in
            guard let self else { return .commandFailed }
            self.resume()
            return .success
        }

        commandCenter.pauseCommand.addTarget { [weak self] _ in
            guard let self else { return .commandFailed }
            self.pause()
            return .success
        }

        commandCenter.nextTrackCommand.addTarget { [weak self] _ in
            guard let self else { return .commandFailed }
            self.nextSong()
            return .success
        }

        commandCenter.previousTrackCommand.addTarget { [weak self] _ in
            guard let self else { return .commandFailed }
            self.prevSong()
            return .success
        }

        commandCenter.changePlaybackPositionCommand.addTarget { [weak self] event in
            guard
                let self,
                let event = event as? MPChangePlaybackPositionCommandEvent
            else {
                return .commandFailed
            }

            self.seek(to: event.positionTime)
            return .success
        }

        commandCenter.playCommand.isEnabled = true
        commandCenter.pauseCommand.isEnabled = true
        commandCenter.nextTrackCommand.isEnabled = true
        commandCenter.previousTrackCommand.isEnabled = true
        commandCenter.changePlaybackPositionCommand.isEnabled = true
    }
}

// MARK: - Legacy implementation kept for reference
/*
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
 
 var isActive: Bool {
 self != .off
 }
 }
 
 final class AudioPlayer: NSObject, ObservableObject, AVAudioPlayerDelegate {
 private let folderAccessManager: FolderAccessManager
 private var player: AVAudioPlayer?
 private var formatter = DateComponentsFormatter()
 private var progressTimer: Timer?
 private var isAudioSessionSetup: Bool = false;
 @Published private var currentSongID: MusicFile.ID?
 
 @Published var isPlaying = false
 @Published var currentFile: MusicFile?
 @Published var isShuffleOn = false
 @Published var repeatMode: RepeatMode = .off
 @Published var currentArtworkSmall: UIImage?
 @Published var currentArtworkLarge: UIImage?
 @Published var currentTime: Double = 0
 @Published var duration: Double = 0
 @Published var isScrubbing = false
 
 init(folderAccessManager: FolderAccessManager) {
 self.folderAccessManager = folderAccessManager
 super.init()
 setupRemoteTransportControls()
 formatter.allowedUnits = [.minute, .second]
 formatter.unitsStyle = .positional
 formatter.zeroFormattingBehavior = .pad
 
 NotificationCenter.default.addObserver(self,
 selector: #selector(handleInterruption),
 name: AVAudioSession.interruptionNotification,
 object: AVAudioSession.sharedInstance())
 
 }
 
 @objc func handleInterruption(notification: Notification) {
 guard let userInfo = notification.userInfo,
 let interruptionTypeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
 let interruptionType = AVAudioSession.InterruptionType(rawValue: interruptionTypeValue) else {
 return
 }
 
 switch interruptionType {
 case .began:
 isPlaying = false
 case .ended:
 break
 @unknown default:
 break
 }
 }
 
 @MainActor
 func loadArtwork(for file: MusicFile) async {
 currentArtworkSmall = await ArtworkLoader.shared
 .loadArtwork(for: file.url, fullSize: false)
 .value
 
 currentArtworkLarge = await ArtworkLoader.shared
 .loadArtwork(for: file.url, fullSize: true)
 .value
 }
 
 func play(file: MusicFile) {
 do {
 let newPlayer = try AVAudioPlayer(contentsOf: file.url)
 newPlayer.delegate = self
 newPlayer.prepareToPlay()
 
 self.player = newPlayer
 self.currentFile = file
 self.currentSongID = file.id
 
 if newPlayer.play() {
 Task {
 await loadArtwork(for: file)
 updateLockScreenInfo()
 }
 duration = player?.duration ?? 0
 currentTime = player?.currentTime ?? 0
 isPlaying = true
 if !isAudioSessionSetup {
 setupAudioSession()
 isAudioSessionSetup = true
 }
 
 startProgressTimer()
 updateLockScreenInfo()
 print("Playback started")
 } else {
 print("play() failed")
 }
 } catch {
 print("Error loading file: \(error)")
 }
 }
 
 func getCurrentPlayerTime() -> String {
 if let formattedString = formatter.string(from: player!.currentTime) {
 return formattedString
 }
 return "OO:OO"
 }
 
 func getFormattedDuration() -> String {
 if let formattedString = formatter.string(from: player!.duration) {
 return formattedString
 }
 return "OO:OO"
 }
 
 func nextSong() {
 let files = folderAccessManager.musicFiles
 guard !files.isEmpty else { return }
 
 let nextFile: MusicFile
 
 if isShuffleOn {
 nextFile = files.randomElement()!
 } else {
 guard let currentSongID else {
 nextFile = files[0]
 play(file: nextFile)
 return
 }
 
 guard let currentIndex = files.firstIndex(where: { $0.id == currentSongID }) else {
 nextFile = files[0]
 play(file: nextFile)
 return
 }
 
 let nextIndex = (currentIndex + 1) % files.count
 nextFile = files[nextIndex]
 }
 
 play(file: nextFile)
 }
 
 func prevSong() {
 play(file: currentFile!)
 }
 
 func repeatClick() {
 repeatMode.next()
 switch repeatMode {
 case .off:
 player?.numberOfLoops = 1
 case .all:
 player?.numberOfLoops = 1
 case .one:
 player?.numberOfLoops = -1
 }
 }
 
 func pause() {
 player?.pause()
 isPlaying = false
 stopProgressTimer()
 updateLockScreenInfo()
 }
 
 func resume() {
 player?.play()
 isPlaying = true
 startProgressTimer()
 updateLockScreenInfo()
 }
 
 private func startProgressTimer() {
 stopProgressTimer()
 
 progressTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
 guard let self, let player = self.player else { return }
 guard !self.isScrubbing else { return }
 
 self.currentTime = player.currentTime
 self.duration = player.duration
 }
 }
 
 private func stopProgressTimer() {
 progressTimer?.invalidate()
 progressTimer = nil
 }
 
 func togglePlayPause() {
 guard let player else { return }
 
 if player.isPlaying {
 pause()
 } else {
 resume()
 }
 }
 
 func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
 print("Finished playing called")
 print("success:", flag)
 isPlaying = false
 
 if player.numberOfLoops >= 0 {
 nextSong()
 }
 }
 
 func setupAudioSession() {
 do {
 try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
 try AVAudioSession.sharedInstance().setActive(true)
 
 } catch {
 print("Failed to set audio session category: \\(error)")
 }
 }
 
 func updateLockScreenInfo() {
 guard let file = currentFile, let player else { return }
 
 var info: [String: Any] = [
 MPMediaItemPropertyTitle: file.title,
 MPMediaItemPropertyArtist: file.artist,
 MPNowPlayingInfoPropertyElapsedPlaybackTime: player.currentTime,
 MPMediaItemPropertyPlaybackDuration: player.duration,
 MPNowPlayingInfoPropertyPlaybackRate: isPlaying ? 1.0 : 0.0
 ]
 
 if let currentArtworkSmall {
 info[MPMediaItemPropertyArtwork] = MPMediaItemArtwork(
 boundsSize: currentArtworkSmall.size
 ) { _ in currentArtworkSmall }
 }
 
 MPNowPlayingInfoCenter.default().nowPlayingInfo = info
 
 }
 
 @MainActor
 func seek(to time: TimeInterval) {
 guard let player else { return }
 
 let clamped = max(0, min(time, player.duration))
 player.currentTime = clamped
 currentTime = clamped
 duration = player.duration
 
 updateLockScreenInfo()
 }
 
 func setupRemoteTransportControls() {
 let commandCenter = MPRemoteCommandCenter.shared()
 
 commandCenter.playCommand.addTarget { [weak self] _ in
 guard let self else { return .commandFailed }
 self.resume()
 return .success
 }
 
 commandCenter.pauseCommand.addTarget { [weak self] _ in
 guard let self else { return .commandFailed }
 self.pause()
 return .success
 }
 
 commandCenter.nextTrackCommand.addTarget { [weak self] _ in
 guard let self else { return .commandFailed }
 self.nextSong()
 return .success
 }
 
 commandCenter.previousTrackCommand.addTarget { [weak self] _ in
 guard let self else { return .commandFailed }
 self.prevSong()
 return .success
 }
 
 commandCenter.changePlaybackPositionCommand.addTarget { [weak self] event in
 guard
 let self,
 let event = event as? MPChangePlaybackPositionCommandEvent
 else {
 return .commandFailed
 }
 
 self.seek(to: event.positionTime)
 return .success
 }
 
 commandCenter.playCommand.isEnabled = true
 commandCenter.pauseCommand.isEnabled = true
 commandCenter.nextTrackCommand.isEnabled = true
 commandCenter.changePlaybackPositionCommand.isEnabled = true
 }
 }
 */
