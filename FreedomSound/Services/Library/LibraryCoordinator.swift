//
//  LibraryCoordinator.swift
//  FreedomSound
//
//  Created by Gaëtan Boyals on 18/06/2026.
//

import Foundation
import SwiftUI
import Combine

final class LibraryCoordinator {
    let libScanner: LibraryScanner
    let folderMgr: FolderManager
    let playbackMgr: PlaybackQueue
    let metadataParser: MetadataParser
    let libStore: LibraryStore
    let audioEngine: AudioEngine
    
    var cancellables = Set<AnyCancellable>()
    
    init(libScanner: LibraryScanner, folderMgr: FolderManager, playbackMgr: PlaybackQueue, metadataParser: MetadataParser, libraryStore: LibraryStore, audioEngine: AudioEngine) {
        self.libScanner = libScanner
        self.folderMgr = folderMgr
        self.playbackMgr = playbackMgr
        self.metadataParser = metadataParser
        self.libStore = libraryStore
        self.audioEngine = audioEngine
        
        audioEngine.onTrackFinished = { [weak playbackMgr] in
            playbackMgr?.nextTrack()
        }
        playbackMgr.$currentTrack
            .dropFirst()
            .sink { [weak audioEngine] track in
                audioEngine?.play(track: track)
            }
            .store(in: &cancellables)
    }
    
    func loadLibrary() async {
        do {
            let files = try libScanner.scanFolder(folderUrl: folderMgr.musicFolder) ?? []
            Task.detached(priority: .userInitiated) {
                let (songs, playlists) = await self.metadataParser.parseAudioFiles(files: files)
                
                await MainActor.run {
                    self.libStore.tracks = songs
                    self.libStore.playlists = playlists
                }
            }
        } catch {
            print(error)
        }
    }
}
