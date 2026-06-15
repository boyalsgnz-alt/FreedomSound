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
    @StateObject private var router: Router

    init() {
        let manager = FolderAccessManager()
        _folderAccessManager = StateObject(wrappedValue: manager)
        _audioPlayer = StateObject(wrappedValue: AudioPlayer(folderAccessManager: manager))
        _router = StateObject(wrappedValue: Router())
    }
    
    var body: some Scene {
        WindowGroup {
                ContentView()
                    .environmentObject(folderAccessManager)
                    .environmentObject(audioPlayer)
                    .environmentObject(router)
                    .task {
                        folderAccessManager.scanFolder()
                    }
        }
    }
}
