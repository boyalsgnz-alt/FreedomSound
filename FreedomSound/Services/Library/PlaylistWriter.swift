//
//  PlaylistWriter.swift
//  FreedomSound
//
//  Created by Gaëtan Boyals on 03/09/2026.
//

import Foundation

enum PlaylistWriterError: LocalizedError {
    case emptyName
    case missingSourceFile
    case fileWriteFailed(Error)
    case fileDeleteFailed(Error)

    var errorDescription: String? {
        switch self {
        case .emptyName:
            return "Playlist name cannot be empty."
        case .missingSourceFile:
            return "This playlist has no file to write to."
        case .fileWriteFailed(let error):
            return "Could not write playlist file: \(error.localizedDescription)"
        case .fileDeleteFailed(let error):
            return "Could not delete playlist file: \(error.localizedDescription)"
        }
    }
}

/**
 Writes/updates the .m3u files backing local playlists, in the same folder the library is scanned
 from. Must be called with an already folder-access-scoped URL, e.g. from inside
 `FolderManager.withAccessToFolder`.
 */
enum PlaylistWriter {

    static func appendTrack(_ track: Track, to playlist: Playlist, in folderURL: URL) throws -> Playlist {
        guard !playlist.trackFileNames.contains(track.fileName) else {
            return playlist
        }
        guard let sourceURL = playlist.sourceURL else {
            throw PlaylistWriterError.missingSourceFile
        }

        var content = (try? String(contentsOf: sourceURL, encoding: .utf8))
            ?? "#EXTM3U\n#PLAYLIST:\(playlist.name)\n"
        if !content.hasSuffix("\n") {
            content += "\n"
        }
        content += track.fileName + "\n"

        do {
            try content.write(to: sourceURL, atomically: true, encoding: .utf8)
        } catch {
            throw PlaylistWriterError.fileWriteFailed(error)
        }

        return Playlist(
            id: playlist.id,
            name: playlist.name,
            sourceURL: sourceURL,
            trackFileNames: playlist.trackFileNames + [track.fileName]
        )
    }

    static func createPlaylist(named rawName: String, with track: Track, in folderURL: URL) throws -> Playlist {
        try createPlaylist(named: rawName, with: [track], in: folderURL)
    }

    static func createPlaylist(named rawName: String, with tracks: [Track], in folderURL: URL) throws -> Playlist {
        let trimmedName = rawName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else {
            throw PlaylistWriterError.emptyName
        }

        let fileURL = uniqueFileURL(forBaseName: trimmedName, in: folderURL)
        let playlistName = fileURL.deletingPathExtension().lastPathComponent
        let fileNames = tracks.map { $0.fileName }
        let content = "#EXTM3U\n#PLAYLIST:\(playlistName)\n" + fileNames.map { $0 + "\n" }.joined()

        do {
            try content.write(to: fileURL, atomically: true, encoding: .utf8)
        } catch {
            throw PlaylistWriterError.fileWriteFailed(error)
        }

        return Playlist(
            id: fileURL.path,
            name: playlistName,
            sourceURL: fileURL,
            trackFileNames: fileNames
        )
    }

    static func deletePlaylist(_ playlist: Playlist, in folderURL: URL) throws {
        guard let sourceURL = playlist.sourceURL else {
            throw PlaylistWriterError.missingSourceFile
        }
        do {
            try FileManager.default.removeItem(at: sourceURL)
        } catch {
            throw PlaylistWriterError.fileDeleteFailed(error)
        }
    }

    private static func uniqueFileURL(forBaseName baseName: String, in folderURL: URL) -> URL {
        let sanitized = sanitize(baseName)
        var candidate = folderURL.appendingPathComponent(sanitized).appendingPathExtension("m3u")
        var suffix = 2
        while FileManager.default.fileExists(atPath: candidate.path) {
            candidate = folderURL.appendingPathComponent("\(sanitized) (\(suffix))").appendingPathExtension("m3u")
            suffix += 1
        }
        return candidate
    }

    private static func sanitize(_ name: String) -> String {
        let invalidCharacters = CharacterSet(charactersIn: "/\\:?%*|\"<>")
        return name.components(separatedBy: invalidCharacters).joined(separator: "-")
    }
}
