//
//  LibraryCoordinator.swift
//  FreedomSound
//
//  Created by Gaëtan Boyals on 18/06/2026.
//

import Foundation
import SwiftUI
import Combine

final class LibraryCoordinator: ObservableObject {
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
            let files = try folderMgr.withAccessToFolder { url in
                try libScanner.scanFolder(folderUrl: url)
            }
            Task.detached(priority: .userInitiated) {
                let (songs, playlists) = await self.metadataParser.parseAudioFiles(files: files!!)
                
                await MainActor.run {
                    self.libStore.tracks = songs
                    self.libStore.playlists = playlists
                }
            }
        } catch {
            print(error)
        }
    }

    @MainActor
    func addTrack(_ track: Track, to playlist: Playlist) throws {
        guard let updated = try folderMgr.withAccessToFolder({ url in
            try PlaylistWriter.appendTrack(track, to: playlist, in: url)
        }) else { return }

        if let index = libStore.playlists.firstIndex(where: { $0.id == updated.id }) {
            libStore.playlists[index] = updated
        }
    }

    @MainActor
    func addTrack(_ track: Track, toNewPlaylistNamed name: String) throws {
        try addTracks([track], toNewPlaylistNamed: name)
    }

    @MainActor
    func addTracks(_ tracks: [Track], toNewPlaylistNamed name: String) throws {
        guard let newPlaylist = try folderMgr.withAccessToFolder({ url in
            try PlaylistWriter.createPlaylist(named: name, with: tracks, in: url)
        }) else { return }

        libStore.playlists.append(newPlaylist)
    }

    @MainActor
    func deletePlaylist(_ playlist: Playlist) throws {
        try folderMgr.withAccessToFolder { url in
            try PlaylistWriter.deletePlaylist(playlist, in: url)
        }
        libStore.playlists.removeAll { $0.id == playlist.id }
    }
}
