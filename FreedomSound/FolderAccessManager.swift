import Foundation
import UniformTypeIdentifiers

@MainActor
final class FolderAccessManager: ObservableObject {
    @Published var selectedFolderURL: URL?
    @Published var musicFiles: [MusicFile] = []
    @Published var statusMessage: String = "No folder selected"

    private let bookmarkKey = "SelectedMusicFolderBookmark"

    init() {
        restoreFolderFromBookmark()
    }

    // MARK: - Public API

    func savePickedFolder(_ folderURL: URL) {
        do {
            let bookmarkData = try folderURL.bookmarkData()
            UserDefaults.standard.set(bookmarkData, forKey: bookmarkKey)

            selectedFolderURL = folderURL
            statusMessage = "Folder saved: \(folderURL.lastPathComponent)"
        } catch {
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
                bookmarkDataIsStale: &isStale
            )

            if isStale {
                let newBookmark = try url.bookmarkData()
                UserDefaults.standard.set(newBookmark, forKey: bookmarkKey)
            }

            selectedFolderURL = url
            statusMessage = "Using saved folder: \(url.lastPathComponent)"
        } catch {
            selectedFolderURL = nil
            statusMessage = "Saved folder is no longer available. Please pick it again."
        }
    }

    func clearSavedFolder() {
        UserDefaults.standard.removeObject(forKey: bookmarkKey)
        selectedFolderURL = nil
        musicFiles = []
        statusMessage = "Saved folder cleared"
    }

    func scanFolder() {
        guard let folderURL = selectedFolderURL else {
            statusMessage = "No folder selected"
            musicFiles = []
            return
        }

        let didAccess = folderURL.startAccessingSecurityScopedResource()
        defer {
            if didAccess {
                folderURL.stopAccessingSecurityScopedResource()
            }
        }

        do {
            let found = try recursiveAudioFiles(in: folderURL)
                .map { MusicFile(url: $0) }
                .sorted { $0.fileName.localizedCaseInsensitiveCompare($1.fileName) == .orderedAscending }

            musicFiles = found
            statusMessage = "Found \(found.count) audio file(s)"
        } catch {
            musicFiles = []
            statusMessage = "Scan failed: \(error.localizedDescription)"
        }
    }

    // MARK: - Recursive scan

    private func recursiveAudioFiles(in folderURL: URL) throws -> [URL] {
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
            return []
        }

        var results: [URL] = []

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
                } else {
                    // Fallback for providers that don't give a content type
                    let ext = fileURL.pathExtension.lowercased()
                    if Self.supportedAudioExtensions.contains(ext) {
                        results.append(fileURL)
                    }
                }
            } catch {
                // Skip unreadable items and continue scanning
                continue
            }
        }

        return results
    }

    private static let supportedAudioExtensions: Set<String> = [
        "mp3", "m4a", "aac", "flac", "wav", "aif", "aiff", "caf", "alac", "ogg"
    ]
}