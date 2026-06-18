import Foundation
import Combine
import UniformTypeIdentifiers
import ImageIO

import SwiftUI
import AVFoundation
import UniformTypeIdentifiers
import UIKit
import Combine
import MediaPlayer

final class FolderManager: ObservableObject {
    @Published var musicFolder: URL?
    private let bookmarkKey = "SelectedMusicFolderBookmark"
    
    init() {
        restoreFolderFromBookmark()
    }
    
    func savePickedFolder(_ folderURL: URL) {
        let didAccess = folderURL.startAccessingSecurityScopedResource()
        defer {
            if didAccess {
                folderURL.stopAccessingSecurityScopedResource()
            }
        }
        
        do {
            let bookmarkData = try folderURL.bookmarkData(
                options: [],
                includingResourceValuesForKeys: nil,
                relativeTo: nil
            )
            
            UserDefaults.standard.set(bookmarkData, forKey: bookmarkKey)
            musicFolder = folderURL
        } catch {
            print("Failed to save bookmark:", error)
        }
    }
    
    func restoreFolderFromBookmark() {
        guard let bookmarkData = UserDefaults.standard.data(forKey: bookmarkKey) else {
            return
        }
        
        do {
            var isStale = false
            let url = try URL(
                resolvingBookmarkData: bookmarkData,
                options: [],
                relativeTo: nil,
                bookmarkDataIsStale: &isStale
            )
            
            if isStale {
                let newBookmark = try url.bookmarkData(
                    options: [],
                    includingResourceValuesForKeys: nil,
                    relativeTo: nil
                )
                UserDefaults.standard.set(newBookmark, forKey: bookmarkKey)
            }
            print("restored bookmark")
            musicFolder = url
        } catch {
            return
        }
    }
    
    func clearSavedFolder() {
        UserDefaults.standard.removeObject(forKey: bookmarkKey)
        musicFolder = nil
    }
    
    deinit {
        musicFolder?.stopAccessingSecurityScopedResource()
        musicFolder = nil
    }
}

@MainActor
final class FolderAccessManager: ObservableObject {
    @Published var selectedFolderURL: URL?
    @Published var musicFiles: [MusicFile] = []
    @Published var currentPlaylist: [MusicFile] = []
    @Published var currentPlaylistName: String = "Playlist"
    @Published var playlists: [Playlist] = []
    @Published var statusMessage: String = "No folder selected"
    private let bookmarkKey = "SelectedMusicFolderBookmark"
    
    @State private var searchText = ""
    
    init() {
        restoreFolderFromBookmark()
    }
    
    
    static let supportedAudioExtensions: Set<String> = [
        "mp3", "m4a", "aac", "wav", "flac", "aif", "aiff", "caf", "ogg"
    ]
    
    func savePickedFolder(_ folderURL: URL) {
        let didAccess = folderURL.startAccessingSecurityScopedResource()
        defer {
            if didAccess {
                folderURL.stopAccessingSecurityScopedResource()
            }
        }
        
        do {
            let bookmarkData = try folderURL.bookmarkData(
                options: [],
                includingResourceValuesForKeys: nil,
                relativeTo: nil
            )
            
            UserDefaults.standard.set(bookmarkData, forKey: bookmarkKey)
            selectedFolderURL = folderURL
            statusMessage = "Folder saved: \(folderURL.lastPathComponent)"
        } catch {
            print("Failed to save bookmark:", error)
            statusMessage = "Failed to save folder bookmark: \(error.localizedDescription)"
        }
    }
    
    func restoreFolderFromBookmark() {
        
        guard let bookmarkData = UserDefaults.standard.data(forKey: bookmarkKey) else {
            selectedFolderURL = nil
            statusMessage = "Pick your music folder"
            return
        }
        
        do {
            var isStale = false
            let url = try URL(
                resolvingBookmarkData: bookmarkData,
                options: [],
                relativeTo: nil,
                bookmarkDataIsStale: &isStale
            )
            
            if isStale {
                let newBookmark = try url.bookmarkData(
                    options: [],
                    includingResourceValuesForKeys: nil,
                    relativeTo: nil
                )
                UserDefaults.standard.set(newBookmark, forKey: bookmarkKey)
            }
            
            selectedFolderURL = url
            statusMessage = "Using saved folder: \(url.lastPathComponent)"
        } catch {
            print("Failed to resolve bookmark:", error)
            selectedFolderURL = nil
            musicFiles = []
            statusMessage = "Saved folder could not be restored. Please pick it again."
        }
    }
    
