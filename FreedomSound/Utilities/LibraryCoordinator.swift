//
//  LibraryCoordinator.swift
//  FreedomSound
//
//  Created by Gaëtan Boyals on 18/06/2026.
//

final class LibraryCoordinator {
    let libScanner: LibraryScanner
    let folderMgr: FolderManager
    let playbackMgr: PlaybackManager
    let metadataParser: MetadataParser
    
    init(libScanner: LibraryScanner, folderMgr: FolderManager, playbackMgr: PlaybackManager, metadataParser: MetadataParser) {
        self.libScanner = libScanner
        self.folderMgr = folderMgr
        self.playbackMgr = playbackMgr
        self.metadataParser = metadataParser
    }
    
    func loadLibrary() {
        var folderToScan = folderMgr.musicFolder
        // var [filesURL, playlistFiles] = libScanner.scanFolder(folderToScan)
        // var musicFiles = metadataParser.parseFiles(filesURL)
        // playbackMgr.setAllSongs(musicFiles)
        // playbackMgr.setPlaylists(playlistFiles)
    }
}
