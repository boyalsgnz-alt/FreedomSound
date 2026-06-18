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
    let notificationDelegate = NotificationDelegate()

    init() {
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
                    .environmentObject(audioPlayer)
                    .task {
                        folderAccessManager.scanFolder()
                    }
        }
    }
}
