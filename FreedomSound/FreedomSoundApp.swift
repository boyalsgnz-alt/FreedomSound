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
    @StateObject private var folderManager = FolderManager()
    @StateObject private var playbackManager = PlaybackManager()
    private let scanner = LibraryScanner()
    private let parser = MetadataParser()
    
    private let coordinator: LibraryCoordinator
    /* END OF NEW CODE */
    let notificationDelegate = NotificationDelegate()
    
    init() {
        /* NEW CODE */
        let folderManager = FolderManager()
        let playbackManager = PlaybackManager()
        
        self.coordinator = LibraryCoordinator(
            libScanner: scanner,
            folderMgr: folderManager,
            playbackMgr: playbackManager,
            metadataParser: parser
        )
        
        _folderManager = StateObject(wrappedValue: folderManager)
        _playbackManager = StateObject(wrappedValue: playbackManager)
        /* END OF NEW CODE */
        let manager = FolderAccessManager()
        _folderAccessManager = StateObject(wrappedValue: manager)
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
                .task(id: folderManager.musicFolder) {
                    guard folderManager.musicFolder != nil else { return }
                    coordinator.loadLibrary()
                }
        }
    }
}
