//
//  FreedomSoundApp.swift
//  FreedomSound
//
//  Created by Gaëtan Boyals on 05/04/2026.
//

import SwiftUI
import AVFoundation

@main
struct FreedomSoundApp: App {
    @StateObject private var folderManager: FolderManager
    @StateObject private var playbackManager: PlaybackQueue
    @StateObject private var libraryStore: LibraryStore
    @StateObject private var audioEngine: AudioEngine
    private let scanner = LibraryScanner()
    private let parser = MetadataParser()
    private let lockScreen: LockScreenManager
    
    private let coordinator: LibraryCoordinator
    let notificationDelegate = NotificationDelegate()
    
    init() {
        let libraryStore = LibraryStore()
        let folderManager = FolderManager()
        let playbackManager = PlaybackQueue()
        let audioEngine = AudioEngine(playbackQueue: playbackManager)
        
        self.coordinator = LibraryCoordinator(
            libScanner: scanner,
            folderMgr: folderManager,
            playbackMgr: playbackManager,
            metadataParser: parser,
            libraryStore: libraryStore,
            audioEngine: audioEngine
        )
        self.lockScreen = LockScreenManager(playbackQueue: playbackManager, audioEngine: audioEngine)
        
        _folderManager = StateObject(wrappedValue: folderManager)
        _playbackManager = StateObject(wrappedValue: playbackManager)
        _libraryStore = StateObject(wrappedValue: libraryStore)
        
        audioEngine.onTrackFinished = { [weak playbackManager] in
            playbackManager?.nextTrack()
        }
        _audioEngine = StateObject(wrappedValue: audioEngine)
        
        UNUserNotificationCenter.current().delegate = notificationDelegate
        requestNotificationPermission()
        scheduleExpiryReminder()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(folderManager)
                .environmentObject(libraryStore)
                .environmentObject(playbackManager)
                .environmentObject(audioEngine)
                .task(id: folderManager.musicFolder) {
                    guard folderManager.musicFolder != nil else { return }
                    await coordinator.loadLibrary()
                }
        }
    }
}
