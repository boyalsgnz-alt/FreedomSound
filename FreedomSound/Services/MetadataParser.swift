//
//  MetadataParser.swift
//  FreedomSound
//
//  Created by Gaëtan Boyals on 18/06/2026.
//

import Combine
import Foundation
import AVFoundation

final class MetadataParser {
    
    func parseAudioFiles(files: [URL]) async -> ([Track], [Playlist]) {
        var allSongs: [Track] = []
        var allPlaylists: [Playlist] = []
        
        for file in files {
            if file.pathExtension == "m3u" {
                let newPlaylist = parseM3UFile(file: file)!
                allPlaylists.append(newPlaylist)
            } else {
                let newFile = await parseMP3File(file: file)
                allSongs.append(newFile)
            }
        }
        return (allSongs, allPlaylists)
    }
    
    private func parseMP3File(file: URL) async -> Track {
        var song: Track = Track(url: file)
        let asset = AVURLAsset(url: file)
        
        do {
            let metadata = try await asset.load(.commonMetadata)
            
            if let title = try await AVMetadataItem.metadataItems(
                from: metadata,
                withKey: AVMetadataKey.commonKeyTitle,
                keySpace: .common
            ).first?.load(.stringValue),
               !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                song.title = title
            }
            
            if let artist = try await AVMetadataItem.metadataItems(
                from: metadata,
                withKey: AVMetadataKey.commonKeyArtist,
                keySpace: .common
            ).first?.load(.stringValue),
               !artist.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                song.artist = artist
            }
        } catch {
            print("Metadata load failed for \(file): \(error.localizedDescription)")
        }
        
        return song
    }
    
    /**
     This function does not really need any file validation or resolving paths because files provided here
     are generated from another system. If there is an error, it's the parent system that needs fixing.
     */
    private func parseM3UFile(file: URL) -> Playlist? {
        do {
            let content = try String(contentsOf: file, encoding: .utf8)
            let lines = content.components(separatedBy: .newlines)

            guard lines.first == "#EXTM3U" else {
                print("No EXTM3U tag in \(file.lastPathComponent), skipping...")
                return nil
            }

            var playlistName = file.deletingPathExtension().lastPathComponent
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

                trackFileNames.append(decodedPath)
            }
            return Playlist(
                id: file.path,
                name: playlistName,
                sourceURL: file,
                trackFileNames: trackFileNames
            )
        } catch {
            print("Error reading M3U file: \(error)")
            return nil
        }
    }
}