    func clearSavedFolder() {
        UserDefaults.standard.removeObject(forKey: bookmarkKey)
        selectedFolderURL = nil
        musicFiles = []
        playlists = []
        currentPlaylist = []
        currentPlaylistName = "Playlist"
        statusMessage = "Saved folder cleared"
    }
    
    func selectPlaylist(_ playlist: Playlist) {
        currentPlaylist = playlist.trackFileNames.compactMap { trackFileName in
            musicFiles.first(where: { song in
                song.fileName == trackFileName || song.url.lastPathComponent == trackFileName
            })
        }
        currentPlaylistName = playlist.name
    }

    func parseM3U(fileURL: URL, library: [MusicFile]) -> Playlist? {
        do {
            let content = try String(contentsOf: fileURL, encoding: .utf8)
            let lines = content.components(separatedBy: .newlines)

            guard lines.first == "#EXTM3U" else {
                print("No EXTM3U tag in \(fileURL.lastPathComponent), skipping...")
                return nil
            }

            var playlistName = fileURL.deletingPathExtension().lastPathComponent
            var trackFileNames: [String] = []

            for line in lines.dropFirst() {
                if line.starts(with: "#PLAYLIST:") {
                    let extractedName = line.replacingOccurrences(of: "#PLAYLIST:", with: "")
                        .trimmingCharacters(in: .whitespacesAndNewlines)
                    if !extractedName.isEmpty {
                        playlistName = extractedName
                    }
                    continue
                }

                if line.hasPrefix("#") || line.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    continue
                }

                let rawPath = line.trimmingCharacters(in: .whitespacesAndNewlines)
                let decodedPath = rawPath.removingPercentEncoding ?? rawPath

                if let found = library.first(where: { element in
                    element.fileName == decodedPath || element.url.lastPathComponent == decodedPath
                }) {
                    trackFileNames.append(found.fileName)
                }
            }

            return Playlist(
                id: fileURL.path,
                name: playlistName,
                sourceURL: fileURL,
                trackFileNames: trackFileNames
            )
        } catch {
            print("Error reading M3U file: \(error)")
            return nil
        }
    }
    
    func scanFolder() {
        guard let folderURL = selectedFolderURL else {
            statusMessage = "No folder selected"
            musicFiles = []
            return
        }
        
        Task {
            let didAccess = folderURL.startAccessingSecurityScopedResource()
            guard didAccess else {
                self.musicFiles = []
                self.statusMessage = "Saved folder is no longer accessible. Please choose it again."
                return
            }
            
            do {
                
                var foundPlaylistsURLs: [URL] = []
                
                let basicFiles = try await Task.detached(priority: .userInitiated) {
                    let lmao = try self.recursiveAudioFiles(in: folderURL)
                    
                    let foundURLs = lmao.0
                        .sorted {
                            $0.lastPathComponent.localizedCaseInsensitiveCompare($1.lastPathComponent) == .orderedAscending
                        }
                    foundPlaylistsURLs = lmao.1
                    return foundURLs.map { MusicFile(url: $0) }
                }.value
                
                self.playlists = foundPlaylistsURLs.compactMap { item in
                    parseM3U(fileURL: item, library: basicFiles)
                }
                
                loadMetadataProgressively(for: basicFiles)
                
            } catch {
                self.musicFiles = []
                self.playlists = []
                self.statusMessage = "Scan failed: \(error.localizedDescription)"
            }
        }
    }

        
    func searchSongs(in songs: [MusicFile], text: String) -> [MusicFile] {
        if text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return songs
        }
        
        return songs.filter {
            $0.title.localizedCaseInsensitiveContains(text) ||
            $0.artist.localizedCaseInsensitiveContains(text)
        }
    }
    
    private nonisolated func recursiveAudioFiles(in folderURL: URL) throws -> ([URL], [URL]) {
        let keys: Set<URLResourceKey> = [
            .isDirectoryKey,
            .isRegularFileKey,
            .contentTypeKey,
            .nameKey
        ]
        
        guard let enumerator = FileManager.default.enumerator(
            at: folderURL,
            includingPropertiesForKeys: Array(keys),
            options: [.skipsHiddenFiles, .skipsPackageDescendants]
        ) else {
            throw NSError(
                domain: "FolderAccessManager",
                code: 1,
                userInfo: [NSLocalizedDescriptionKey: "Could not enumerate folder."]
            )
        }
        
        var results: [URL] = []
        var playl: [URL] = []
        
        for case let fileURL as URL in enumerator {
            do {
                let values = try fileURL.resourceValues(forKeys: keys)
                
                if values.isDirectory == true {
                    continue
                }
                
                guard values.isRegularFile == true else {
                    continue
                }
                
                if let contentType = values.contentType {
                    if contentType.conforms(to: .audio) {
                        results.append(fileURL)
                    }
                    else {
                        let ext = fileURL.pathExtension.lowercased()
                        if Self.supportedAudioExtensions.contains(ext) {
                            results.append(fileURL)
                        }
                        if (ext.starts(with: "m3u")) {
                            playl.append(fileURL)
                        }
                    }
                }
            } catch {
                print("Skipping unreadable item:", fileURL.lastPathComponent, "error:", error)
            }
        }
        return (results, playl)
    }

    private func loadMetadataProgressively(for files: [MusicFile]) {
        let maxConcurrentLoads = 4
        let publishBatchSize = 200

        Task.detached(priority: .utility) { [weak self] in
            var updatedFiles = files
            var nextIndexToSchedule = 0
            var completedCount = 0

            await withTaskGroup(of: (Int, MusicFile).self) { group in
                let initialTaskCount = min(maxConcurrentLoads, files.count)

                for _ in 0..<initialTaskCount {
                    let index = nextIndexToSchedule
                    group.addTask {
                        let updated = await Self.loadMetadata(for: files[index])
                        return (index, updated)
                    }
                    nextIndexToSchedule += 1
                }

                while let (index, updatedFile) = await group.next() {
                    updatedFiles[index] = updatedFile
                    completedCount += 1

                    if nextIndexToSchedule < files.count {
                        let nextIndex = nextIndexToSchedule
                        group.addTask {
                            let updated = await Self.loadMetadata(for: files[nextIndex])
                            return (nextIndex, updated)
                        }
                        nextIndexToSchedule += 1
                    }

                    if completedCount % publishBatchSize == 0 || completedCount == files.count {
                        let snapshot = updatedFiles
                        await MainActor.run {
                            self?.musicFiles = snapshot
                        }
                    }
                }
            }
            await MainActor.run {
                self?.selectedFolderURL?.stopAccessingSecurityScopedResource()
            }
        }
    }
    
    private static func loadMetadata(for file: MusicFile) async -> MusicFile {
        var updatedFile = file
        let asset = AVURLAsset(url: file.url)
        
        do {
            let metadata = try await asset.load(.commonMetadata)
            
            if let title = AVMetadataItem.metadataItems(
                from: metadata,
                withKey: AVMetadataKey.commonKeyTitle,
                keySpace: .common
            ).first?.stringValue,
               !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                updatedFile.title = title
            }
            
            if let artist = AVMetadataItem.metadataItems(
                from: metadata,
                withKey: AVMetadataKey.commonKeyArtist,
                keySpace: .common
            ).first?.stringValue,
               !artist.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                updatedFile.artist = artist
            }
        } catch {
            print("Metadata load failed for \(file.fileName): \(error.localizedDescription)")
        }
        
        return updatedFile
    }
}
