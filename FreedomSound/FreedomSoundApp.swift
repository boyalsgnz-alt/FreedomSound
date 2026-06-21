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
    @StateObject private var folderAccessManager = FolderAccessManager()
    @StateObject private var audioPlayer: AudioPlayer
    
    /* NEW CODE */
    @StateObject private var folderManager: FolderManager
    @StateObject private var playbackManager: PlaybackQueuee
    @StateObject private var libraryStore: LibraryStore
    @StateObject private var audioEngine: AudioEngine
    private let scanner = LibraryScanner()
    private let parser = MetadataParser()
    
    private let coordinator: LibraryCoordinator
    /* END OF NEW CODE */
    let notificationDelegate = NotificationDelegate()
    
    init() {
        /* NEW CODE */
        let libraryStore = LibraryStore()
        let folderManager = FolderManager()
        let playbackManager = PlaybackQueuee()
        let audioEngine = AudioEngine(playbackQueue: playbackManager)
        
        self.coordinator = LibraryCoordinator(
            libScanner: scanner,
            folderMgr: folderManager,
            playbackMgr: playbackManager,
            metadataParser: parser,
            libraryStore: libraryStore
        )
        
        _folderManager = StateObject(wrappedValue: folderManager)
        _playbackManager = StateObject(wrappedValue: playbackManager)
        _libraryStore = StateObject(wrappedValue: libraryStore)
        /* END OF NEW CODE */
        let manager = FolderAccessManager()
        _folderAccessManager = StateObject(wrappedValue: manager)
        _audioEngine = StateObject(wrappedValue: audioEngine)
        _audioPlayer = StateObject(wrappedValue: AudioPlayer(folderAccessManager: manager))
        
        UNUserNotificationCenter.current().delegate = notificationDelegate
        requestNotificationPermission()
        scheduleExpiryReminder()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(folderAccessManager)
                .environmentObject(folderManager)
                .environmentObject(audioPlayer)
                .environmentObject(libraryStore)
                .environmentObject(playbackManager)
                .environmentObject(audioEngine)
                .task(id: folderManager.musicFolder) {
                    /* Needs this line to load songs, old system */
                    folderAccessManager.scanFolder()
                    /* End of old system */
                    guard folderManager.musicFolder != nil else { return }
                    await coordinator.loadLibrary()
                }
        }
    }
}
