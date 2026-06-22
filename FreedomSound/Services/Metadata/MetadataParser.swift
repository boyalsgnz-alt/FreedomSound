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
        let mp3Files = files.filter { $0.pathExtension == "mp3"}
        let m3uFiles = files.filter { $0.pathExtension == "m3u" }
        
        let allPlaylists: [Playlist] = m3uFiles.compactMap { parseM3UFile(file: $0) }
        
        let allSongs = await parseMP3FilesConcurrently(files: mp3Files)
        
        return (allSongs, allPlaylists)
    }
    
    private func parseMP3FilesConcurrently(files: [URL], batchSize: Int = 50) async -> [Track] {
        var allTracks: [Track] = []
        
        let batches = stride(from: 0, to: files.count, by: batchSize).map {
            Array(files[$0..<min($0 + batchSize, files.count)])
        }
        
        for batch in batches {
            await withTaskGroup(of: Track.self) { group in
                for file in batch {
                    group.addTask {
                        await self.parseMP3File(file: file)
                    }
                }
                for await track in group {
                    allTracks.append(track)
                }
            }
        }
        return allTracks
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
