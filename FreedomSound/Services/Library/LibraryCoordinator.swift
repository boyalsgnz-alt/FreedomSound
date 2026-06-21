//
//  LibraryCoordinator.swift
//  FreedomSound
//
//  Created by Gaëtan Boyals on 18/06/2026.
//

import Foundation
import SwiftUI

final class LibraryCoordinator {
    let libScanner: LibraryScanner
    let folderMgr: FolderManager
    let playbackMgr: PlaybackQueuee
    let metadataParser: MetadataParser
    let libStore: LibraryStore
    
    init(libScanner: LibraryScanner, folderMgr: FolderManager, playbackMgr: PlaybackQueuee, metadataParser: MetadataParser, libraryStore: LibraryStore) {
        self.libScanner = libScanner
        self.folderMgr = folderMgr
        self.playbackMgr = playbackMgr
        self.metadataParser = metadataParser
        self.libStore = libraryStore
    }
    
    func loadLibrary() async {
        do {
            let files = try libScanner.scanFolder(folderUrl: folderMgr.musicFolder) ?? []
            let (songs, playlists) = await metadataParser.parseAudioFiles(files: files)
            libStore.tracks = songs
            libStore.playlists = playlists
        } catch {
            print(error)
        }
    }
}
